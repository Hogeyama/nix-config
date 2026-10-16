#!/usr/bin/env bash
# git-split の e2e テスト。一時リポジトリを作って bin/git-split を実際に叩き、
# index / tree の状態を検証する。
#
# 使い方: ./test_git_split.sh          (全ケース実行)
#         ./test_git_split.sh <name>   (名前が部分一致するケースだけ実行)
#
# ファイルモードは index の実値 (git ls-files -s の第1列) で検証する。
# splitstage は index へ blob を直接書き込む経路を持ち、その経路がモードを
# 取り違えると実行ビットが黙って落ちるため、モードは内容と同格で検証する。

set -u

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
GS="$ROOT/bin/git-split"
FILTER="${1:-}"

pass_count=0
fail_count=0

fail() {
    printf '  FAIL: %s\n' "$1"
    fail_count=$((fail_count + 1))
}

# 一時リポジトリを作って cd する。$REPO に絶対パスが入る。
new_repo() {
    REPO="$(mktemp -d "${TMPDIR:-/tmp}/git-split-test.XXXXXX")"
    cd "$REPO" || exit 1
    git init -q .
    git config user.email test@example.com
    git config user.name tester
    git config commit.gpgsign false
}

# index 上の <path> のモードが <want> であることを検証する。
assert_index_mode() {
    local path="$1" want="$2" got
    got="$(git ls-files -s -- "$path" | awk '{print $1}')"
    if [ "$got" != "$want" ]; then
        fail "index mode of $path: want $want, got ${got:-<absent>}"
    fi
}

# HEAD の tree 上の <path> のモードが <want> であることを検証する。
assert_head_mode() {
    local path="$1" want="$2" got
    got="$(git ls-tree HEAD -- "$path" | awk '{print $1}')"
    if [ "$got" != "$want" ]; then
        fail "HEAD mode of $path: want $want, got ${got:-<absent>}"
    fi
}

assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) fail "expected output to contain '$2'; got: $1" ;;
    esac
}

# start が失敗し、その出力に <path> が含まれることを検証する。
assert_start_rejects() {
    local out
    out="$("$GS" start 2>&1)"
    case "$out" in
        *'"ok": true'*) fail "start accepted a change it cannot stage later" ;;
    esac
    assert_contains "$out" "$1"
}

assert_json_true() {
    # $1: JSON, $2: キー名
    local got
    got="$(printf '%s' "$1" | python3 -c \
        'import json,sys;print(json.load(sys.stdin).get(sys.argv[1]))' "$2" 2>&1)"
    if [ "$got" != "True" ]; then
        fail "expected JSON key $2 to be true; got $got"
    fi
}

# show の JSON から remaining_ids の n 番目を取り出す。
nth_remaining_id() {
    "$GS" show --file "$1" | python3 -c \
        'import json,sys;print(json.load(sys.stdin)["remaining_ids"][int(sys.argv[1])])' "$2"
}

first_hunk_id() {
    "$GS" show --file "$1" | python3 -c \
        'import json,sys;print(json.load(sys.stdin)["hunks"][0]["id"])'
}

# ------------------------------------------------------------------ cases

# 実行可能ファイル (モード変更なし・内容変更あり) を用意する。
setup_exec_file() {
    printf 'line1\nline2\nline3\n' > run.sh
    chmod +x run.sh
    git add -A
    git commit -qm init
    printf 'line1\nline2 changed\nline3\nline4\n' > run.sh
}

case_line_id_add_keeps_exec_bit() {
    setup_exec_file
    "$GS" start > /dev/null
    "$GS" add "$(nth_remaining_id run.sh 0)" > /dev/null
    assert_index_mode run.sh 100755
}

case_hunk_id_add_keeps_exec_bit() {
    setup_exec_file
    "$GS" start > /dev/null
    "$GS" add "$(first_hunk_id run.sh)" > /dev/null
    assert_index_mode run.sh 100755
}

case_set_keeps_exec_bit() {
    setup_exec_file
    "$GS" start > /dev/null
    # 中間内容はリポジトリ外の一時ファイルで渡す (worktree を触ると verify が
    # worktree 違反として弾くため)
    local intermediate
    intermediate="$(mktemp "${TMPDIR:-/tmp}/git-split-test-content.XXXXXX")"
    printf 'line1\nline2 changed\nline3\n' > "$intermediate"
    "$GS" set run.sh --from "$intermediate" > /dev/null
    rm -f "$intermediate"
    assert_index_mode run.sh 100755
}

