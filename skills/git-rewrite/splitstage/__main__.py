"""git split CLI (python パッケージ名は splitstage)。

すべてのサブコマンドは JSON 1 オブジェクトを stdout に出し、
成功なら exit 0、失敗なら exit 1 で {"ok": false, "error": ...} を返す。
すべての呼び出しは .git/split/oplog.jsonl に記録される。
"""

import argparse
import json
import sys
from pathlib import Path

from splitstage import SplitstageError, oplog
from splitstage.diffparse import GitError, group_hunks
from splitstage.state import STATE_DIR_NAME, Session, StateError


class CommandError(SplitstageError):
    pass


COMPLETED_ERROR = "session completed; run `git split start` for a new session"


def _reject_if_completed(session):
    """complete 到達後のセッションで変更系コマンドが呼ばれたら拒否する。"""
    if session.data.get("completed"):
        raise CommandError(COMPLETED_ERROR)


def _completed_status_summary(session):
    """complete 到達後の status: alignment 計算を行わず安定した要約だけ返す。

    以後 (external な git 操作の後などに) 呼ばれても、その操作に紛らわされ
    ない値を返す。
    """
    committed = session.data["committed"]
    committed_ids = sorted({i for c in committed for i in c["ids"]})
    return {
        "completed": True,
        "complete": True,
        "committed": [{"oid": c["oid"], "msg": c["msg"], "n_ids": len(c["ids"])}
                      for c in committed],
        "committed_ids": committed_ids,
        "staged_ids": [],
        "remaining_ids": [],
        "files": {},
        "fabricated_files": session.data["fabricated_files"],
        "plan_cursor": None,
    }


def _completed_verify_summary(session):
    """complete 到達後の verify: alignment 計算を行わず安定した要約だけ返す。"""
    committed_ids = {i for c in session.data["committed"] for i in c["ids"]}
    return {
        "completed": True,
        "problems": [],
        "clean": True,
        "complete": True,
        "staged_count": 0,
        "remaining_count": 0,
        "committed_count": len(committed_ids),
        "betweenness_skipped_files": session.data["fabricated_files"],
    }


def _id_to_file(universe):
    """line ID -> path の索引。"""
    return {op["id"]: path
            for path, f in universe["files"].items()
            for op in f["ops"] if op["t"] != "keep"}


def _files_view(session, staged_ids, remaining_ids, unaligned):
    """per-file ビュー: staged/remaining の line ID と unaligned をファイル別にまとめる。

    unaligned: {path: [(t, text), ...]}。universe に無い path (fabricated 等) も
    バケットを作る。
    """
    id2f = _id_to_file(session.universe)
    files = {}

    def bucket(path):
        if path not in files:
            kind = session.universe["files"].get(path, {}).get("kind", "unknown")
            files[path] = {"kind": kind, "staged_ids": [],
                           "remaining_ids": [], "unaligned": []}
        return files[path]

    for i in sorted(staged_ids):
        bucket(id2f[i])["staged_ids"].append(i)
    for i in sorted(remaining_ids):
        bucket(id2f[i])["remaining_ids"].append(i)
    for path, lines in unaligned.items():
        bucket(path)["unaligned"] = [[t, x] for t, x in lines]
    return files


# ------------------------------------------------------------------ commands

def cmd_start(args):
    session = Session.start(args.repo, tracked_only=args.tracked_only)
    note = ("files matched by .gitignore are not tracked by this tool; "
            "use git add -f before start if they must be committed")
    if args.tracked_only:
        note += ("; --tracked-only: untracked files are not part of this "
                 "session and were left untouched")
    return {
        "orig_head": session.data["orig_head"],
        "snapshot_tree": session.data["snapshot_tree"],
        "total_change_ids": len(session.all_ids()),
        "files": {p: {"kind": f["kind"],
                      "changes": sum(1 for op in f["ops"] if op["t"] != "keep")}
                  for p, f in session.universe["files"].items()},
        "note": note,
    }


