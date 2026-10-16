#!/usr/bin/env bash
# forgejow の統合テスト。実際の forgejo を起動して検証する。
#
# 検証したい挙動 (返信が同一スレッドに入るか、コミット後もスレッドが残るか、
# resolve が API に反映されるか) はすべてサーバ側の実装に依存するので、スタブは
# 作らない。起動が1秒台なので実物を使う。
#
# 状態を汚さないため XDG_STATE_HOME と XDG_RUNTIME_DIR をテスト用の一時
# ディレクトリに差し替える。レビュー対象のリポジトリも一時ディレクトリに作る。
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGEJOW="$SCRIPT_DIR/forgejow"

WORK=$(mktemp -d)
export XDG_STATE_HOME="$WORK/state"
export XDG_RUNTIME_DIR="$WORK/run"
mkdir -p "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR"

pass=0
fail=0
REQUEST_PID=""
REQUEST_OUT=""

# 起動したインスタンスは pid ファイルから直接止める。$WORK を消してから down を
# 呼ぶ順序になるとプロセスが取り残され、ポートを掴んだまま次回のテストに干渉する。
cleanup() {
  local f
  if [ -n "$REQUEST_PID" ]; then
    kill -TERM "$REQUEST_PID" 2>/dev/null || true
    wait "$REQUEST_PID" 2>/dev/null || true
  fi
  for f in "$XDG_RUNTIME_DIR"/forgejo-review/*/web.pid; do
    [ -f "$f" ] || continue
    kill "$(cat "$f")" 2>/dev/null || true
  done
  rm -rf "$WORK"
}
trap cleanup EXIT

ok() { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
ng() { printf '  NG   %s\n       %s\n' "$1" "${2:-}"; fail=$((fail + 1)); }

assert_eq() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then ok "$label"; else ng "$label" "want=$want got=$got"; fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  case "$haystack" in
    *"$needle"*) ok "$label" ;;
    # 失敗時は実際の出力も残す。出力が空だったのか別物だったのかを、再実行せずに
    # 切り分けられるようにする。
    *) ng "$label" "'$needle' が出力に無い。実際の出力: [$(printf '%s' "$haystack" | head -c 400)]" ;;
  esac
}

wait_until() {
  local description="$1"
  shift
  for _ in $(seq 1 120); do
    "$@" && return 0
    sleep 0.25
  done
  ng "$description" "timed out"
  return 1
}

process_is_dead() { ! ps -o stat= -p "$1" 2>/dev/null | grep -qv '^Z'; }
process_is_running() { ps -o stat= -p "$1" 2>/dev/null | grep -qv '^Z'; }
output_has_pr() { grep -q '診断ログ:' "$1" 2>/dev/null; }

start_request_lease() {
  REQUEST_OUT="$WORK/request-review-$RANDOM.out"
  setsid "$FORGEJOW" request-review "$(cat "$WORK/base")..HEAD" \
    >"$REQUEST_OUT" 2>&1 &
  REQUEST_PID=$!
  wait_until "request-review が PR 情報を出力する" output_has_pr "$REQUEST_OUT"
}

# レビュー対象のリポジトリを作る。base の後に2コミット積む。
setup_repo() {
  mkdir -p "$WORK/repo"
  cd "$WORK/repo" || exit 1
  git init -q -b main
  git config user.email dev@example.invalid
  git config user.name dev
  git config commit.gpgsign false
  printf 'def add(a, b):\n    return a + b\n' >app.py
  git add -A && git commit -qm 'feat: add()'
  git rev-parse HEAD >"$WORK/base"
  printf '\n\ndef div(a, b):\n    return a / b\n' >>app.py
  git add -A && git commit -qm 'feat: div() を追加する'
  printf '\n\ndef mul(a, b):\n    return a * b\n' >>app.py
  git add -A && git commit -qm 'feat: mul() を追加する'
}

echo "=== Task 1: インスタンスの起動と破棄 ==="
setup_repo
# shellcheck source=lib/forgejo_instance.sh
. "$SCRIPT_DIR/lib/forgejo_instance.sh"
fj_up || ng "fj_up が失敗した" "$(tail -3 "$(fj_run_dir)/log/web.log" 2>/dev/null)"
DIAGNOSTICS_FILE="$(fj_diagnostics_file)"
FORGEJO_PID="$(cat "$(fj_run_dir)/web.pid")"
assert_eq "新規起動した Forgejo の PID を所有する" "$FORGEJO_PID" "$FJ_STARTED_PID"
read -r FORGEJO_PGID FORGEJO_SID FORGEJO_TTY < <(
  ps -o pgid=,sid=,tty= -p "$FORGEJO_PID"
)
assert_eq "Forgejo が専用 process group にいる" "$FORGEJO_PID" "$FORGEJO_PGID"
assert_eq "Forgejo が専用 session にいる" "$FORGEJO_PID" "$FORGEJO_SID"
assert_eq "Forgejo が controlling TTY を持たない" "?" "$FORGEJO_TTY"
assert_eq "healthz が 200 を返す" 200 \
  "$(curl -sS -o /dev/null -w '%{http_code}' "http://localhost:$(fj_port)/api/healthz")"
assert_eq "agent が uid 1 になる" 1 \
  "$(sqlite3 "$(fj_run_dir)/data/forgejo.db" "SELECT id FROM \`user\` WHERE lower_name='agent';")"
assert_eq "reviewer が uid 2 になる" 2 \
  "$(sqlite3 "$(fj_run_dir)/data/forgejo.db" "SELECT id FROM \`user\` WHERE lower_name='reviewer';")"
assert_eq "credentials が永続ディレクトリに在る" yes \
  "$([ -f "$(fj_state_dir)/credentials" ] && echo yes || echo no)"
assert_eq "セッションストアが永続ディレクトリに在る" yes \
  "$([ -d "$(fj_state_dir)/sessions" ] && echo yes || echo no)"
assert_eq "state ディレクトリが forgejo-review 名前空間にある" yes \
  "$(case "$(fj_state_dir)" in */forgejo-review) echo yes;; *) echo no;; esac)"