case_full_split_of_exec_file_completes() {
    setup_exec_file
    "$GS" start > /dev/null
    "$GS" add "$(nth_remaining_id run.sh 0)" > /dev/null
    "$GS" commit -m part1 > /dev/null
    assert_head_mode run.sh 100755
    "$GS" add --remaining > /dev/null
    out="$("$GS" commit -m part2)"
    assert_json_true "$out" complete
    assert_head_mode run.sh 100755
    if [ -n "$(git status --porcelain)" ]; then
        fail "worktree is dirty after a complete split: $(git status --porcelain)"
    fi
}

# 行 ID を持たない変更 (以下の4種) は stage する手段が無く、放置すると分割
# 完了時の tree 不一致としてしか現れない。start で拒否することを確認する。

case_mode_only_change_is_rejected_at_start() {
    printf 'x\n' > a.sh
    git add -A
    git commit -qm init
    chmod +x a.sh                      # モード変更のみ (内容変更なし)
    assert_start_rejects a.sh
}

case_binary_change_is_rejected_at_start() {
    printf '\x00\x01binary\n' > data.bin
    git add -A
    git commit -qm init
    printf '\x00\x01changed\n' > data.bin
    assert_start_rejects data.bin
}

case_empty_file_creation_is_rejected_at_start() {
    printf 'seed\n' > seed.txt
    git add -A
    git commit -qm init
    : > empty.txt
    assert_start_rejects empty.txt
}

case_empty_file_deletion_is_rejected_at_start() {
    : > empty.txt
    printf 'seed\n' > seed.txt
    git add -A
    git commit -qm init
    rm empty.txt
    assert_start_rejects empty.txt
}

# start は untracked ファイルを diff に載せるため `git add -N` する。拒否で
# 抜けたときにその登録が残ると、原因を取り除いても start が通らなくなる。

setup_rejected_start_with_untracked() {
    printf 'seed\n' > seed.txt
    git add -A
    git commit -qm init
    printf 'seed2\n' > seed.txt
    : > empty.txt                      # 拒否される untracked ファイル
    printf 'new\n' > other_new.txt     # 無関係な untracked ファイル
    assert_start_rejects empty.txt
}

case_rejected_start_leaves_index_untouched() {
    setup_rejected_start_with_untracked
    local tracked
    tracked="$(git ls-files)"
    if [ "$tracked" != "seed.txt" ]; then
        fail "rejected start left index entries: $(printf '%s' "$tracked" | tr '\n' ' ')"
    fi
}

case_start_succeeds_after_removing_the_rejected_change() {
    setup_rejected_start_with_untracked
    rm empty.txt
    assert_json_true "$("$GS" start)" ok
}

case_mode_change_with_content_change_completes() {
    printf 'line1\nline2\n' > tool.sh
    git add -A
    git commit -qm init
    chmod +x tool.sh                   # モード変更 + 内容変更
    printf 'line1\nline2 changed\n' > tool.sh
    "$GS" start > /dev/null
    "$GS" add --remaining > /dev/null
    out="$("$GS" commit -m all)"
    assert_json_true "$out" complete
    assert_head_mode tool.sh 100755
}

CASES="
case_line_id_add_keeps_exec_bit
case_hunk_id_add_keeps_exec_bit
case_set_keeps_exec_bit
case_full_split_of_exec_file_completes
case_mode_only_change_is_rejected_at_start
case_binary_change_is_rejected_at_start
case_empty_file_creation_is_rejected_at_start
case_empty_file_deletion_is_rejected_at_start
case_rejected_start_leaves_index_untouched
case_start_succeeds_after_removing_the_rejected_change
case_mode_change_with_content_change_completes
"

# ------------------------------------------------------------------ runner

for name in $CASES; do
    if [ -n "$FILTER" ]; then
        case "$name" in
            *"$FILTER"*) ;;
            *) continue ;;
        esac
    fi
    before=$fail_count
    printf '%s\n' "$name"
    new_repo
    "$name"
    cd / || exit 1
    rm -rf "$REPO"
    if [ "$fail_count" -eq "$before" ]; then
        pass_count=$((pass_count + 1))
        printf '  ok\n'
    fi
done

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]