def cmd_show(args):
    session = Session.load(args.repo)
    if args.context is not None:
        session.data["context"] = args.context
        session.save()
    context = session.data["context"]
    applied = session.applied_align()
    committed_ids = {i for c in session.data["committed"] for i in c["ids"]}
    staged = applied.matched_ids - committed_ids
    hunks, remaining = group_hunks(session.universe, session.repo,
                                   context=context,
                                   staged_ids=applied.matched_ids)
    out_hunks = []
    for h in hunks:
        item = {"id": h["id"], "file": h["file"], "n_lines": len(h["line_ids"])}
        if args.lines:
            item["lines"] = h["lines"]
        else:
            item["patch"] = h["patch"]
        out_hunks.append(item)
    if args.file:
        wanted = set(args.file)
        unknown = sorted(wanted - set(session.universe["files"]))
        if unknown:
            raise CommandError(f"unknown file: {unknown[0]}")
        id2f = _id_to_file(session.universe)
        staged = {i for i in staged if id2f[i] in wanted}
        remaining.matched_ids = {i for i in remaining.matched_ids
                                 if id2f[i] in wanted}
        remaining.unaligned = {p: v for p, v in remaining.unaligned.items()
                               if p in wanted}
        out_hunks = [h for h in out_hunks if h["file"] in wanted]
        committed_ids = {i for i in committed_ids if id2f[i] in wanted}
    fabricated = set(session.data["fabricated_files"])
    if args.file:
        fabricated &= set(args.file)
    unaligned = {p: remaining.unaligned.get(p, [])
                 for p in set(remaining.unaligned) | fabricated}
    return {
        "context": context,
        "staged_ids": sorted(staged),
        "remaining_ids": sorted(remaining.matched_ids),
        "committed_ids": sorted(committed_ids),
        "hunks": out_hunks,
        "files": _files_view(session, staged, remaining.matched_ids, unaligned),
        "fabricated_files": session.data["fabricated_files"],
    }


def cmd_status(args):
    session = Session.load(args.repo)
    if session.data.get("completed"):
        return _completed_status_summary(session)
    applied = session.applied_align()
    committed_ids = {i for c in session.data["committed"] for i in c["ids"]}
    staged = applied.matched_ids - committed_ids
    remaining = session.remaining_align(exclude_ids=applied.matched_ids)
    plan = session.data.get("plan")
    unaligned = {}
    for d in (applied.unaligned, remaining.unaligned):
        for k, v in d.items():
            unaligned.setdefault(k, []).extend(v)
    return {
        "staged_ids": sorted(staged),
        "remaining_ids": sorted(remaining.matched_ids),
        "committed_ids": sorted(committed_ids),
        "files": _files_view(session, staged, remaining.matched_ids, unaligned),
        "committed": [{"oid": c["oid"], "msg": c["msg"], "n_ids": len(c["ids"])}
                      for c in session.data["committed"]],
        "fabricated_files": session.data["fabricated_files"],
        "plan_cursor": plan["cursor"] if plan else None,
    }


def cmd_add(args):
    from splitstage.staging import stage_ids, resolve_selection, _stage_lines
    session = Session.load(args.repo)
    _reject_if_completed(session)
    uses_selector = bool(args.file or args.remaining or args.except_ids
                         or args.except_files)
    if not uses_selector:
        if not args.ids:
            raise CommandError("nothing selected; pass ids or a selector "
                               "(--file/--remaining/--except/--except-file)")
        return stage_ids(session, args.ids)      # 従来経路 (hunk patch 経路を温存)
    line_ids = resolve_selection(
        session,
        positional=args.ids,
        files=args.file or [],
        remaining=args.remaining,
        except_ids=args.except_ids or [],
        except_files=args.except_files or [])
    return _stage_lines(session, line_ids)


def cmd_set(args):
    from splitstage.staging import stage_content
    session = Session.load(args.repo)
    _reject_if_completed(session)
    if args.delete:
        content = None
    elif args.from_file:
        content = Path(args.from_file).read_text()
    else:
        content = sys.stdin.read()
    return stage_content(session, args.file, content)


def cmd_verify(args):
    from splitstage.verify import verify
    session = Session.load(args.repo)
    if session.data.get("completed"):
        return _completed_verify_summary(session)
    return verify(session, betweenness=not args.no_betweenness)


def cmd_commit(args):
    from splitstage.verify import do_commit
    session = Session.load(args.repo)
    _reject_if_completed(session)
    return do_commit(session, args.message)