assert_eq "run ディレクトリが forgejo-review 名前空間にある" yes \
  "$(case "$(fj_run_dir)" in */forgejo-review/*) echo yes;; *) echo no;; esac)"
assert_eq "旧スキル名がパスに残らない" no \
  "$(case "$(fj_state_dir)$(fj_run_dir)" in *patched-superpowers*) echo yes;; *) echo no;; esac)"
assert_contains "APP_NAME が forgejo-review になる" "APP_NAME = forgejo-review" \
  "$(cat "$(fj_conf)")"
assert_eq "spawned 診断イベントがプロセス識別情報を持つ" 1 \
  "$(jq -s --argjson pid "$FORGEJO_PID" '[.[] | select(.event == "forgejo_spawned" and .process.pid == $pid and (.process.ppid | type) == "number" and (.process.processGroupId | type) == "number" and (.process.sessionId | type) == "number")] | length' "$DIAGNOSTICS_FILE")"

PORT_BEFORE="$(fj_port)"
sleep 300 &
UNSAFE_PID=$!
echo "$UNSAFE_PID" >"$(fj_run_dir)/web.pid"
assert_eq "安全でない既存 Forgejo を再利用しない" 1 "$(fj_up; echo $?)"
kill "$UNSAFE_PID" 2>/dev/null || true
wait "$UNSAFE_PID" 2>/dev/null || true
echo "$FORGEJO_PID" >"$(fj_run_dir)/web.pid"
fj_up
assert_eq "再実行で同じインスタンスを再利用する" "$PORT_BEFORE" "$(fj_port)"
assert_eq "再利用した Forgejo の PID は所有しない" "" "$FJ_STARTED_PID"

FORGEJO_PID="$(cat "$(fj_run_dir)/web.pid")"
fj_down
assert_eq "down で実行ディレクトリが消える" no \
  "$([ -d "$(fj_run_dir)" ] && echo yes || echo no)"
