#!/usr/bin/env bash
# critw の統合テスト。実際の crit を起動して検証する。
#
# 検証したいのは「share 先が潰れているか」「gh に認証情報が渡らないか」
# 「Finish Review 後にコメントと承認可否が出るか」で、いずれも crit の実装に
# 依存するのでスタブは作らない。
#
# crit は ~/.crit にデーモンとプランを置くので、HOME を一時ディレクトリに差し替えて
# 本物のセッションから隔離する。gh は呼ばれた環境を記録するシムに差し替える。
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRITW="$SCRIPT_DIR/critw"

WORK=$(mktemp -d)
export HOME="$WORK/home"
export XDG_RUNTIME_DIR="$WORK/run"
export GH_SHIM_LOG="$WORK/gh.log"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$WORK/bin"
cat >"$WORK/bin/gh" <<'SHIM'
#!/usr/bin/env bash
echo "GH_TOKEN=[${GH_TOKEN-unset}] GITHUB_TOKEN=[${GITHUB_TOKEN-unset}] GH_CONFIG_DIR=[${GH_CONFIG_DIR-unset}]" >>"$GH_SHIM_LOG"
exit 4
SHIM
chmod +x "$WORK/bin/gh"
export PATH="$WORK/bin:$PATH"
export GITHUB_TOKEN="dummy-token"

# テストが直接呼ぶ crit は更新確認を切る。critw を経由しない起動が GitHub に
# 問い合わせに行くのを防ぐためで、critw 自身は自分の環境で切る。
rawcrit() { CRIT_NO_UPDATE_CHECK=1 crit "$@"; }

# それでも外へ出ようとする通信は、到達不能なプロキシに向けてその場で落とす。
# crit も gh も curl もプロキシの環境変数を見る。ループバックは除外しないと
# テスト自身の curl が通らない。
export HTTP_PROXY=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 ALL_PROXY=http://127.0.0.1:9
export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY all_proxy=$ALL_PROXY
export NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost

pass=0
fail=0
REQUEST_PID=""

