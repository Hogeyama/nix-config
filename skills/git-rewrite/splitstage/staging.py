"""stage (`add`) の 2 経路と `set` (旧 stage-content)。

- hunk ID (案A): 現在の diff から patch を再構成して git apply --cached --recount
- 行 ID (案B): 選択から中間ファイル内容を構成して blob を直接 index へ
- `set`: 内容そのものを受け取って blob を index へ (でっち上げ型対応)

どの経路も適用後に「staged == 適用前 staged ∪ 選択」を universe 整列で
検証し、崩れていたら index を巻き戻してエラーにする。patch 適用の成功と
内容の正しさは別物 (ブリーフ §2 の行順崩れ) なので、この事後検証が本体。
"""

import shutil
import subprocess
from pathlib import Path

from splitstage import SplitstageError
from splitstage.diffparse import GitError, group_hunks, run_git
from splitstage.state import StateError, _git_dir


class StageError(SplitstageError):
    pass


# ------------------------------------------------------------------ helpers

def _index_path(repo):
    return _git_dir(repo) / "index"


def _backup_index(session):
    src = _index_path(session.repo)
    dst = session.dir / "index.bak"
    shutil.copy2(src, dst)
    return dst


def _restore_index(session):
    src = session.dir / "index.bak"
    shutil.copy2(src, _index_path(session.repo))


def _id_map(universe):
    """id -> (path, op) の索引。"""
    out = {}
    for path, f in universe["files"].items():
        for op in f["ops"]:
            if op["t"] != "keep":
                out[op["id"]] = (path, op)
    return out


def _post_stage_check(session, expected_applied):
    applied = session.applied_align()
    # fabricated ファイル (`set` ででっち上げ内容を宣言済み) は verify() と
    # 同様に unaligned チェックの対象外にする。旧実装はここだけ無条件で
    # エラーにしており、`set` で1ファイルを fabricated 化した後は無関係な
    # 他ファイルへの add がすべて拒否されるバグがあった (レビュー指摘)。
    fabricated = set(session.data["fabricated_files"])
    nonfab_unaligned = {p: v for p, v in applied.unaligned.items()
                        if p not in fabricated}
    if nonfab_unaligned:
        raise StageError(
            f"staged content does not align to universe: {nonfab_unaligned}")
    if applied.matched_ids != expected_applied:
        missing = sorted(expected_applied - applied.matched_ids)
        extra = sorted(applied.matched_ids - expected_applied)
        raise StageError(
            f"staged set mismatch after apply: missing={missing} extra={extra}")


def _stage_summary(session):
    applied = session.applied_align()
    committed = {i for c in session.data["committed"] for i in c["ids"]}
    return {
        "staged_ids": sorted(applied.matched_ids - committed),
        "n_staged": len(applied.matched_ids - committed),
    }


# ------------------------------------------------------------------ 経路1: hunk

def _expand_ids(session, ids):
    """位置引数/except に来た id 列を line ID へ展開する。

    hunk ID (h:) はその hunk の line_ids に展開。line ID (l:) はそのまま。
    未知 ID はそのまま返し、後段の line 経路 (_stage_lines) にエラーを委ねる。
    """
    kinds = {i.split(":", 1)[0] for i in ids}
    if not kinds <= {"h", "l"}:
        raise StageError(f"unknown id prefix in {sorted(ids)}")
    line_ids = {i for i in ids if i.startswith("l:")}
    hunk_ids = {i for i in ids if i.startswith("h:")}
    if hunk_ids:
        context = session.data["context"]
        applied_before = session.applied_align().matched_ids
        hunks, _ = group_hunks(session.universe, session.repo,
                               context=context, staged_ids=applied_before)
        by_id = {h["id"]: h for h in hunks}
        unknown = sorted(hunk_ids - set(by_id))
        if unknown:
            raise StageError(f"unknown hunk ids {unknown}")
        for hid in hunk_ids:
            line_ids.update(by_id[hid]["line_ids"])
    return line_ids


