"""案C: plan 一括実行 (宣言的制御)。

plan 形式:
  [ {"msg": "...", "ids": ["h:.." | "l:..", ...]},
    {"msg": "...", "edit": true},
    ... ]

各ステップで stage → staged 集合の検証 → commit を回す。
"edit": true のステップでは停止して制御を返し、手動 (生の git や
`set`) で staged を作ってもらってから `continue` で再開する。
ステップ失敗時はそのステップで停止する。全戻しは `abort`。
"""

from splitstage import SplitstageError
from splitstage.staging import stage_content, stage_ids
from splitstage.verify import do_commit


class PlanError(SplitstageError):
    pass


def _validate(plan):
    if not isinstance(plan, list) or not plan:
        raise PlanError("plan must be a non-empty JSON array")
    for i, step in enumerate(plan):
        if not isinstance(step, dict) or "msg" not in step:
            raise PlanError(f"step {i}: each step needs a msg")
        if not step.get("edit") and not step.get("ids"):
            raise PlanError(f"step {i}: needs ids (or \"edit\": true)")


def apply_plan(session, plan):
    _validate(plan)
    if session.data.get("plan"):
        raise PlanError("a plan is already in progress (continue or abort)")
    session.data["plan"] = {"steps": plan, "cursor": 0}
    session.save()
    return _run(session)


def continue_plan(session):
    state = session.data.get("plan")
    if not state:
        raise PlanError("no plan in progress")
    step = state["steps"][state["cursor"]]
    if step.get("edit"):
        # 手動介入の結果 (現在 staged の内容) をこのステップとして commit
        result = do_commit(session, step["msg"])
        state["cursor"] += 1
        session.data["plan"] = state
        session.save()
        return _run(session, first_result=result)
    # ids ステップで失敗して停止していた場合: そのステップから再試行
    return _run(session)


def _run(session, first_result=None):
    state = session.data["plan"]
    executed = [first_result] if first_result else []
    while state["cursor"] < len(state["steps"]):
        i = state["cursor"]
        step = state["steps"][i]
        if step.get("edit"):
            session.data["plan"] = state
            session.save()
            return {
                "paused": True,
                "cursor": i,
                "msg": step["msg"],
                "note": ("stage the intended changes manually (raw git, or "
                         "`set`), then run `continue`"),
                "executed": executed,
            }
        try:
            stage_ids(session, step["ids"])
            result = do_commit(session, step["msg"])
        except SplitstageError as e:
            session.data["plan"] = state
            session.save()
            raise PlanError(
                f"step {i} ({step['msg']!r}) failed: {e}. "
                "fix manually and use continue/abort") from e
        executed.append(result)
        state["cursor"] += 1
        session.data["plan"] = state
        session.save()
    session.data["plan"] = None
    session.save()
    last = executed[-1] if executed else {}
    return {
        "paused": False,
        "executed": executed,
        "complete": bool(last.get("complete")),
    }
