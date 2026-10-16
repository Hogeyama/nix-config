"""セッション状態。すべて対象 repo の .git/split/ 配下に置く。"""

import json
import subprocess
from pathlib import Path

from splitstage import SplitstageError
from splitstage.diffparse import (GitError, align, build_universe, parse_diff,
                                  run_git, universe_ids)

# 状態ディレクトリ名 (.git/<STATE_DIR_NAME>/)。CLI (__main__.py) の oplog パスも
# ここに揃える。
STATE_DIR_NAME = "split"


class StateError(SplitstageError):
    pass


def _git_dir(repo):
    out = run_git(repo, "rev-parse", "--git-dir").strip()
    p = Path(out)
    return p if p.is_absolute() else Path(repo) / p


class Session:
    def __init__(self, repo, data, universe):
        self.repo = Path(repo)
        self.data = data          # session.json の中身
        self.universe = universe

    # ---------------------------------------------------------- lifecycle

    @classmethod
    def start(cls, repo, tracked_only=False):
        """start: セッションを開始する。

        tracked_only=True の場合、untracked ファイルへの `git add -N` を
        行わず、分割対象を tracked ファイルの変更だけに限定する
        (rebase -i の edit 停止中など、worktree に無関係な untracked
        ファイルが転がっているケース向け)。
        """
        repo = Path(repo)
        d = _git_dir(repo) / STATE_DIR_NAME
        session_file = d / "session.json"
        if session_file.exists():
            try:
                existing = json.loads(session_file.read_text())
            except (json.JSONDecodeError, OSError):
                existing = {}
            if existing.get("completed"):
                # 完了済みセッションはライフサイクル終端に達している。次の
                # セッションの開始を妨げないよう自動で片付ける (oplog は残す)。
                session_file.unlink(missing_ok=True)
                (d / "universe.json").unlink(missing_ok=True)
            else:
                raise StateError("session already exists (use abort to reset)")
        # index が HEAD と一致していること (これから stage 操作で index を使うため)
        if run_git(repo, "diff", "--cached", "--name-only").strip():
            raise StateError("index is not clean; commit or reset staged changes first")
        # start が途中で失敗したときに取り消せるよう、この呼び出しで登録した
        # intent-to-add パスを控える。残したままだと、原因 (対象外のファイル
        # など) を worktree から取り除いても index 側に登録が残り続け、start が
        # 同じ理由で拒否され続けて抜け出せなくなる。
        ita_added = []
        try:
            if not tracked_only:
                # untracked を intent-to-add で diff に含める
                untracked = run_git(repo, "ls-files", "--others",
                                    "--exclude-standard").splitlines()
                for path in untracked:
                    run_git(repo, "add", "-N", "--", path)
                    ita_added.append(path)
            universe = build_universe(repo)
            snapshot_tree = worktree_tree(repo, tracked_only=tracked_only)
            head = run_git(repo, "rev-parse", "HEAD").strip()
            data = {
                "orig_head": head,
                "snapshot_tree": snapshot_tree,
                "context": 3,
                "fabricated_files": [],
                "committed": [],
                "plan": None,
                "tracked_only": tracked_only,
            }
            d.mkdir(parents=True, exist_ok=True)
            (d / "universe.json").write_text(json.dumps(universe))
            session = cls(repo, data, universe)
            session.save()
        except Exception:
            for path in ita_added:
                # 元のエラーを握り潰さないよう、取り消しの失敗は無視する
                run_git(repo, "update-index", "--force-remove", "--", path,
                        check=False)
            raise
        return session

    @classmethod
    def load(cls, repo):
        d = _git_dir(repo) / STATE_DIR_NAME
        try:
            data = json.loads((d / "session.json").read_text())
            universe = json.loads((d / "universe.json").read_text())
        except FileNotFoundError:
            raise StateError("no session; run `git split start` first")
        return cls(repo, data, universe)

    def save(self):
        d = _git_dir(self.repo) / STATE_DIR_NAME
        (d / "session.json").write_text(json.dumps(self.data, ensure_ascii=False))

    def clear(self):
        d = _git_dir(self.repo) / STATE_DIR_NAME
        for name in ("session.json", "universe.json"):
            (d / name).unlink(missing_ok=True)

    @property
    def dir(self):
        return _git_dir(self.repo) / STATE_DIR_NAME

    # ---------------------------------------------------------- alignment

    def applied_align(self):
        """orig_head → index の diff を universe に整列 (= stage/commit 済み)。"""
        text = run_git(self.repo, "diff", "--no-renames", "--no-color",
                       "--cached", self.data["orig_head"])
        return align(self.universe, parse_diff(text))

    def remaining_align(self, exclude_ids=frozenset()):
        """index → worktree の diff を universe に整列 (= 未 stage)。"""
        text = run_git(self.repo, "diff", "--no-renames", "--no-color")
        return align(self.universe, parse_diff(text), exclude_ids=exclude_ids)

    def all_ids(self):
        return set(universe_ids(self.universe))


