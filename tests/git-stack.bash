#!/usr/bin/env bash
# Test functions are invoked dynamically by name in main.
# shellcheck disable=SC2329
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly REPO_ROOT
SCRIPT=$REPO_ROOT/files/.local/bin/git-stack
readonly SCRIPT
CHEAT=$REPO_ROOT/files/.local/share/navi/cheats/git.cheat
readonly CHEAT
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

assert_file_absent() {
    local path=$1
    [[ ! -e $path ]] || fail "expected path to be absent: $path"
}

git_path() {
    local repo=$1
    local name=$2
    local path
    path=$(git -C "$repo" rev-parse --git-path "$name")
    case $path in
        /*) printf '%s\n' "$path" ;;
        *) printf '%s\n' "$repo/$path" ;;
    esac
}

init_repo() {
    local name=$1
    local initial_branch=${2:-main}
    local repo=$TEST_ROOT/$name
    mkdir -p "$repo"
    git -C "$repo" init -q -b "$initial_branch"
    git -C "$repo" config user.name "Git Stack Test"
    git -C "$repo" config user.email "git-stack@example.invalid"
    git -C "$repo" config commit.gpgSign false
    git -C "$repo" config rebase.rebaseMerges false
    printf '%s\n' "$initial_branch" >"$repo/$initial_branch.txt"
    git -C "$repo" add "$initial_branch.txt"
    git -C "$repo" commit -q -m "$initial_branch"
    printf '%s\n' "$repo"
}

add_branch_commit() {
    local repo=$1
    local branch=$2
    git -C "$repo" switch -q -c "$branch"
    printf '%s\n' "$branch" >"$repo/$branch.txt"
    git -C "$repo" add "$branch.txt"
    git -C "$repo" commit -q -m "$branch"
}

make_stack() {
    local name=$1
    local base=${2:-main}
    local repo
    repo=$(init_repo "$name" "$base")
    add_branch_commit "$repo" A
    add_branch_commit "$repo" B
    add_branch_commit "$repo" C
    add_branch_commit "$repo" D
    printf '%s\n' "$repo"
}

make_remote_stack() {
    local name=$1
    local repo remote
    repo=$(make_stack "$name")
    remote=$TEST_ROOT/$name.git
    git init -q --bare "$remote"
    git -C "$repo" remote add origin "$remote"
    git -C "$repo" push -q --set-upstream origin main A B C D
    printf '%s\n' "$repo"
}

rewrite_b() {
    local repo=$1
    (cd "$repo" && "$SCRIPT" edit B)
    printf '%s\n' "B prime" >"$repo/B.txt"
    git -C "$repo" add B.txt
    git -C "$repo" commit -q --amend --no-edit
}

test_list_uses_main_default() {
    local repo actual
    repo=$(make_stack list-main)
    actual=$(cd "$repo" && "$SCRIPT" list)
    assert_eq $'A\nB\nC' "$actual" "main stack order"
}

test_list_uses_master_default() {
    local repo actual
    repo=$(make_stack list-master master)
    actual=$(cd "$repo" && "$SCRIPT" list)
    assert_eq $'A\nB\nC' "$actual" "master stack order"
}

test_list_selects_nearest_configured_base() {
    local repo actual
    repo=$(make_stack list-nearest)
    git -C "$repo" config --add stack.baseBranch main
    git -C "$repo" config --add stack.baseBranch B
    actual=$(cd "$repo" && "$SCRIPT" list)
    assert_eq "C" "$actual" "nearest configured base"
}

test_list_reports_missing_base() {
    local repo error_file
    repo=$(make_stack list-no-base trunk)
    error_file=$TEST_ROOT/list-no-base.error
    if (cd "$repo" && "$SCRIPT" list 2>"$error_file"); then
        fail "list without a base unexpectedly succeeded"
    fi
    grep -Fq "git config --add stack.baseBranch" "$error_file" ||
        fail "missing-base configuration hint missing"
}

test_edit_switches_and_records_state() {
    local repo state_dir old_b expected
    repo=$(make_stack edit-state)
    old_b=$(git -C "$repo" rev-parse B)

    (cd "$repo" && "$SCRIPT" edit B)

    assert_eq "B" "$(git -C "$repo" branch --show-current)" "edit checkout"
    state_dir=$(git -C "$repo" rev-parse --git-path stack-edit)
    assert_eq "B" "$(<"$repo/$state_dir/target-branch")" "stored target"
    assert_eq "$old_b" "$(<"$repo/$state_dir/old-target-oid")" "stored old target"
    assert_eq "D" "$(<"$repo/$state_dir/return-branch")" "stored return branch"
    assert_eq "edit" "$(<"$repo/$state_dir/phase")" "stored phase"

    expected=$(
        printf '%s\tA\n' "$(git -C "$repo" rev-parse A)"
        printf '%s\tB\n' "$(git -C "$repo" rev-parse B)"
        printf '%s\tC\n' "$(git -C "$repo" rev-parse C)"
        printf '%s\tD\n' "$(git -C "$repo" rev-parse D)"
    )
    assert_eq "$expected" "$(<"$repo/$state_dir/pre-oids")" "stored pre oids"
}

test_edit_rejects_dirty_worktree() {
    local repo error_file
    repo=$(make_stack edit-dirty)
    error_file=$TEST_ROOT/edit-dirty.error
    printf '%s\n' dirty >"$repo/untracked.txt"
    if (cd "$repo" && "$SCRIPT" edit B 2>"$error_file"); then
        fail "dirty edit unexpectedly succeeded"
    fi
    grep -Fq "worktree is not clean" "$error_file" ||
        fail "dirty edit diagnostic missing"
    assert_eq "D" "$(git -C "$repo" branch --show-current)" "dirty edit branch"
}

test_edit_rejects_detached_head() {
    local repo error_file
    repo=$(make_stack edit-detached)
    error_file=$TEST_ROOT/edit-detached.error
    git -C "$repo" switch -q --detach
    if (cd "$repo" && "$SCRIPT" edit B 2>"$error_file"); then
        fail "detached edit unexpectedly succeeded"
    fi
    grep -Fq "detached HEAD" "$error_file" ||
        fail "detached edit diagnostic missing"
}

test_edit_rejects_branch_outside_stack() {
    local repo error_file
    repo=$(make_stack edit-outside)
    error_file=$TEST_ROOT/edit-outside.error
    git -C "$repo" branch side main
    if (cd "$repo" && "$SCRIPT" edit side 2>"$error_file"); then
        fail "outside-stack edit unexpectedly succeeded"
    fi
    grep -Fq "is not editable from D" "$error_file" ||
        fail "outside-stack diagnostic missing"
}

test_edit_rejects_active_session() {
    local repo error_file
    repo=$(make_stack edit-active)
    error_file=$TEST_ROOT/edit-active.error
    (cd "$repo" && "$SCRIPT" edit B)
    if (cd "$repo" && "$SCRIPT" edit A 2>"$error_file"); then
        fail "nested edit unexpectedly succeeded"
    fi
    grep -Fq "another stack edit is already active" "$error_file" ||
        fail "active-session diagnostic missing"
}

test_edit_state_is_worktree_specific() {
    local repo linked linked_state main_state
    repo=$(make_stack edit-worktree)
    linked=$TEST_ROOT/edit-worktree-linked
    git -C "$repo" worktree add -q -b W "$linked" D

    (cd "$linked" && "$SCRIPT" edit B)

    linked_state=$(git -C "$linked" rev-parse --git-path stack-edit)
    main_state=$(git -C "$repo" rev-parse --git-path stack-edit)
    [[ -d $linked_state ]] || fail "linked-worktree state missing"
    assert_file_absent "$repo/$main_state"
}

test_done_rebases_descendants_and_updates_refs() {
    local repo old_b old_c old_d new_b state_dir
    repo=$(make_stack done-amend)
    old_b=$(git -C "$repo" rev-parse B)
    old_c=$(git -C "$repo" rev-parse C)
    old_d=$(git -C "$repo" rev-parse D)

    (cd "$repo" && "$SCRIPT" edit B)
    printf '%s\n' "B prime" >"$repo/B.txt"
    git -C "$repo" add B.txt
    git -C "$repo" commit -q --amend --no-edit
    new_b=$(git -C "$repo" rev-parse B)
    (cd "$repo" && "$SCRIPT" "done")

    assert_eq "D" "$(git -C "$repo" branch --show-current)" "done return branch"
    [[ $new_b != "$old_b" ]] || fail "B was not rewritten"
    [[ $(git -C "$repo" rev-parse C) != "$old_c" ]] || fail "C ref was not updated"
    [[ $(git -C "$repo" rev-parse D) != "$old_d" ]] || fail "D ref was not updated"
    git -C "$repo" merge-base --is-ancestor B C ||
        fail "C is not based on rewritten B"
    git -C "$repo" merge-base --is-ancestor C D ||
        fail "D is not based on rewritten C"
    assert_eq "4" "$(git -C "$repo" rev-list --count main..D)" "rebased commit count"
    state_dir=$(git -C "$repo" rev-parse --git-path stack-edit)
    assert_file_absent "$repo/$state_dir"
}

test_done_handles_commits_added_to_target() {
    local repo subjects
    repo=$(make_stack done-add)

    (cd "$repo" && "$SCRIPT" edit B)
    printf '%s\n' X >"$repo/X.txt"
    git -C "$repo" add X.txt
    git -C "$repo" commit -q -m X
    (cd "$repo" && "$SCRIPT" "done")

    subjects=$(git -C "$repo" log --reverse --format=%s main..D)
    assert_eq $'A\nB\nX\nC\nD' "$subjects" "added target commit order"
    assert_eq "1" "$(git -C "$repo" log --format=%s main..D | grep -c '^B$')" \
        "old B duplication count"
}

test_done_rejects_dirty_worktree() {
    local repo error_file
    repo=$(make_stack done-dirty)
    error_file=$TEST_ROOT/done-dirty.error
    (cd "$repo" && "$SCRIPT" edit B)
    printf '%s\n' dirty >"$repo/untracked.txt"

    if (cd "$repo" && "$SCRIPT" "done" 2>"$error_file"); then
        fail "dirty done unexpectedly succeeded"
    fi
    grep -Fq "worktree is not clean" "$error_file" ||
        fail "dirty done diagnostic missing"
    assert_eq "B" "$(git -C "$repo" branch --show-current)" "dirty done branch"
}

make_conflicting_stack() {
    local name=$1
    local repo
    repo=$(init_repo "$name")
    printf '%s\n' base >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q -m conflict-base
    add_branch_commit "$repo" A
    git -C "$repo" switch -q -c B
    printf '%s\n' B >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q -m B
    git -C "$repo" switch -q -c C
    printf '%s\n' C >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q -m C
    add_branch_commit "$repo" D
    printf '%s\n' "$repo"
}

make_twice_conflicting_stack() {
    local name=$1
    local repo
    repo=$(init_repo "$name")
    printf '%s\n' base >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q -m conflict-base
    add_branch_commit "$repo" A
    git -C "$repo" switch -q -c B
    printf '%s\n' B >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q -m B
    git -C "$repo" switch -q -c C
    printf '%s\n' C1 >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q -m C1
    printf '%s\n' C2 >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q -m C2
    add_branch_commit "$repo" D
    printf '%s\n' "$repo"
}

start_conflicting_rebase() {
    local repo=$1
    (cd "$repo" && "$SCRIPT" edit B)
    printf '%s\n' "B prime" >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q --amend --no-edit
    if (cd "$repo" && "$SCRIPT" "done"); then
        fail "conflicting rebase unexpectedly succeeded"
    fi
}

resolve_conflict() {
    local repo=$1
    printf '%s\n' resolved >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
}

test_done_continues_conflicted_rebase() {
    local repo state_dir
    repo=$(make_conflicting_stack conflict-continue)
    start_conflicting_rebase "$repo"
    resolve_conflict "$repo"

    (cd "$repo" && GIT_EDITOR=true "$SCRIPT" "done")

    assert_eq "D" "$(git -C "$repo" branch --show-current)" "continued return branch"
    assert_eq "resolved" "$(<"$repo/conflict.txt")" "continued resolution"
    state_dir=$(git -C "$repo" rev-parse --git-path stack-edit)
    assert_file_absent "$repo/$state_dir"
}

test_switch_cancels_edit_state() {
    local repo state_dir
    repo=$(make_stack stale-switch)
    (cd "$repo" && "$SCRIPT" edit B)
    git -C "$repo" switch -q D
    (cd "$repo" && "$SCRIPT" list >/dev/null)
    state_dir=$(git -C "$repo" rev-parse --git-path stack-edit)
    assert_file_absent "$repo/$state_dir"
}

test_rebase_abort_clears_state_on_next_command() {
    local repo state_dir
    repo=$(make_conflicting_stack stale-abort)
    start_conflicting_rebase "$repo"
    git -C "$repo" rebase --abort
    (cd "$repo" && "$SCRIPT" list >/dev/null)
    state_dir=$(git -C "$repo" rev-parse --git-path stack-edit)
    assert_file_absent "$repo/$state_dir"
    assert_eq "B prime" "$(git -C "$repo" show B:conflict.txt)" \
        "abort preserves edited B"
}

test_direct_rebase_continue_clears_state_on_next_command() {
    local repo state_dir
    repo=$(make_conflicting_stack stale-continue)
    start_conflicting_rebase "$repo"
    resolve_conflict "$repo"
    (cd "$repo" && GIT_EDITOR=true git rebase --continue)
    (cd "$repo" && "$SCRIPT" list >/dev/null)
    state_dir=$(git -C "$repo" rev-parse --git-path stack-edit)
    assert_file_absent "$repo/$state_dir"
}

test_rebase_marker_survives_repeated_conflicts() {
    local repo state_dir rebase_dir session_id
    repo=$(make_twice_conflicting_stack marker-repeat)

    (cd "$repo" && "$SCRIPT" edit B)
    printf '%s\n' "B prime" >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q --amend --no-edit
    if (cd "$repo" && "$SCRIPT" "done"); then
        fail "first conflicting rebase unexpectedly succeeded"
    fi

    state_dir=$(git_path "$repo" stack-edit)
    rebase_dir=$(git_path "$repo" rebase-merge)
    [[ -f $state_dir/session-id ]] || fail "stack session ID missing"
    [[ -f $rebase_dir/git-stack-session ]] || fail "rebase marker missing"
    session_id=$(<"$state_dir/session-id")
    assert_eq "$session_id" "$(<"$rebase_dir/git-stack-session")" \
        "initial rebase marker"

    printf '%s\n' resolved-one >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    if (cd "$repo" && GIT_EDITOR=true "$SCRIPT" "done"); then
        fail "second conflicting rebase unexpectedly succeeded"
    fi
    assert_eq "$session_id" "$(<"$rebase_dir/git-stack-session")" \
        "marker after rebase continue"

    printf '%s\n' resolved-two >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    (cd "$repo" && GIT_EDITOR=true "$SCRIPT" "done")
    assert_file_absent "$state_dir"
}

test_done_refuses_unrelated_rebase() {
    local repo state_dir rebase_dir error_file msgnum_before
    repo=$(make_conflicting_stack marker-unrelated)
    error_file=$TEST_ROOT/marker-unrelated.error
    start_conflicting_rebase "$repo"
    state_dir=$(git_path "$repo" stack-edit)
    rebase_dir=$(git_path "$repo" rebase-merge)
    [[ -f $rebase_dir/git-stack-session ]] || fail "stack rebase marker missing"

    git -C "$repo" rebase --abort
    if (cd "$repo" && git rebase --force-rebase --exec false main >/dev/null 2>&1); then
        fail "unrelated rebase unexpectedly succeeded"
    fi
    msgnum_before=$(<"$rebase_dir/msgnum")

    if (cd "$repo" && "$SCRIPT" "done" 2>"$error_file"); then
        fail "stack done continued an unrelated rebase"
    fi
    grep -Fq "active rebase does not belong to this stack edit" "$error_file" ||
        fail "unrelated-rebase diagnostic missing"
    assert_eq "$msgnum_before" "$(<"$rebase_dir/msgnum")" \
        "unrelated rebase progress"
    [[ -d $rebase_dir ]] || fail "unrelated rebase was removed"
    assert_file_absent "$state_dir"
    git -C "$repo" rebase --abort
}

make_merged_stack() {
    local name=$1
    local repo
    repo=$(init_repo "$name")
    add_branch_commit "$repo" A
    add_branch_commit "$repo" B
    git -C "$repo" switch -q -c C
    printf '%s\n' C >"$repo/C.txt"
    git -C "$repo" add C.txt
    git -C "$repo" commit -q -m C
    git -C "$repo" switch -q -c side B
    printf '%s\n' side >"$repo/side.txt"
    git -C "$repo" add side.txt
    git -C "$repo" commit -q -m side
    git -C "$repo" switch -q C
    git -C "$repo" merge -q --no-ff side -m merge-side
    add_branch_commit "$repo" D
    printf '%s\n' "$repo"
}

test_done_preserves_merge_topology() {
    local repo
    repo=$(make_merged_stack rebase-merges)

    (cd "$repo" && "$SCRIPT" edit B)
    printf '%s\n' "B prime" >"$repo/B.txt"
    git -C "$repo" add B.txt
    git -C "$repo" commit -q --amend --no-edit
    (cd "$repo" && "$SCRIPT" "done")

    assert_eq "1" \
        "$(git -C "$repo" rev-list --count --min-parents=2 B..D)" \
        "preserved merge count"
    git -C "$repo" merge-base --is-ancestor side C ||
        fail "rewritten side branch is not merged into C"
}

test_cli_help_and_bad_arguments() {
    local repo output error_file
    repo=$(make_stack cli)
    error_file=$TEST_ROOT/cli.error
    output=$("$SCRIPT" --help)
    grep -Fq "git stack edit <local-branch>" <<<"$output" ||
        fail "help omits edit"
    grep -Fq "git stack done" <<<"$output" ||
        fail "help omits done"
    grep -Fq "git stack list" <<<"$output" ||
        fail "help omits list"
    grep -Fq "git stack push-all" <<<"$output" ||
        fail "help omits push-all"

    if (cd "$repo" && "$SCRIPT" "done" extra 2>"$error_file"); then
        fail "done with an argument unexpectedly succeeded"
    fi
    grep -Fq "usage: git stack done" "$error_file" ||
        fail "done usage diagnostic missing"

    if (cd "$repo" && "$SCRIPT" push-all extra 2>"$error_file"); then
        fail "push-all with an argument unexpectedly succeeded"
    fi
    grep -Fq "usage: git stack push-all" "$error_file" ||
        fail "push-all usage diagnostic missing"

    if (cd "$repo" && "$SCRIPT" unknown 2>"$error_file"); then
        fail "unknown subcommand unexpectedly succeeded"
    fi
    grep -Fq "unknown subcommand: unknown" "$error_file" ||
        fail "unknown subcommand diagnostic missing"

    if (cd "$repo" && "$SCRIPT" "done" 2>"$error_file"); then
        fail "done without a session unexpectedly succeeded"
    fi
    grep -Fq "no stack edit is active" "$error_file" ||
        fail "missing-session diagnostic missing"
}

test_navi_completion_delegates_to_stack_list() {
    grep -Fqx 'git stack edit <stack-branch>' "$CHEAT" ||
        fail "navi edit entry missing"
    grep -Fqx 'git stack done' "$CHEAT" ||
        fail "navi done entry missing"
    grep -Fqx 'git stack push-all' "$CHEAT" ||
        fail "navi push-all entry missing"
    grep -Eq '^\$ stack-branch: +git stack list$' "$CHEAT" ||
        fail "navi stack-branch completion missing"
}

test_done_prompts_only_moved_branches() {
    local repo output
    repo=$(make_remote_stack push-moved)
    rewrite_b "$repo"

    output=$(cd "$repo" && printf 'n\nn\nn\n' | "$SCRIPT" "done" 2>&1)

    grep -Fq "Push B to origin/B?" <<<"$output" || fail "B prompt missing"
    grep -Fq "Push C to origin/C?" <<<"$output" || fail "C prompt missing"
    grep -Fq "Push D to origin/D?" <<<"$output" || fail "D prompt missing"
    if grep -Fq "Push A " <<<"$output"; then
        fail "unmoved branch A was offered"
    fi
}

test_done_declines_leave_remote_untouched() {
    local repo remote before
    repo=$(make_remote_stack push-decline)
    remote=$TEST_ROOT/push-decline.git
    before=$(git -C "$remote" rev-parse B)
    rewrite_b "$repo"

    (cd "$repo" && printf 'n\nn\nn\n' | "$SCRIPT" "done" >/dev/null 2>&1)

    assert_eq "$before" "$(git -C "$remote" rev-parse B)" "declined remote B"
}

test_done_pushes_accepted_branches() {
    local repo remote branch
    repo=$(make_remote_stack push-accept)
    remote=$TEST_ROOT/push-accept.git
    rewrite_b "$repo"

    (cd "$repo" && printf 'y\ny\ny\n' | "$SCRIPT" "done" >/dev/null 2>&1)

    for branch in B C D; do
        assert_eq \
            "$(git -C "$repo" rev-parse "$branch")" \
            "$(git -C "$remote" rev-parse "$branch")" \
            "pushed $branch"
    done
    assert_eq \
        "$(git -C "$repo" rev-parse A)" \
        "$(git -C "$remote" rev-parse A)" \
        "untouched A"
}

test_done_without_input_skips_pushes() {
    local repo remote before error_file
    repo=$(make_remote_stack push-eof)
    remote=$TEST_ROOT/push-eof.git
    before=$(git -C "$remote" rev-parse B)
    error_file=$TEST_ROOT/push-eof.error
    rewrite_b "$repo"

    (cd "$repo" && "$SCRIPT" "done" </dev/null 2>"$error_file") ||
        fail "done with no input exited nonzero"

    grep -Fq "no input; skipping remaining pushes" "$error_file" ||
        fail "no-input diagnostic missing"
    assert_eq "$before" "$(git -C "$remote" rev-parse B)" "remote B after no input"
}

make_untracked_remote_stack() {
    local name=$1
    local repo remote
    repo=$(make_stack "$name")
    remote=$TEST_ROOT/$name.git
    git init -q --bare "$remote"
    git -C "$repo" remote add origin "$remote"
    git -C "$repo" push -q origin main
    printf '%s\n' "$repo"
}

test_done_sets_upstream_for_untracked_branches() {
    local repo remote output
    repo=$(make_untracked_remote_stack push-upstream)
    remote=$TEST_ROOT/push-upstream.git
    rewrite_b "$repo"

    output=$(cd "$repo" && printf 'y\nn\nn\n' | "$SCRIPT" "done" 2>&1)

    grep -Fq "Push B to origin/B and set upstream?" <<<"$output" ||
        fail "set-upstream prompt missing"
    assert_eq "refs/heads/B" \
        "$(git -C "$repo" config --get branch.B.merge)" "B upstream merge ref"
    assert_eq "origin" \
        "$(git -C "$repo" config --get branch.B.remote)" "B upstream remote"
    assert_eq \
        "$(git -C "$repo" rev-parse B)" \
        "$(git -C "$remote" rev-parse B)" \
        "pushed untracked B"
}

test_done_without_remote_prompts_nothing() {
    local repo output
    repo=$(make_stack push-no-remote)
    rewrite_b "$repo"

    output=$(cd "$repo" && "$SCRIPT" "done" </dev/null 2>&1)

    if grep -Fq "Push " <<<"$output"; then
        fail "prompted without a remote"
    fi
}

test_done_reports_push_failures() {
    local repo error_file
    repo=$(make_remote_stack push-failure)
    error_file=$TEST_ROOT/push-failure.error
    rewrite_b "$repo"
    git -C "$repo" remote set-url origin "$TEST_ROOT/push-failure-missing.git"

    if (cd "$repo" && printf 'y\ny\ny\n' | "$SCRIPT" "done" 2>"$error_file"); then
        fail "done succeeded despite failed pushes"
    fi

    grep -Fq "push failed: B" "$error_file" || fail "B failure diagnostic missing"
    grep -Fq "push failed: D" "$error_file" ||
        fail "prompting stopped at the first failure"
    assert_eq "D" "$(git -C "$repo" branch --show-current)" "branch after failures"
}

make_conflicting_remote_stack() {
    local name=$1
    local repo remote
    repo=$(make_conflicting_stack "$name")
    remote=$TEST_ROOT/$name.git
    git init -q --bare "$remote"
    git -C "$repo" remote add origin "$remote"
    git -C "$repo" push -q --set-upstream origin main A B C D
    printf '%s\n' "$repo"
}

test_done_prompts_after_conflict_resolution() {
    local repo remote output
    repo=$(make_conflicting_remote_stack push-conflict)
    remote=$TEST_ROOT/push-conflict.git

    (cd "$repo" && "$SCRIPT" edit B)
    printf '%s\n' rewritten >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    git -C "$repo" commit -q --amend --no-edit
    if (cd "$repo" && "$SCRIPT" "done" </dev/null >/dev/null 2>&1); then
        fail "conflicting rebase unexpectedly succeeded"
    fi

    printf '%s\n' resolved >"$repo/conflict.txt"
    git -C "$repo" add conflict.txt
    output=$(cd "$repo" && printf 'y\ny\ny\n' |
        GIT_EDITOR=true "$SCRIPT" "done" 2>&1)

    grep -Fq "Push B to origin/B?" <<<"$output" ||
        fail "continuation B prompt missing"
    assert_eq \
        "$(git -C "$repo" rev-parse D)" \
        "$(git -C "$remote" rev-parse D)" \
        "pushed D after conflict"
}

prompt_order() {
    local output=$1
    grep -o 'Push [^ ]* to' <<<"$output" | awk '{print $2}'
}

test_push_all_prompts_every_stack_branch() {
    local repo output
    repo=$(make_remote_stack push-all-order)

    output=$(cd "$repo" && printf 'n\nn\nn\nn\n' | "$SCRIPT" push-all 2>&1)

    assert_eq $'A\nB\nC\nD' "$(prompt_order "$output")" \
        "push-all prompt order"
    if grep -Fq "Push main " <<<"$output"; then
        fail "base branch main was offered"
    fi
}

test_push_all_pushes_accepted_branches_only() {
    local repo remote before branch
    repo=$(make_remote_stack push-all-accept)
    remote=$TEST_ROOT/push-all-accept.git
    rewrite_b "$repo"
    (cd "$repo" && "$SCRIPT" "done" </dev/null >/dev/null 2>&1)
    before=$(git -C "$remote" rev-parse B)

    (cd "$repo" && printf 'n\nn\ny\ny\n' | "$SCRIPT" push-all >/dev/null 2>&1)

    assert_eq "$before" "$(git -C "$remote" rev-parse B)" "declined remote B"
    for branch in C D; do
        assert_eq \
            "$(git -C "$repo" rev-parse "$branch")" \
            "$(git -C "$remote" rev-parse "$branch")" \
            "pushed $branch"
    done
    assert_eq \
        "$(git -C "$repo" rev-parse A)" \
        "$(git -C "$remote" rev-parse A)" \
        "untouched A"
}

test_push_all_sets_upstream_for_untracked_branches() {
    local repo remote output
    repo=$(make_untracked_remote_stack push-all-upstream)
    remote=$TEST_ROOT/push-all-upstream.git

    output=$(cd "$repo" && printf 'n\ny\nn\nn\n' | "$SCRIPT" push-all 2>&1)

    grep -Fq "Push B to origin/B and set upstream?" <<<"$output" ||
        fail "set-upstream prompt missing"
    assert_eq "refs/heads/B" \
        "$(git -C "$repo" config --get branch.B.merge)" "B upstream merge ref"
    assert_eq "origin" \
        "$(git -C "$repo" config --get branch.B.remote)" "B upstream remote"
    assert_eq \
        "$(git -C "$repo" rev-parse B)" \
        "$(git -C "$remote" rev-parse B)" \
        "pushed untracked B"
}

test_push_all_without_remote_prompts_nothing() {
    local repo output
    repo=$(make_stack push-all-no-remote)

    output=$(cd "$repo" && "$SCRIPT" push-all </dev/null 2>&1) ||
        fail "push-all without a remote exited nonzero"

    if grep -Fq "Push " <<<"$output"; then
        fail "prompted without a remote"
    fi
}

test_push_all_without_input_skips_pushes() {
    local repo remote before error_file
    repo=$(make_remote_stack push-all-eof)
    remote=$TEST_ROOT/push-all-eof.git
    git -C "$repo" commit -q --allow-empty -m "D extra"
    before=$(git -C "$remote" rev-parse D)
    error_file=$TEST_ROOT/push-all-eof.error

    (cd "$repo" && "$SCRIPT" push-all </dev/null 2>"$error_file") ||
        fail "push-all with no input exited nonzero"

    grep -Fq "no input; skipping remaining pushes" "$error_file" ||
        fail "no-input diagnostic missing"
    assert_eq "$before" "$(git -C "$remote" rev-parse D)" \
        "remote D after no input"
}

test_push_all_reports_push_failures() {
    local repo error_file
    repo=$(make_remote_stack push-all-failure)
    error_file=$TEST_ROOT/push-all-failure.error
    git -C "$repo" remote set-url origin "$TEST_ROOT/push-all-missing.git"

    if (cd "$repo" && printf 'y\ny\ny\ny\n' |
        "$SCRIPT" push-all 2>"$error_file"); then
        fail "push-all succeeded despite failed pushes"
    fi

    grep -Fq "push failed: A" "$error_file" || fail "A failure diagnostic missing"
    grep -Fq "push failed: D" "$error_file" ||
        fail "prompting stopped at the first failure"
}

test_push_all_rejects_active_edit_session() {
    local repo state_dir error_file
    repo=$(make_remote_stack push-all-editing)
    error_file=$TEST_ROOT/push-all-editing.error
    state_dir=$(git_path "$repo" stack-edit)
    (cd "$repo" && "$SCRIPT" edit B)

    if (cd "$repo" && "$SCRIPT" push-all </dev/null 2>"$error_file"); then
        fail "push-all during an edit session unexpectedly succeeded"
    fi
    grep -Fq "a stack edit is active" "$error_file" ||
        fail "active-session diagnostic missing"
    [[ -d $state_dir ]] || fail "push-all removed the edit state"
    assert_eq "B" "$(<"$state_dir/target-branch")" "target branch after push-all"
}

test_push_all_rejects_active_rebase_session() {
    local repo state_dir rebase_dir error_file
    repo=$(make_conflicting_stack push-all-rebasing)
    error_file=$TEST_ROOT/push-all-rebasing.error
    state_dir=$(git_path "$repo" stack-edit)
    rebase_dir=$(git_path "$repo" rebase-merge)
    start_conflicting_rebase "$repo"

    if (cd "$repo" && "$SCRIPT" push-all </dev/null 2>"$error_file"); then
        fail "push-all during a stack rebase unexpectedly succeeded"
    fi
    grep -Fq "a stack edit is active" "$error_file" ||
        fail "active-session diagnostic missing"
    [[ -d $state_dir ]] || fail "push-all removed the edit state"
    [[ -f $rebase_dir/git-stack-session ]] ||
        fail "push-all removed the rebase marker"
    git -C "$repo" rebase --abort
}

test_push_all_rejects_detached_head() {
    local repo error_file
    repo=$(make_remote_stack push-all-detached)
    error_file=$TEST_ROOT/push-all-detached.error
    git -C "$repo" switch -q --detach HEAD

    if (cd "$repo" && "$SCRIPT" push-all </dev/null 2>"$error_file"); then
        fail "push-all on a detached HEAD unexpectedly succeeded"
    fi
    grep -Fq "detached HEAD is not a stack branch" "$error_file" ||
        fail "detached HEAD diagnostic missing"
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
        test_list_uses_main_default \
        test_list_uses_master_default \
        test_list_selects_nearest_configured_base \
        test_list_reports_missing_base \
        test_edit_switches_and_records_state \
        test_edit_rejects_dirty_worktree \
        test_edit_rejects_detached_head \
        test_edit_rejects_branch_outside_stack \
        test_edit_rejects_active_session \
        test_edit_state_is_worktree_specific \
        test_done_rebases_descendants_and_updates_refs \
        test_done_handles_commits_added_to_target \
        test_done_prompts_only_moved_branches \
        test_done_declines_leave_remote_untouched \
        test_done_pushes_accepted_branches \
        test_done_without_input_skips_pushes \
        test_done_sets_upstream_for_untracked_branches \
        test_done_without_remote_prompts_nothing \
        test_done_reports_push_failures \
        test_done_prompts_after_conflict_resolution \
        test_done_rejects_dirty_worktree \
        test_done_continues_conflicted_rebase \
        test_switch_cancels_edit_state \
        test_rebase_abort_clears_state_on_next_command \
        test_direct_rebase_continue_clears_state_on_next_command \
        test_rebase_marker_survives_repeated_conflicts \
        test_done_refuses_unrelated_rebase \
        test_done_preserves_merge_topology \
        test_cli_help_and_bad_arguments \
        test_navi_completion_delegates_to_stack_list \
        test_push_all_prompts_every_stack_branch \
        test_push_all_pushes_accepted_branches_only \
        test_push_all_sets_upstream_for_untracked_branches \
        test_push_all_without_remote_prompts_nothing \
        test_push_all_without_input_skips_pushes \
        test_push_all_reports_push_failures \
        test_push_all_rejects_active_edit_session \
        test_push_all_rejects_active_rebase_session \
        test_push_all_rejects_detached_head; do
        run_test "$test_name"
    done
}

main "$@"