def cmd_abort(args):
    from splitstage.verify import do_abort
    session = Session.load(args.repo)
    return do_abort(session)


def cmd_plan(args):
    from splitstage.plan import apply_plan
    session = Session.load(args.repo)
    _reject_if_completed(session)
    plan = json.loads(Path(args.plan_file).read_text())
    return apply_plan(session, plan)


def cmd_continue(args):
    from splitstage.plan import continue_plan
    session = Session.load(args.repo)
    _reject_if_completed(session)
    return continue_plan(session)


# ------------------------------------------------------------------ plumbing

def build_parser():
    p = argparse.ArgumentParser(prog="git-split")
    p.add_argument("--repo", default=".", help="対象 repo (既定: カレント)")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("start")
    s.add_argument("--tracked-only", action="store_true",
                   help="untracked ファイルを分割対象に含めない "
                        "(git add -N をスキップ)")
    s.set_defaults(fn=cmd_start)

    s = sub.add_parser("show")
    s.add_argument("--lines", action="store_true")
    s.add_argument("--file", action="append", default=None,
                   help="出力を指定ファイルに限定 (繰り返し可)")
    s.add_argument("-U", dest="context", type=int, default=None)
    s.set_defaults(fn=cmd_show)

    sub.add_parser("status").set_defaults(fn=cmd_status)

    s = sub.add_parser("add")
    s.add_argument("ids", nargs="*")
    s.add_argument("--file", action="append", default=None,
                   help="そのファイルの remaining を全部 (繰り返し可)")
    s.add_argument("--remaining", action="store_true",
                   help="remaining な変更を全部")
    s.add_argument("--except", dest="except_ids", nargs="+", default=None,
                   help="指定 ID を除外 (hunk ID 可)")
    s.add_argument("--except-file", dest="except_files", action="append",
                   default=None, help="そのファイルを丸ごと除外 (繰り返し可)")
    s.set_defaults(fn=cmd_add)

    s = sub.add_parser("set")
    s.add_argument("file")
    s.add_argument("--from", dest="from_file", default=None,
                   help="stdin の代わりにこのファイルの内容を使う")
    s.add_argument("--delete", action="store_true",
                   help="ファイルの削除を stage する")
    s.set_defaults(fn=cmd_set)

    s = sub.add_parser("verify")
    s.add_argument("--no-betweenness", action="store_true")
    s.set_defaults(fn=cmd_verify)

    s = sub.add_parser("commit")
    s.add_argument("-m", "--message", required=True)
    s.set_defaults(fn=cmd_commit)

    sub.add_parser("abort").set_defaults(fn=cmd_abort)

    s = sub.add_parser("plan")
    s.add_argument("plan_file")
    s.set_defaults(fn=cmd_plan)

    sub.add_parser("continue").set_defaults(fn=cmd_continue)
    return p


def main(argv=None):
    argv = argv if argv is not None else sys.argv[1:]
    args = build_parser().parse_args(argv)
    try:
        from splitstage.state import _git_dir
        log_path = _git_dir(args.repo) / STATE_DIR_NAME / "oplog.jsonl"
    except Exception:
        # git repo でない場合など。本処理側のエラーをそのまま返すため続行
        log_path = Path(args.repo) / ".git" / STATE_DIR_NAME / "oplog.jsonl"
    try:
        result = args.fn(args)
        out = {"ok": True, **result}
        code = 0
    except SplitstageError as e:
        out = {"ok": False, "error": str(e)}
        code = 1
    except Exception as e:   # 想定外でも traceback ではなく JSON で返す
        import traceback
        try:
            (Path(log_path).parent / "last_traceback.txt").write_text(
                traceback.format_exc())
        except Exception:
            pass
        out = {"ok": False,
               "error": f"internal error: {e.__class__.__name__}: {e}"}
        code = 1
    try:
        oplog.append(log_path, {"cmd": args.cmd, "argv": argv, "ok": out["ok"],
                                **({"error": out["error"]} if not out["ok"] else {})})
    except Exception:
        pass  # ログ不能でも本処理は返す
    print(json.dumps(out, ensure_ascii=False, indent=1))
    return code


if __name__ == "__main__":
    sys.exit(main())
