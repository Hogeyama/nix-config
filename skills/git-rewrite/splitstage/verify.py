"""多層の完全性チェックと commit / abort。

層構造 (spec / ブリーフ §2):
- ID 会計 (分配型のみ): applied ∪ remaining == universe、重複なし
- betweenness (分配型のみ、fabricated ファイルは自動スキップ):
  staged / remaining の全変更行が universe に整列すること
- 最終 tree 一致 (全類型、スキップ不可): 残り変更ゼロになった時点で
  HEAD の tree == snapshot の tree
"""

from splitstage import SplitstageError
from splitstage.diffparse import run_git
from splitstage.state import worktree_tree


class VerifyError(SplitstageError):
    pass


def _head_tree(repo):
    return run_git(repo, "rev-parse", "HEAD^{tree}").strip()


def verify(session, betweenness=True):
    repo = session.repo
    fabricated = set(session.data["fabricated_files"])
    applied = session.applied_align()
    remaining = session.remaining_align(exclude_ids=applied.matched_ids)
    committed_ids = {i for c in session.data["committed"] for i in c["ids"]}
    staged = applied.matched_ids - committed_ids
    problems = []

    # --- betweenness (fabricated ファイルは対象外)
    skipped = sorted(fabricated)
    if betweenness:
        for path, lines in applied.unaligned.items():
            if path not in fabricated:
                problems.append({
                    "check": "betweenness", "file": path,
                    "detail": [f"{t}{x}" for t, x in lines[:5]],
                    "msg": "staged content does not align to the original diff"})
    # worktree 側の unaligned は「worktree が外部変更された」ことを意味する
    for path, lines in remaining.unaligned.items():
        if path not in fabricated:
            problems.append({
                "check": "worktree", "file": path,
                "detail": [f"{t}{x}" for t, x in lines[:5]],
                "msg": "worktree content does not align to the original diff "
                       "(was the worktree modified during the session?)"})

    # --- ID 会計 (fabricated ファイルの ID は対象外)
    fab_ids = {op["id"] for p in fabricated
               for op in session.universe["files"].get(p, {"ops": []})["ops"]
               if op["t"] != "keep"}
    accountable = session.all_ids() - fab_ids
    covered = (applied.matched_ids | remaining.matched_ids) - fab_ids
    missing = accountable - covered
    # 抑制条件は fabricated 以外の unaligned に限る。fabricated ファイルは
    # 常に unaligned なので、旧条件では `set` を1回使った時点で
    # 以後の ID 消失がすべて沈黙してしまう (レビュー指摘)
    nonfab_unaligned = ({p for p in applied.unaligned if p not in fabricated}
                        | {p for p in remaining.unaligned if p not in fabricated})
    if missing and not nonfab_unaligned:
        problems.append({"check": "id-accounting",
                         "msg": f"ids lost (neither staged nor remaining): "
                                f"{sorted(missing)[:10]}"})

    # --- 完了判定と最終 tree 一致
    complete = False
    if not remaining.matched_ids and not remaining.unaligned and not staged:
        head_tree = _head_tree(repo)
        if head_tree == session.data["snapshot_tree"]:
            complete = True
        else:
            problems.append({
                "check": "final-tree",
                "msg": f"all changes consumed but HEAD tree {head_tree[:12]} != "
                       f"snapshot tree {session.data['snapshot_tree'][:12]} "
                       "(some changes were lost or altered)"})

    return {
        "problems": problems,
        "clean": not problems,
        "complete": complete,
        "staged_count": len(staged),
        "remaining_count": len(remaining.matched_ids),
        "committed_count": len(committed_ids),
        "betweenness_skipped_files": skipped,
    }


def do_commit(session, message):
    repo = session.repo
    if not run_git(repo, "diff", "--cached", "--name-only").strip():
        raise VerifyError("nothing staged; stage changes before commit")
    report = verify(session, betweenness=True)
    hard = [p for p in report["problems"]
            if p["check"] in ("betweenness", "worktree")]
    if hard:
        raise VerifyError(
            "commit refused; integrity check failed "
            "(betweenness: use `set` to declare fabricated "
            f"intermediates / worktree: restore external edits): {hard}")

    applied_before = session.applied_align().matched_ids
    committed_before = {i for c in session.data["committed"] for i in c["ids"]}
    staged_ids = sorted(applied_before - committed_before)

    run_git(repo, "commit", "-q", "--no-verify", "-m", message)
    oid = run_git(repo, "rev-parse", "HEAD").strip()
    session.data["committed"].append(
        {"oid": oid, "msg": message, "ids": staged_ids})
    session.save()

    post = verify(session, betweenness=True)
    if post["complete"]:
        # complete 到達をセッションのライフサイクル終端として明示する。以後
        # 外部で git 操作 (rebase --continue 等) をしてから status/verify を
        # 呼んでも、その操作に紛らわされない安定した要約を返せるようにする。
        session.data["completed"] = True
        session.save()
    result = {
        "commit": oid,
        "msg": message,
        "n_ids": len(staged_ids),
        "remaining_count": post["remaining_count"],
        "complete": post["complete"],
        "betweenness_skipped_files": post["betweenness_skipped_files"],
    }
    if post["remaining_count"] == 0 and not post["complete"]:
        result["warning"] = ("no changes remain but final tree does not match "
                             "snapshot; some changes were lost. "
                             f"problems: {post['problems']}")
    return result


def do_abort(session):
    """スナップショット時点へ全復元する。

    HEAD を orig_head に戻し、worktree をスナップショットの内容にし、
    index を HEAD (+ 元の intent-to-add) に戻す。セッションは終了する。
    セッション外で作られた「スナップショットにも HEAD にも無いファイル」
    は消さない (関知しない)。
    """
    repo = session.repo
    orig_head = session.data["orig_head"]
    snapshot_tree = session.data["snapshot_tree"]

    run_git(repo, "reset", "-q", "--hard", orig_head)
    # HEAD に有りスナップショットに無いファイルは reset --hard で復活して
    # しまうので、明示的に消す
    status = run_git(repo, "diff-tree", "-r", "--name-status",
                     orig_head, snapshot_tree)
    deleted = [l.split("\t", 1)[1] for l in status.splitlines()
               if l.startswith("D")]
    # worktree をスナップショット内容に
    run_git(repo, "read-tree", snapshot_tree)
    run_git(repo, "checkout-index", "-a", "-f")
    for path in deleted:
        (session.repo / path).unlink(missing_ok=True)
        run_git(repo, "update-index", "--force-remove", "--", path)
    # index を HEAD に戻す。untracked の intent-to-add は復元しない
    # (snapshot 前の素の状態に合わせる。再 snapshot 時に付け直される)
    run_git(repo, "read-tree", orig_head)
    session.clear()
    restored_tree = worktree_tree(
        repo, tracked_only=session.data.get("tracked_only", False))
    return {
        "restored": True,
        "head": orig_head,
        "worktree_matches_snapshot": restored_tree == snapshot_tree,
    }
