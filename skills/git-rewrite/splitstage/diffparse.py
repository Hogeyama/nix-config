"""git diff のパース、universe 構築、整列 (align)。

universe: snapshot 時の全変更を行単位に展開した不変のリスト。
以後のすべての diff はここへ「整列」して解釈し、ID はこの universe の
要素に対してのみ振る。位置ではなく内容で指すため、stage が進んで
offset がズレても ID は不変になる。
"""

import hashlib
import subprocess
from collections import defaultdict
from dataclasses import dataclass, field

from splitstage import SplitstageError


def run_git(repo, *args, check=True, input_=None):
    p = subprocess.run(["git", "-C", str(repo), *args],
                       capture_output=True, text=True, input=input_)
    if check and p.returncode != 0:
        raise GitError(f"git {' '.join(args)}: {p.stderr.strip()}")
    return p.stdout


class GitError(SplitstageError):
    pass


# ---------------------------------------------------------------- diff parse

@dataclass
class Hunk:
    header: str
    lines: list = field(default_factory=list)   # [(t, text)]  t は " " / "-" / "+"


@dataclass
class FileDiff:
    path: str
    kind: str = "modified"       # modified / added / deleted
    mode: str = "100644"
    hunks: list = field(default_factory=list)
    no_newline: bool = False     # "\ No newline at end of file" を含む


def parse_diff(text):
    """unified diff テキストを {path: FileDiff} に変換する。

    --no-renames 前提 (rename ヘッダは扱わない)。
    """
    files = {}
    cur = None
    hunk = None
    for raw in text.splitlines():
        if raw.startswith("diff --git "):
            # b/ 側のパスを取る (quote なし前提: fixture はスペースを含まない)
            b_path = raw.split(" b/", 1)[1]
            cur = FileDiff(path=b_path)
            files[b_path] = cur
            hunk = None
        elif cur is None:
            continue
        elif raw.startswith("new file mode "):
            cur.kind = "added"
            cur.mode = raw.rsplit(" ", 1)[1]
        elif raw.startswith("deleted file mode "):
            cur.kind = "deleted"
            cur.mode = raw.rsplit(" ", 1)[1]
        elif raw.startswith("old mode ") or raw.startswith("new mode "):
            cur.mode = raw.rsplit(" ", 1)[1]
        elif hunk is None and raw.startswith("index "):
            # git が old/new mode 行を出すのは「モードが変化したとき」だけで、
            # 変化していないファイルの実モードは index 行の末尾フィールド
            # (`index 83db48f..a16f0f7 100755`) にしか現れない。ここを読まないと
            # 実行可能ファイルの mode が既定値 100644 のまま universe に載り、
            # index へ blob を直接書く経路 (行 ID / `set`) が実行ビットを落とす。
            # モードが変化した diff では index 行に末尾フィールドが無いため、
            # 直前の old/new mode 行の結果を上書きしてしまうことはない。
            parts = raw.split()
            if len(parts) == 3:
                cur.mode = parts[2]
        elif raw.startswith("@@"):
            hunk = Hunk(header=raw)
            cur.hunks.append(hunk)
        elif hunk is not None:
            if raw.startswith("\\"):   # "\ No newline at end of file"
                cur.no_newline = True
                continue
            if raw[:1] in (" ", "-", "+"):
                hunk.lines.append((raw[0], raw[1:]))
            elif raw == "":
                hunk.lines.append((" ", ""))
    return files


# ---------------------------------------------------------------- universe

def _line_id(path, t, text, occ):
    h = hashlib.sha256(f"{path}\0{t}\0{text}\0{occ}".encode()).hexdigest()[:8]
    return f"l:{h}"


