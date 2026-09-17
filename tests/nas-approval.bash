#!/usr/bin/env bash
# Test functions are invoked dynamically by name in main.
# shellcheck disable=SC2329
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly REPO_ROOT
WATCH=$REPO_ROOT/files/.local/bin/nas-approval-watch
readonly WATCH
WRAPPER=$REPO_ROOT/files/.local/bin/nas-acp-nvim
readonly WRAPPER
TEST_ROOT=$(mktemp -d)
readonly TEST_ROOT
trap 'rm -rf -- "$TEST_ROOT"' EXIT

fail() {
    echo "not ok - $*" >&2
    return 1
}

assert_eq() {
    local expected=$1
    local actual=$2
    local message=$3
    [[ $actual == "$expected" ]] ||
        fail "$message: expected [$expected], got [$actual]"
}

# Builds a directory holding fake nas and nvim executables, plus the files they
# record their invocations in. Callers put it at the front of PATH.
make_stubs() {
    local name=$1
    local watch_output=$2
    local dir=$TEST_ROOT/$name
    mkdir -p "$dir"

    cat >"$dir/nvim" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$dir/nvim-calls"
EOF

    cat >"$dir/nas" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$dir/nas-calls"
case \$2 in
    watch) cat "$watch_output" ;;
esac
EOF

    chmod +x "$dir/nvim" "$dir/nas"
    printf '%s\n' "$dir"
}

# The counts pushed to nvim, in order, as a space separated list.
pushed_counts() {
    local dir=$1
    local calls=()
    local line
    while IFS= read -r line; do
        [[ $line =~ ,\ ([0-9]+)\]\)$ ]] || continue
        calls+=("${BASH_REMATCH[1]}")
    done <"$dir/nvim-calls"
    printf '%s\n' "${calls[*]}"
}

added_event() {
    printf '{"event":"added","domain":"hostexec","entry":{"sessionId":"s1","requestId":"%s"}}\n' "$1"
}

removed_event() {
    printf '{"event":"removed","domain":"hostexec","sessionId":"s1","requestId":"%s"}\n' "$1"
}

# Runs the watcher against a prepared stream and returns the stub directory.
run_watcher() {
    local name=$1
    local stream=$2
    local dir
    dir=$(make_stubs "$name" "$stream")
    local session_file=$TEST_ROOT/$name.session-id
    printf 'sess_test\n' >"$session_file"
    PATH=$dir:$PATH \
        NAS_APPROVAL_NVIM_SERVER=/tmp/nvim.sock \
        NAS_APPROVAL_SESSION_TIMEOUT=2 \
        "$WATCH" hostexec "$session_file" 2>/dev/null
    printf '%s\n' "$dir"
}

test_watch_pushes_count_on_every_change() {
    local stream=$TEST_ROOT/stream-changes
    {
        added_event req_1
        added_event req_2
        removed_event req_1
    } >"$stream"

    local dir
    dir=$(run_watcher changes "$stream")

    assert_eq "1 2 1 0" "$(pushed_counts "$dir")" "counts pushed"
}

test_watch_ignores_duplicate_added() {
    local stream=$TEST_ROOT/stream-duplicate
    {
        added_event req_1
        added_event req_1
    } >"$stream"

    local dir
    dir=$(run_watcher duplicate "$stream")

    assert_eq "1 0" "$(pushed_counts "$dir")" "counts pushed"
}

test_watch_reports_the_session_id() {
    local stream=$TEST_ROOT/stream-reported-session
    added_event req_1 >"$stream"

    local dir
    dir=$(run_watcher reported-session "$stream")

    assert_eq "--remote-expr luaeval(\"require('config.nas_approval').set_pending(_A[1], _A[2], _A[3])\", ['hostexec', 'sess_test', 1])" \
        "$(sed -n '1s/^--server [^ ]* //p' "$dir/nvim-calls")" "pushed expression"
}