cleanup() {
  if [ -n "$REQUEST_PID" ]; then
    kill -TERM "$REQUEST_PID" 2>/dev/null || true
    wait "$REQUEST_PID" 2>/dev/null || true
  fi
  rawcrit stop --all >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

check() {
  local name="$1" ok="$2"
  if [ "$ok" = 0 ]; then
    echo "ok   $name"; pass=$((pass + 1))
  else
    echo "FAIL $name"; fail=$((fail + 1))
  fi
}

wait_for() {
  local i
  for _ in $(seq 1 60); do
    if eval "$1"; then return 0; fi
    sleep 0.5
  done
  return 1
}

port_of() { cat "$XDG_RUNTIME_DIR/critw/port" 2>/dev/null; }

finish_review() {
  local sid
  sid="$(rawcrit status --json | sed -n 's/^ *"id": *"\([0-9a-f]*\)",*$/\1/p' | head -1)"
  curl -s -X POST "http://127.0.0.1:$(port_of)/api/finish" -H "X-Crit-Session: $sid" >/dev/null
}

printf '# spec\n\nhello\n' >"$WORK/2026-01-01-Sample-Design.md"

# --- round 1: 起動と安全確認 -------------------------------------------------
"$CRITW" request-review "$WORK/2026-01-01-Sample-Design.md" >"$WORK/req1.out" 2>"$WORK/req1.err" &
REQUEST_PID=$!
wait_for '[ -s "$XDG_RUNTIME_DIR/critw/port" ]'
check "request-review がポートを記録する" $?

"$CRITW" report | grep -q "URL:  http://localhost:$(port_of)"
check "report が URL を出す" $?

[ "$(cat "$XDG_RUNTIME_DIR/critw/slug")" = "2026-01-01-sample-design" ]
check "slug はファイル名から拡張子を除いて小文字にしたもの" $?

curl -s "http://127.0.0.1:$(port_of)/api/config" | grep -q '"share_url":"http://127.0.0.1:9"'
check "デーモンの share_url が到達不能アドレスになる" $?

if [ -s "$GH_SHIM_LOG" ]; then
  ! grep -qv 'GH_TOKEN=\[\] GITHUB_TOKEN=\[\]' "$GH_SHIM_LOG"
  check "gh が呼ばれるなら認証情報は空" $?
else
  echo "skip gh は呼ばれなかった"
fi

# --- round 1 終了: コメントなしで承認 ---------------------------------------
finish_review
wait "$REQUEST_PID"; rc=$?; REQUEST_PID=""
[ "$rc" = 0 ] && grep -q '^approved: true' "$WORK/req1.out"
check "Finish Review で request-review が戻り approved: true を出す" $?

# --- round 2 ----------------------------------------------------------------
# 承認で終わったラウンドの後はデーモンが残らないので、ポートの一致は見ない。
"$CRITW" request-review "$WORK/2026-01-01-Sample-Design.md" >"$WORK/req2.out" 2>"$WORK/req2.err" &
REQUEST_PID=$!
wait_for 'grep -q "^URL:" "$WORK/req2.out"'
check "2 ラウンド目も起動する" $?
curl -s "http://127.0.0.1:$(port_of)/api/config" | grep -q '"share_url":"http://127.0.0.1:9"'
check "2 ラウンド目も share_url が到達不能アドレスになる" $?

# --- 返信 -------------------------------------------------------------------
rawcrit comment --plan 2026-01-01-sample-design 2026-01-01-sample-design.md:3 "clarify" >/dev/null 2>&1
cid="$("$CRITW" comments --json | sed -n 's/^ *"id": *"\(c_[0-9a-z]*\)",*$/\1/p' | head -1)"
[ -n "$cid" ]
check "comments がコメント id を返す" $?
echo "clarified" | "$CRITW" reply "$cid" >/dev/null 2>&1
check "reply が成功する" $?

finish_review
wait "$REQUEST_PID"; REQUEST_PID=""

# --- share 先が潰れたデーモンは使い回す ----------------------------------------
rawcrit stop --all >/dev/null 2>&1
rawcrit plan --share-url http://127.0.0.1:9 --no-open --name 2026-01-01-sample-design "$WORK/2026-01-01-Sample-Design.md" >/dev/null 2>&1 &
SAFE_PID=$!
wait_for 'rawcrit status --json | grep -q "\"running\": true"'
safe_port="$(rawcrit status --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["sessions"][0]["port"])')"
"$CRITW" request-review "$WORK/2026-01-01-Sample-Design.md" >"$WORK/req4.out" 2>"$WORK/req4.err" &
REQUEST_PID=$!
wait_for 'grep -q "^URL:" "$WORK/req4.out"'
[ "$(port_of)" = "$safe_port" ] && ! grep -q "止める" "$WORK/req4.err"
check "share 先が潰れたデーモンはそのまま使う" $?
# このデーモンには手動起動分と critw 分の 2 セッションがぶら下がるので、Finish Review
# では片方しか戻らない。ここでは再利用だけを見たいので両方とも落とす。
kill "$SAFE_PID" "$REQUEST_PID" 2>/dev/null
wait "$SAFE_PID" "$REQUEST_PID" 2>/dev/null
REQUEST_PID=""

# --- share 先が生きているデーモンは止める ---------------------------------------
rawcrit stop --all >/dev/null 2>&1
rawcrit plan --no-open --name unsafe "$WORK/2026-01-01-Sample-Design.md" >/dev/null 2>&1 &
UNSAFE_PID=$!
wait_for 'rawcrit status --json | grep -q "\"running\": true"'
"$CRITW" request-review "$WORK/2026-01-01-Sample-Design.md" >"$WORK/req3.out" 2>"$WORK/req3.err" &
REQUEST_PID=$!
wait_for 'grep -q "^URL:" "$WORK/req3.out"'
grep -q "share 先が潰れていないデーモン" "$WORK/req3.err" \
  && curl -s "http://127.0.0.1:$(port_of)/api/config" | grep -q '"share_url":"http://127.0.0.1:9"'
check "share 先が生きているデーモンは止めてから起動する" $?
kill "$UNSAFE_PID" 2>/dev/null; wait "$UNSAFE_PID" 2>/dev/null
finish_review
wait "$REQUEST_PID"; REQUEST_PID=""

echo
echo "pass=$pass fail=$fail"
[ "$fail" = 0 ]