def resolve_selection(session, positional, files, remaining, except_ids,
                      except_files):
    """セレクタから stage 対象の line ID 集合を組み立てる。

    包含 (positional / files / remaining) の和集合から除外 (except_ids /
    except_files) を引く。包含セレクタが1つも指定されず除外だけ指定された
    場合はベースを remaining とする (「包含が解決後に空か」ではなく「包含
    セレクタが渡されたか」で判定する。--file 指定先が既に全 stage 済みで
    解決結果が空集合になっただけの場合に無関係な remaining 全体へフォール
    バックしてしまう footgun を避けるため)。--file / --remaining / 暗黙
    ベースは remaining のみを集めるが、位置引数で明示された ID はそのまま
    通す (既 stage の ID が混ざれば後段の _stage_lines が already-staged
    エラーを出す)。結果は universe 出現順で返す。
    """
    idmap = _id_map(session.universe)                 # id -> (path, op)
    id2f = {i: pf[0] for i, pf in idmap.items()}
    applied_before = session.applied_align().matched_ids
    remaining_ids = set(idmap) - applied_before

    for path in list(files) + list(except_files):
        if path not in session.universe["files"]:
            raise StageError(f"unknown file: {path}")

    include = set(_expand_ids(session, positional))   # 明示指定はそのまま通す
    for path in files:
        include |= {i for i in remaining_ids if id2f[i] == path}
    if remaining:
        include |= remaining_ids
    has_inclusion = bool(positional or files or remaining)
    if not has_inclusion and (except_ids or except_files):
        include = set(remaining_ids)          # 除外のみ指定 → 暗黙 remaining ベース

    exclude = set(_expand_ids(session, except_ids))
    unknown_ex = sorted(i for i in exclude if i not in idmap)
    if unknown_ex:
        raise StageError(f"unknown ids in --except: {unknown_ex}")
    for path in except_files:
        exclude |= {i for i in idmap if id2f[i] == path}

    selected = include - exclude
    if not selected:
        raise StageError("selection resolved to empty set")
    unknown = sorted(i for i in selected if i not in idmap)
    if unknown:
        raise StageError(f"unknown line ids: {unknown}")
    # universe 出現順 (安定) で返す
    order = {op["id"]: n for n, op in enumerate(
        op for f in session.universe["files"].values() for op in f["ops"]
        if op["t"] != "keep")}
    return sorted(selected, key=lambda i: order[i])


def stage_ids(session, ids):
    kinds = {i.split(":", 1)[0] for i in ids}
    if not kinds <= {"h", "l"}:
        raise StageError(f"unknown id prefix in {sorted(ids)}")
    if kinds == {"h", "l"}:
        raise StageError("cannot mix hunk ids and line ids in one stage call")
    if len(set(ids)) != len(ids):
        raise StageError("duplicate ids in one stage call")
    if kinds == {"h"}:
        return _stage_hunks(session, ids)
    return _stage_lines(session, ids)


def _stage_hunks(session, hunk_ids):
    context = session.data["context"]
    applied_before = session.applied_align().matched_ids
    hunks, rem = group_hunks(session.universe, session.repo,
                             context=context, staged_ids=applied_before)
    by_id = {h["id"]: h for h in hunks}
    unknown = [i for i in hunk_ids if i not in by_id]
    if unknown:
        raise StageError(
            f"unknown hunk ids {unknown}; current hunks: {sorted(by_id)} "
            f"(context=-U{context}; hunk ids change when context changes)")
    selected = [by_id[i] for i in hunk_ids]
    selected_lines = {lid for h in selected for lid in h["line_ids"]}

    # patch を file 単位に組み立てる (同一 file の hunk は 1 セクションにまとめ、
    # 元 diff の出現順を保つ)
    per_file = {}
    for h in hunks:                       # 元の順序で走査
        if h["id"] in set(hunk_ids):
            per_file.setdefault(h["file"], []).append(h)
    sections = []
    for path, hs in per_file.items():
        header = hs[0]["patch"].split("@@", 1)[0]
        body = "".join(p["patch"][len(header):] for p in hs)
        sections.append(header + body)
    patch = "".join(sections)

    args = ["apply", "--cached", "--recount"]
    if context == 0:
        args.append("--unidiff-zero")
    _backup_index(session)
    try:
        run_git(session.repo, *args, input_=patch)
        _post_stage_check(session, applied_before | selected_lines)
    except (GitError, StageError):
        _restore_index(session)
        raise
    return {"staged_now": sorted(selected_lines), **_stage_summary(session)}