assert_eq "down でも credentials は残る" yes \
  "$([ -f "$(fj_state_dir)/credentials" ] && echo yes || echo no)"
assert_eq "down の SIGTERM 診断イベントが記録される" 1 \
  "$(jq -s --argjson pid "$FORGEJO_PID" '[.[] | select(.event == "forgejo_signal_sent" and .signal == "SIGTERM" and .reason == "down" and .process.pid == $pid)] | length' "$DIAGNOSTICS_FILE")"

echo "=== Task 2: リポジトリ作成と PR の用意 ==="
cd "$WORK/repo" || exit 1
start_request_lease
OUT="$(cat "$REQUEST_OUT")"
assert_contains "PR の URL を出力する" "/pulls/1" "$OUT"
assert_contains "div のコミットを列挙する" "div() を追加する" "$OUT"
assert_contains "mul のコミットを列挙する" "mul() を追加する" "$OUT"
assert_contains "ログイン情報を出力する" "ユーザー:   reviewer" "$OUT"
assert_contains "診断ログのパスを出力する" "診断ログ: $DIAGNOSTICS_FILE" "$OUT"
assert_eq "request-review が出力後も lease を保持する" yes \
  "$(process_is_running "$REQUEST_PID" && echo yes || echo no)"

# shellcheck source=lib/forgejo_api.sh
. "$SCRIPT_DIR/lib/forgejo_api.sh"
REPO="$(fj_ensure_repo)"
assert_eq "PR に2コミット載る" 2 \
  "$(fj_api GET "/repos/$REPO/pulls/1/commits" | jq 'length')"
assert_eq "base コミットは PR に含まれない" 0 \
  "$(fj_api GET "/repos/$REPO/pulls/1/commits" \
     | jq --arg b "$(cat "$WORK/base")" '[.[] | select(.sha == $b)] | length')"
assert_eq "PR body にレビュー対象の range が載る" \
  "レビュー対象: $(cat "$WORK/base")..HEAD" \
  "$(fj_api GET "/repos/$REPO/pulls/1" | jq -r '.body')"
assert_eq "reviewer が write 権限を持つ" true \
  "$(fj_api GET "/repos/$REPO/collaborators/reviewer/permission" \
     | jq -r '.permission == "write"')"

# 人間のブラウザを模したセッションを用意する。閲覧自体は匿名でもできるが、コメントの
# 投稿にはログインが必要で、行コメントのボタンは匿名では描画されない。
fj_credentials
REVIEWER_JAR="$(fj_run_dir)/cookies-reviewer-test"
curl -sS -c "$REVIEWER_JAR" -o /dev/null \
  -d "user_name=reviewer&password=$FJ_REVIEWER_PASS" \
  "http://localhost:$(fj_port)/user/login"
assert_eq "reviewer が PR の files ページを開ける" 200 \
  "$(curl -sS -o /dev/null -w '%{http_code}' -b "$REVIEWER_JAR" "$(fj_pr_url)/files")"

echo "=== Task 3: スレッドの取得 ==="
# shellcheck source=lib/forgejo_format.sh
. "$SCRIPT_DIR/lib/forgejo_format.sh"
# reviewer が per-commit ビューから指摘を付けた状態を作る。
HEAD_SHA="$(git rev-parse HEAD)"
curl -sS -b "$REVIEWER_JAR" -o /dev/null \
  -X POST "$(fj_pr_url)/files/reviews/comments" \
  --data-urlencode "origin=diff" \
  --data-urlencode "latest_commit_id=$HEAD_SHA" \
  --data-urlencode "side=proposed" \
  --data-urlencode "line=4" \
  --data-urlencode "path=app.py" \
  --data-urlencode "single_review=true" \
  --data-urlencode "content=div: ゼロ除算を検証していない"

