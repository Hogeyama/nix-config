#!/usr/bin/env bash
# fj_threads の整形ロジックの単体テスト。Forgejo を起動せずに実行する。
#
# 統合テスト (test_forgejow.sh) はサーバ側の実装に依存する挙動を実物で検証するため
# スタブを置かない。一方スレッドの並び順とグルーピングは API のレスポンスを受けた後の
# 自前の jq が決めるので、レスポンスを固定した方が意図した入力を作れる。特に「同一
# review 内で position の降順にコメントが付いた」状態は、実サーバ相手には作りにくい。
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/forgejo_api.sh
. "$SCRIPT_DIR/lib/forgejo_api.sh"

pass=0
fail=0

ok() { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
ng() { printf '  NG   %s\n       %s\n' "$1" "${2:-}"; fail=$((fail + 1)); }

assert_eq() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then ok "$label"; else ng "$label" "want=$want got=$got"; fi
}

fj_ensure_repo() { echo agent/review; }
fj_pr_num() { echo 1; }

# Forgejo 16 の API と同じ形にする。position と original_position はどちらも符号なしの
# ファイル行番号で、proposed 側は position、previous 側は original_position に入る
# (もう一方は 0)。複数行コメントは範囲の先頭行 + extra_lines_count で表す。
comment() {
  local id="$1" path="$2" position="$3" original="$4" extra="$5" author="$6"
  printf '{
    "id": %s, "path": "%s", "position": %s, "original_position": %s,
    "extra_lines_count": %s, "commit_id": "0123456789abcdef",
    "resolver": null, "html_url": "http://localhost/pulls/1#issuecomment-%s",
    "diff_hunk": "@@ -1,1 +1,1 @@", "created_at": "2026-08-14T00:00:00Z",
    "user": {"login": "%s"}, "body": "comment %s"
  }' "$id" "$path" "$position" "$original" "$extra" "$id" "$author" "$id"
}

# review 7 は position の降順にコメントが付いた状態。group_by([path, position]) の
# 結果をそのまま返すと 13, 12, 11 の順に並ぶ。review 3 は review 7 より後に API から
# 返るが、コメント id は小さい。並べ替えないと review の取得順が出力順を決める。
# shellcheck disable=SC2329 # fj_threads から呼ばれる。
fj_api() {
  local path="$2"
  case "$path" in
    */reviews)
      printf '[
        {"id": 7, "state": "COMMENT", "stale": false, "comments_count": 3},
        {"id": 9, "state": "PENDING", "stale": false, "comments_count": 1},
        {"id": 3, "state": "COMMENT", "stale": true, "comments_count": 1},
        {"id": 15, "state": "COMMENT", "stale": false, "comments_count": 5}
      ]'
      ;;
    */reviews/7/comments)
      printf '[%s, %s, %s]' \
        "$(comment 11 b.py 2 0 0 reviewer)" \
        "$(comment 12 a.py 9 0 0 reviewer)" \
        "$(comment 13 a.py 3 0 0 reviewer)"
      ;;
    */reviews/3/comments)
      printf '[%s]' "$(comment 5 a.py 1 0 0 reviewer)"
      ;;
    */reviews/9/comments)
      printf '[%s]' "$(comment 99 a.py 4 0 0 reviewer)"
      ;;
    # review 15 は複数行コメントと previous 側を混ぜる。Forgejo の UI は表示行
    # (範囲の末尾 = 行 + extra_lines_count) と side で会話を分けるので、同じ出力に
    # ならないと reply が UI 上で別スレッドに落ちる。
    #   31: a.py 20-24 の複数行コメント (表示行 24)
    #   32: a.py 20 の単一行コメント (表示行 20) → 31 とは別スレッド
    #   33: a.py 24 の単一行コメント (表示行 24) → 31 と同一スレッド
    #   34: c.py previous 側 7 行目
    #   35: c.py proposed 側 7 行目 → 34 とは別スレッド
    */reviews/15/comments)
      printf '[%s, %s, %s, %s, %s]' \
        "$(comment 31 a.py 20 0 4 reviewer)" \
        "$(comment 32 a.py 20 0 0 reviewer)" \
        "$(comment 33 a.py 24 0 0 agent)" \
        "$(comment 34 c.py 0 7 0 reviewer)" \
        "$(comment 35 c.py 7 0 0 reviewer)"
      ;;
    *) echo "unexpected path: $path" >&2; return 1 ;;
  esac
}

echo "=== スレッドの並び順 ==="
THREADS="$(fj_threads)" || ng "fj_threads が失敗した" ""
assert_eq "thread_id の昇順に並ぶ" "5 11 12 13 31 32 34 35" \
  "$(printf '%s' "$THREADS" | jq -r '[.[].thread_id] | join(" ")')"
assert_eq "review の取得順に引きずられない" 5 \
  "$(printf '%s' "$THREADS" | jq -r '.[0].thread_id')"
assert_eq "同一 review 内でも id の昇順になる" "11 12 13" \
  "$(printf '%s' "$THREADS" | jq -r '[.[] | select(.review_id == 7) | .thread_id] | join(" ")')"

echo "=== グルーピングと除外 ==="
assert_eq "PENDING のレビューを含めない" 0 \
  "$(printf '%s' "$THREADS" | jq '[.[] | select(.thread_id == 99)] | length')"
assert_eq "表示行が同じコメントだけが1スレッドにまとまる" 8 \
  "$(printf '%s' "$THREADS" | jq 'length')"
assert_eq "review ごとの stale を引き継ぐ" "true" \
  "$(printf '%s' "$THREADS" | jq -r '.[0].stale')"

echo "=== 複数行コメントと previous 側 ==="
T31="$(printf '%s' "$THREADS" | jq -c '.[] | select(.thread_id == 31)')"
assert_eq "複数行コメントの行は範囲の先頭になる" 20 "$(printf '%s' "$T31" | jq -r '.line')"
assert_eq "extra_lines_count を出力する" 4 "$(printf '%s' "$T31" | jq -r '.extra_lines_count')"
assert_eq "表示行 (行+extra) が同じ単一行コメントは同一スレッドに入る" "comment 31,comment 33" \
  "$(printf '%s' "$T31" | jq -r '[.comments[].body] | join(",")')"
assert_eq "同じ先頭行でも extra_lines_count が違えば別スレッドになる" 1 \
  "$(printf '%s' "$THREADS" | jq '[.[] | select(.thread_id == 32)] | length')"
T34="$(printf '%s' "$THREADS" | jq -c '.[] | select(.thread_id == 34)')"
assert_eq "previous 側は original_position を行として使う" 7 "$(printf '%s' "$T34" | jq -r '.line')"
assert_eq "previous 側の side が previous になる" previous "$(printf '%s' "$T34" | jq -r '.side')"
assert_eq "同じ行でも side が違えば別スレッドになる" proposed \
  "$(printf '%s' "$THREADS" | jq -r '.[] | select(.thread_id == 35) | .side')"

echo "=== スレッドが無い場合 ==="
fj_api() { printf '[]'; }
assert_eq "空配列を返す" "[]" "$(fj_threads | jq -c .)"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