def _pair_block(block):
    """変更ブロック (keep を含まない連続変更) 内の del / add をペアリングし、
    「置換はその場で、挿入・削除は独立に」の順へ並べ直す。

    git diff は変更ブロックを「del 群 → add 群」で出力するが、その順の
    ops を部分適用すると、前側の変更だけ適用したときに add がブロック末尾へ
    落ちて行順が崩れる (ブリーフ §2 の行順崩れと同型)。

    ペアリングは位置ではなく内容類似度の単調マッチング (小さな DP) で決める。
    位置ベース (i 番目同士) だと、置換と挿入が混在するブロック
    (dels=[o13], adds=[o12b, o13']) で削除が無関係な挿入と対になり、
    部分適用の中間状態で挿入行が本来と違う位置に落ちる。
    """
    from difflib import SequenceMatcher
    dels = [op for op in block if op["t"] == "del"]
    adds = [op for op in block if op["t"] == "add"]
    if not dels or not adds:
        return dels + adds
    m, n = len(dels), len(adds)
    ratio = [[SequenceMatcher(None, d["text"], a["text"]).ratio()
              for a in adds] for d in dels]
    MIN = 0.5   # これ未満は置換とみなさない (独立した削除+挿入として扱う)
    # dp[i][j] = dels[:i] と adds[:j] の最良マッチスコア
    dp = [[0.0] * (n + 1) for _ in range(m + 1)]
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            best = max(dp[i - 1][j], dp[i][j - 1])
            if ratio[i - 1][j - 1] >= MIN:
                best = max(best, dp[i - 1][j - 1] + ratio[i - 1][j - 1])
            dp[i][j] = best
    # traceback で (del, add) ペアと独立要素を元の単調順に並べる
    out = []
    i, j = m, n
    while i > 0 or j > 0:
        if (i > 0 and j > 0 and ratio[i - 1][j - 1] >= MIN
                and dp[i][j] == dp[i - 1][j - 1] + ratio[i - 1][j - 1]):
            out.append(adds[j - 1])
            out.append(dels[i - 1])
            i, j = i - 1, j - 1
        elif j > 0 and dp[i][j] == dp[i][j - 1]:
            out.append(adds[j - 1])
            j -= 1
        else:
            out.append(dels[i - 1])
            i -= 1
    out.reverse()
    return out


def build_universe(repo):
    """HEAD vs worktree の全変更を ops 列に展開して ID を振る。

    呼び出し前提: untracked は `git add -N` 済み、index は HEAD と一致
    (intent-to-add エントリを除く)。
    -U999999 で diff を取ることで、変更のないファイル行も keep op として
    全て手に入る (中間内容の構成に必要)。
    """
    text = run_git(repo, "diff", "--no-renames", "--no-color", "-U999999")
    parsed = parse_diff(text)
    bad = sorted(p for p, fd in parsed.items() if fd.no_newline)
    if bad:
        # 中間内容の構成が全行に改行を付ける前提のため、末尾改行の無い
        # ファイルは patch 経路・行経路とも正しく扱えない (既知の制限)。
        # 黙って壊れるのではなく snapshot 時点で明確に拒否する
        raise GitError(
            f"files without trailing newline are not supported by this "
            f"prototype: {bad}")
    occ_counter = defaultdict(int)
    files = {}
    for path, fd in parsed.items():
        raw_ops = []
        for hunk in fd.hunks:
            for t, line_text in hunk.lines:
                if t == " ":
                    raw_ops.append({"t": "keep", "text": line_text})
                else:
                    kind = "del" if t == "-" else "add"
                    key = (path, t, line_text)
                    occ = occ_counter[key]
                    occ_counter[key] += 1
                    raw_ops.append({"t": kind, "text": line_text,
                                    "id": _line_id(path, t, line_text, occ),
                                    "occ": occ})
        # 変更ブロックごとに del/add をペアリングして並び直す
        ops = []
        block = []
        for op in raw_ops:
            if op["t"] == "keep":
                ops.extend(_pair_block(block))
                block = []
                ops.append(op)
            else:
                block.append(op)
        ops.extend(_pair_block(block))
        files[path] = {"kind": fd.kind, "mode": fd.mode, "ops": ops}
    no_ids = sorted(p for p, f in files.items()
                    if not any(op["t"] != "keep" for op in f["ops"]))
    if no_ids:
        # 変更行を1つも持たないファイル。この種の変更 (モードのみの変更、
        # バイナリファイル、空ファイルの新規作成・削除) は diff に変更行が
        # 現れないため ID を振れず、stage する手段が存在しない。放置すると
        # 分割完了時の tree 不一致という遠く離れた症状としてしか現れないので、
        # 末尾改行の無いファイルと同様、snapshot 時点で明示的に拒否する。
        raise GitError(
            f"changes with no line-level content cannot be staged by this "
            f"prototype (mode-only change, binary file, or empty file "
            f"creation/deletion): {no_ids}; commit them separately before or "
            f"after the split")
    return {"files": files}


def universe_ids(universe):
    return [op["id"] for f in universe["files"].values()
            for op in f["ops"] if op["t"] != "keep"]