THREADS="$(fj_threads)"
assert_eq "スレッドが1件見える" 1 "$(echo "$THREADS" | jq 'length')"
assert_eq "投稿者が reviewer になる" reviewer \
  "$(echo "$THREADS" | jq -r '.[0].comments[0].author')"
assert_eq "未 resolve である" false "$(echo "$THREADS" | jq -r '.[0].resolved')"
assert_eq "返答待ちと判定する" true "$(echo "$THREADS" | jq -r '.[0].awaiting_reply')"
assert_eq "path を持つ" app.py "$(echo "$THREADS" | jq -r '.[0].path')"
assert_contains "html_url を持つ" "/pulls/1" "$(echo "$THREADS" | jq -r '.[0].html_url')"
assert_contains "対象の diff hunk を持つ" "@@" "$(echo "$THREADS" | jq -r '.[0].diff_hunk')"

OUT="$("$FORGEJOW" fetch-comments)"
assert_contains "平文出力に本文が出る" "ゼロ除算" "$OUT"
assert_contains "平文出力に thread が出る" "thread:" "$OUT"
assert_contains "平文出力に返答待ちの一覧が出る" "返答待ちのスレッド" "$OUT"
# 行番号だけでは前後の文脈が分からないので、対象コードが出ないとどこへの指摘か
# 読み取りにくい。
assert_contains "平文出力に対象コードが出る" "│ @@" "$OUT"
assert_eq "--json は JSON を返す" 1 "$("$FORGEJOW" fetch-comments --json | jq 'length')"

echo "=== Task 4: 返信と resolve ==="
TID="$(fj_threads | jq -r '.[0].thread_id')"
echo "ゼロ除算の検証を追加した" | "$FORGEJOW" reply "$TID" || ng "reply が失敗した" ""
THREADS="$(fj_threads)"
assert_eq "同一スレッドに返信が入る" 2 "$(echo "$THREADS" | jq '.[0].comments | length')"
assert_eq "返信の投稿者が agent になる" agent \
  "$(echo "$THREADS" | jq -r '.[0].comments[-1].author')"
assert_eq "返信後は返答待ちでなくなる" false \
  "$(echo "$THREADS" | jq -r '.[0].awaiting_reply')"
assert_eq "スレッドは増えない" 1 "$(echo "$THREADS" | jq 'length')"

echo "対応済み" | "$FORGEJOW" resolve "$TID" || ng "resolve が失敗した" ""
assert_eq "resolve が反映される" true "$(fj_threads | jq -r '.[0].resolved')"
assert_eq "resolve した主体が記録される" agent "$(fj_threads | jq -r '.[0].resolver')"

echo "=== Task 4b: 複数行コメントへの返信 ==="
# Forgejo の UI は会話を (path, side, 表示行) で分ける。表示行は範囲の末尾
# (行 + extra_lines_count) なので、返信が extra_lines_count を引き継がないと
# API 上は同じ review に入ってもブラウザでは別スレッドとして描画される。
# fj_threads のレベルでは検出できない分裂なので、ブラウザが受け取る HTML の
# conversation-holder の数で判定する。
count_holders() {
  curl -sS -b "$REVIEWER_JAR" "$(fj_pr_url)/files" |
    grep -o 'class="conversation-holder"' | wc -l
}
# reviewer が div() の2行 (5-6行目) にまたがる指摘を付ける。UI と同じく範囲の
# 先頭行 + extra_lines_count で表す。
curl -sS -b "$REVIEWER_JAR" -o /dev/null \
  -X POST "$(fj_pr_url)/files/reviews/comments" \
  --data-urlencode "origin=diff" \
  --data-urlencode "latest_commit_id=$HEAD_SHA" \
  --data-urlencode "side=proposed" \
  --data-urlencode "line=5" \
  --data-urlencode "extra_lines_count=1" \
  --data-urlencode "path=app.py" \
  --data-urlencode "single_review=true" \
  --data-urlencode "content=div: 名前が省略されすぎている"