test_watch_refuses_an_unexpected_session_id() {
    local dir
    dir=$(make_stubs bad-session "/dev/null")
    local session_file=$TEST_ROOT/bad.session-id
    printf "sess'; bad\n" >"$session_file"
    local status=0
    PATH=$dir:$PATH \
        NAS_APPROVAL_NVIM_SERVER=/tmp/nvim.sock \
        NAS_APPROVAL_SESSION_TIMEOUT=1 \
        "$WATCH" hostexec "$session_file" 2>/dev/null ||
        status=$?

    assert_eq 1 "$status" "exit status"
    [[ ! -e $dir/nas-calls ]] || fail "nas should not have been invoked"
}

test_watch_subscribes_to_the_session() {
    local stream=$TEST_ROOT/stream-session
    : >"$stream"

    local dir
    dir=$(run_watcher session "$stream")

    assert_eq "hostexec watch --session sess_test" \
        "$(cat "$dir/nas-calls")" "nas invocation"
}

test_watch_gives_up_without_a_session_id() {
    local dir
    dir=$(make_stubs missing "/dev/null")
    local status=0
    PATH=$dir:$PATH \
        NAS_APPROVAL_NVIM_SERVER=/tmp/nvim.sock \
        NAS_APPROVAL_SESSION_TIMEOUT=1 \
        "$WATCH" hostexec "$TEST_ROOT/absent.session-id" 2>/dev/null ||
        status=$?

    assert_eq 1 "$status" "exit status"
    [[ ! -e $dir/nas-calls ]] || fail "nas should not have been invoked"
}

# Replaces nas with a stub that records its arguments and exits, so the wrapper
# returns instead of running a session.
make_wrapper_stubs() {
    local name=$1
    local dir=$TEST_ROOT/$name
    mkdir -p "$dir"
    cat >"$dir/nas" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >"$dir/nas-calls"
EOF
    cat >"$dir/nas-approval-watch" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$1" >>"$dir/watch-calls"
EOF
    # The wrapper resolves the watcher next to itself, so it is run from the
    # stub directory to pick up the stub.
    cp "$WRAPPER" "$dir/nas-acp-nvim"
    chmod +x "$dir/nas" "$dir/nas-approval-watch"
    printf '%s\n' "$dir"
}

run_wrapper() {
    local dir=$1
    shift
    XDG_RUNTIME_DIR=$dir/run PATH=$dir:$PATH "$@" "$dir/nas-acp-nvim" claude-acp
    # The watchers are started in the background; give them a moment to record.
    sleep 0.5
}

test_wrapper_passes_the_session_id_file_before_the_profile() {
    local dir
    dir=$(make_wrapper_stubs wrapper-args)

    run_wrapper "$dir" env NAS_APPROVAL_NVIM_SERVER=/tmp/nvim.sock

    local recorded
    recorded=$(cat "$dir/nas-calls")
    [[ $recorded == "--write-session-id $dir/run/nas-acp-nvim/"*".session-id claude-acp" ]] ||
        fail "unexpected nas invocation: $recorded"
}

test_wrapper_starts_a_watcher_per_domain() {
    local dir
    dir=$(make_wrapper_stubs wrapper-watchers)

    run_wrapper "$dir" env NAS_APPROVAL_NVIM_SERVER=/tmp/nvim.sock

    assert_eq "hostexec
network" "$(sort "$dir/watch-calls")" "watched domains"
}

test_wrapper_without_a_server_starts_no_watcher() {
    local dir
    dir=$(make_wrapper_stubs wrapper-bare)

    run_wrapper "$dir" env -u NAS_APPROVAL_NVIM_SERVER -u NVIM

    [[ -e $dir/nas-calls ]] || fail "nas should have been invoked"
    [[ ! -e $dir/watch-calls ]] || fail "no watcher should have been started"
}

run_test() {
    local name=$1
    echo "# $name"
    "$name"
    echo "ok - $name"
}

main() {
    local test_name
    for test_name in \
        test_watch_pushes_count_on_every_change \
        test_watch_ignores_duplicate_added \
        test_watch_subscribes_to_the_session \
        test_watch_reports_the_session_id \
        test_watch_refuses_an_unexpected_session_id \
        test_watch_gives_up_without_a_session_id \
        test_wrapper_passes_the_session_id_file_before_the_profile \
        test_wrapper_starts_a_watcher_per_domain \
        test_wrapper_without_a_server_starts_no_watcher; do
        run_test "$test_name"
    done
}

main "$@"