# ---------------------------------------------------------------- align

@dataclass
class AlignResult:
    matched_ids: set = field(default_factory=set)
    unaligned: dict = field(default_factory=dict)   # path -> [ (t, text), ... ]

    @property
    def ok(self):
        return not self.unaligned


def align(universe, filediffs, exclude_ids=frozenset()):
    """diff の変更行を universe の未消費 op に in-order マッチさせる。

    exclude_ids: すでに別の側 (staged など) に整列済みで消費された ID。
    del と add は別々の列として順序マッチする (diff 内での del/add の
    交互配置は universe とブロック構造が違い得るが、同種内の相対順序は
    保存されるため)。
    """
    result = AlignResult()
    for path, fd in filediffs.items():
        ufile = universe["files"].get(path)
        if ufile is None:
            for hunk in fd.hunks:
                for t, text in hunk.lines:
                    if t != " ":
                        result.unaligned.setdefault(path, []).append((t, text))
            continue
        pools = {
            "-": [op for op in ufile["ops"]
                  if op["t"] == "del" and op["id"] not in exclude_ids],
            "+": [op for op in ufile["ops"]
                  if op["t"] == "add" and op["id"] not in exclude_ids],
        }
        cursors = {"-": 0, "+": 0}
        for hunk in fd.hunks:
            for t, text in hunk.lines:
                if t == " ":
                    continue
                pool = pools[t]
                i = cursors[t]
                while i < len(pool) and (pool[i]["text"] != text
                                         or pool[i]["id"] in result.matched_ids):
                    i += 1
                if i < len(pool):
                    result.matched_ids.add(pool[i]["id"])
                    cursors[t] = i + 1
                else:
                    result.unaligned.setdefault(path, []).append((t, text))
    return result


# ---------------------------------------------------------------- hunks

def group_hunks(universe, repo, context=3, staged_ids=frozenset()):
    """現在の diff (index vs worktree) を指定 context で hunk に分け、
    各 hunk を universe の行 ID 集合として返す。

    返り値: (hunk リスト, 現在の diff の AlignResult)
    hunk: {"id", "file", "line_ids", "patch"(ファイルヘッダ込み patch 断片)}
    """
    text = run_git(repo, "diff", "--no-renames", "--no-color", f"-U{context}")
    parsed = parse_diff(text)
    result = []
    overall = AlignResult()
    for path, fd in parsed.items():
        header = _file_header(text, path)
        ufile = universe["files"].get(path)
        pools = {"-": [], "+": []}
        if ufile:
            pools = {
                "-": [op for op in ufile["ops"]
                      if op["t"] == "del" and op["id"] not in staged_ids],
                "+": [op for op in ufile["ops"]
                      if op["t"] == "add" and op["id"] not in staged_ids],
            }
        cursors = {"-": 0, "+": 0}
        for hunk in fd.hunks:
            line_ids = []
            lines_view = []
            for t, line_text in hunk.lines:
                if t == " ":
                    continue
                pool = pools[t]
                i = cursors[t]
                while i < len(pool) and (pool[i]["text"] != line_text
                                         or pool[i]["id"] in overall.matched_ids):
                    i += 1
                if i < len(pool):
                    lid = pool[i]["id"]
                    overall.matched_ids.add(lid)
                    cursors[t] = i + 1
                    line_ids.append(lid)
                    lines_view.append({"id": lid, "t": t, "text": line_text})
                else:
                    overall.unaligned.setdefault(path, []).append((t, line_text))
                    lines_view.append({"id": None, "t": t, "text": line_text})
            hid = "h:" + hashlib.sha256("\0".join(line_ids).encode()).hexdigest()[:8]
            patch = header + hunk.header + "\n" + "\n".join(
                t + text for t, text in hunk.lines) + "\n"
            result.append({"id": hid, "file": path, "line_ids": line_ids,
                           "lines": lines_view, "patch": patch})
    return result, overall


def _file_header(diff_text, path):
    """diff テキストから該当ファイルのヘッダ部分 (diff --git 〜 +++ 行) を抜き出す。"""
    lines = diff_text.splitlines()
    out = []
    in_file = False
    for raw in lines:
        if raw.startswith("diff --git "):
            in_file = raw.endswith(" b/" + path)
            if in_file:
                out = [raw]
            continue
        if in_file:
            if raw.startswith("@@"):
                break
            out.append(raw)
    return "\n".join(out) + "\n"