def worktree_tree(repo, tracked_only=False):
    """worktree 全体 (untracked 込み) の tree oid を一時 index で計算する。

    一時 index は空からではなく HEAD から始める。空 index への `add -A` は
    「ignore されたディレクトリ内の tracked ファイル」(親ディレクトリを
    ignore しつつ `!` で例外化した構成など) を新規ファイル扱いで取り落とし、
    snapshot が実際の worktree より小さくなる。HEAD を種にすれば tracked
    ファイルは ignore 規則に関係なく保持され、add -A は追加・変更・削除の
    差分だけを反映する。

    tracked_only=True の場合は `add -A` の代わりに `add -u` を使う。
    `add -u` は tracked ファイルの変更・削除だけを反映し、untracked
    ファイルは一切拾わない。tracked-only セッションでは untracked が
    分割対象に入らない (= universe に含まれない) ため、snapshot もそれに
    合わせて untracked を無視しないと、最終 tree 一致が untracked の分だけ
    永遠に成立しなくなる。

    ただし `git add -N <path>` (intent-to-add) 済みのファイルは「実の
    index に存在する tracked パス」でありながら `add -u` では拾われない
    (add -u は既存内容の更新のみを行い、新規登録はしないため)。
    --tracked-only で「分割に入れたい新規ファイルは事前に add -N して
    おく」という逃げ道を成立させるには、その ita パスだけ明示的に
    実内容で登録し直す必要がある (実測: 未対応だと最終 tree 一致が
    その ita ファイルの分だけ永遠に成立しない)。

    GIT_INDEX_FILE には「存在しないパス」を渡す必要がある
    (空ファイルは不正な index として git が拒否する)。
    """
    import os
    import tempfile
    with tempfile.TemporaryDirectory(prefix="splitstage-") as td:
        env = dict(os.environ, GIT_INDEX_FILE=str(Path(td) / "index"))
        subprocess.run(["git", "-C", str(repo), "read-tree", "HEAD"],
                       check=True, capture_output=True, env=env)
        add_flag = "-u" if tracked_only else "-A"
        subprocess.run(["git", "-C", str(repo), "add", add_flag],
                       check=True, capture_output=True, env=env)
        if tracked_only:
            # 実 index (env なし = 本来の index) 上の ita パスを列挙する。
            # ita は `--cached` diff からは既定で見えないため
            # --ita-visible-in-index で可視化する。
            ita = subprocess.run(
                ["git", "-C", str(repo), "diff", "--cached", "--name-only",
                 "--ita-visible-in-index"],
                check=True, capture_output=True, text=True).stdout.splitlines()
            if ita:
                subprocess.run(["git", "-C", str(repo), "add", "-A", "--", *ita],
                               check=True, capture_output=True, env=env)
        out = subprocess.run(["git", "-C", str(repo), "write-tree"],
                             check=True, capture_output=True, text=True, env=env)
        return out.stdout.strip()