# ------------------------------------------------------------------ 経路2: 行

def _construct_content(ufile, target_applied):
    """ops を歩いて「target_applied を適用した中間ファイル内容」を作る。"""
    out = []
    for op in ufile["ops"]:
        if op["t"] == "keep":
            out.append(op["text"])
        elif op["t"] == "del":
            if op["id"] not in target_applied:
                out.append(op["text"])
        else:  # add
            if op["id"] in target_applied:
                out.append(op["text"])
    return "".join(x + "\n" for x in out)


def _write_index_content(repo, path, content, mode="100644"):
    if content is None:
        run_git(repo, "update-index", "--force-remove", "--", path)
        return
    oid = run_git(repo, "hash-object", "-w", "--stdin", input_=content).strip()
    run_git(repo, "update-index", "--add",
            "--cacheinfo", f"{mode},{oid},{path}")


def _stage_lines(session, line_ids):
    idmap = _id_map(session.universe)
    unknown = [i for i in line_ids if i not in idmap]
    if unknown:
        raise StageError(f"unknown line ids: {unknown}")
    applied_before = session.applied_align().matched_ids
    already = [i for i in line_ids if i in applied_before]
    if already:
        raise StageError(f"already staged/committed: {already}")
    fabricated = set(session.data["fabricated_files"])
    target_files = {idmap[i][0] for i in line_ids}
    bad = sorted(target_files & fabricated)
    if bad:
        raise StageError(
            f"files {bad} were staged via `set` and no longer align; "
            "line-id staging is unavailable for them")

    _backup_index(session)
    try:
        for path in sorted(target_files):
            ufile = session.universe["files"][path]
            target_applied = ({i for i in applied_before if idmap[i][0] == path}
                              | {i for i in line_ids if idmap[i][0] == path})
            all_file_ids = {op["id"] for op in ufile["ops"] if op["t"] != "keep"}
            if ufile["kind"] == "deleted" and target_applied == all_file_ids:
                content = None      # 削除が完全に適用された → index から除去
            else:
                content = _construct_content(ufile, target_applied)
            _write_index_content(session.repo, path, content, ufile["mode"])
        _post_stage_check(session, applied_before | set(line_ids))
    except (GitError, StageError):
        _restore_index(session)
        raise
    return {"staged_now": sorted(line_ids), **_stage_summary(session)}


# ------------------------------------------------------------------ 経路3: content

def stage_content(session, path, content):
    """内容そのものを staged 状態にする。universe に整列しない内容も許すが、
    その場合そのファイルは fabricated として記録され、以後 ID 会計と
    betweenness の対象外になる (最終 tree 一致だけが網)。"""
    ufile = session.universe["files"].get(path)
    mode = ufile["mode"] if ufile else "100644"
    if content is None and ufile and ufile["kind"] == "added":
        # 新規ファイルの index エントリ (intent-to-add) を消すと、その変更が
        # staged からも remaining からも見えなくなり ID が消失する
        raise StageError(
            f"{path} is a new file; it is already unstaged by default. "
            "to exclude it from this commit, simply do not stage it")
    _backup_index(session)
    _write_index_content(session.repo, path, content, mode)
    applied = session.applied_align()
    # fabricated 認定はこの呼び出しの対象 path に限る。他ファイルの
    # unaligned は別経路の破損なので免除せず、verify / commit に検出させる
    is_fabricated = path in applied.unaligned
    if is_fabricated and path not in session.data["fabricated_files"]:
        session.data["fabricated_files"].append(path)
        session.save()
    other_unaligned = sorted(set(applied.unaligned) - {path}
                             - set(session.data["fabricated_files"]))
    result = {
        "file": path,
        "deleted": content is None,
        "fabricated_files": session.data["fabricated_files"],
        "note": ("content does not align to the original diff; "
                 "betweenness check will be skipped for this file"
                 if is_fabricated else "content aligns to the original diff"),
    }
    if other_unaligned:
        result["warning"] = (f"unrelated staged files do not align: "
                             f"{other_unaligned}; commit will be refused "
                             "until they are fixed")
    return result