MTID="$(fj_threads | jq -r '.[] | select(.extra_lines_count == 1) | .thread_id')"
assert_eq "複数行スレッドが1件見える" 1 "$(echo "$MTID" | wc -w)"
HOLDERS_BEFORE="$(count_holders)"
echo "divide に改名した" | "$FORGEJOW" reply "$MTID" || ng "複数行スレッドへの reply が失敗した" ""
THREADS="$(fj_threads)"
assert_eq "複数行スレッドに返信が入る" 2 \
  "$(echo "$THREADS" | jq --argjson t "$MTID" '.[] | select(.thread_id == $t) | .comments | length')"
assert_eq "複数行への返信でスレッドは増えない" 2 "$(echo "$THREADS" | jq 'length')"
assert_eq "ブラウザ表示でも会話が分かれない" "$HOLDERS_BEFORE" "$(count_holders)"

echo "=== Task 5: 修正コミットの push ==="
printf '\n\ndef sub(a, b):\n    return a - b\n' >>app.py
git add -A && git commit -qm 'fix: sub() を追加する'
FIX_SHA="$(git rev-parse HEAD)"
OUT="$("$FORGEJOW" push)"
# URL は完全な SHA で組む。per-commit ビューは短縮 SHA では 404 を返す。文字列の
# 一致だけでは検出できなかったので、実際に開けることも確かめる。
assert_contains "新規コミットの URL を出力する" "/commits/$FIX_SHA" "$OUT"
assert_eq "per-commit URL が開ける" 200 \
  "$(curl -sS -o /dev/null -w '%{http_code}' "$(fj_pr_url)/commits/$FIX_SHA")"
assert_contains "新規コミットの件名を出力する" "sub() を追加する" "$OUT"
assert_eq "PR が修正コミットを取り込む" 3 \
  "$(fj_api GET "/repos/$REPO/pulls/1/commits" | jq 'length')"
assert_eq "既存スレッドは残る" 2 "$(fj_threads | jq 'length')"
assert_eq "resolve 状態も残る" true "$(fj_threads | jq -r '.[0].resolved')"
OUT="$("$FORGEJOW" push)"
assert_contains "変更が無ければ新規なしと報告する" "新しいコミットはない" "$OUT"
# stale は「指摘が古い」ではなく「レビュー後に head が動いた」を意味する。読み手が
# 指摘の鮮度と誤解しないよう、意味をそのまま書く。
assert_contains "stale を意味の分かる表示にする" "レビュー時点より head が進んでいる" \
  "$("$FORGEJOW" fetch-comments)"

echo "=== Task 6: スモークテスト ==="
assert_eq "スモークが通る" 0 "$(fj_smoke >/dev/null 2>&1; echo $?)"
assert_eq "スモークがスクラッチリポジトリを残さない" 404 \
  "$(curl -sS -o /dev/null -w '%{http_code}' -H "Authorization: token $(fj_token)" \
     "http://localhost:$(fj_port)/api/v1/repos/agent/_forgejow_smoke")"
# 経路が壊れた場合に落ちることを、返信の経路を差し替えて確認する。
assert_eq "返信経路が壊れていれば失敗する" 1 \
  "$(FJ_SMOKE_REPLY_PATH=/does/not/exist fj_smoke >/dev/null 2>&1; echo $?)"

echo "=== Task 7: foreground lease の SIGHUP cleanup ==="
HUP_WEB_PID="$(cat "$(fj_run_dir)/web.pid")"
kill -HUP -- "-$REQUEST_PID" || ng "waiter process group に SIGHUP を送れる" "kill failed"
wait_until "SIGHUP 後に request-review が終了する" process_is_dead "$REQUEST_PID"
wait_until "SIGHUP cleanup 後に Forgejo が終了する" process_is_dead "$HUP_WEB_PID"
assert_eq "waiter の SIGHUP で Forgejo も終了する" no \
  "$(process_is_running "$HUP_WEB_PID" && echo yes || echo no)"
wait "$REQUEST_PID" 2>/dev/null || true
REQUEST_PID=""

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
