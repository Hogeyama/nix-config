# `git stack` Rebase Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure `git stack done` continues only the rebase it started and preserve merge topology while replaying descendant branches.

**Architecture:** Each stack edit receives a session ID stored in `stack-edit/session-id`. When the initial rebase stops, the same ID is written into Git's active `rebase-merge` directory; continuation is allowed only when both values match. The descendant replay uses Git's merge backend through `--rebase-merges`.

**Tech Stack:** Bash, Git 2.43-compatible rebase metadata, the existing Bash integration harness, shellcheck, and Nix flake evaluation.

## Global Constraints

- Do not change the accepted decisions for checked-out refs in other worktrees, nonlinear base distance, or untracked-file handling.
- Never continue a rebase without a matching `git-stack-session` marker.
- Preserve native `git rebase --abort` and direct `git rebase --continue`.
- Use `git rebase --rebase-merges --onto <target> <old-target-oid> --update-refs`.
- Keep state scoped to the path returned by `git rev-parse --git-path stack-edit`.

---

### Task 1: Bind continuation to the stack rebase session

**Files:**
- Modify: `files/.local/bin/git-stack`
- Modify: `tests/git-stack.bash`

**Interfaces:**
- Produces state file: `stack-edit/session-id`, containing a Git object-format hash.
- Produces rebase marker: `rebase-merge/git-stack-session`, containing the same hash.
- Produces helpers: `new_session_id`, `rebase_merge_dir`, `mark_rebase_session`, and `rebase_belongs_to_session`.
- Changes `refresh_state <subcommand>` so a mismatched active rebase is never continued.

- [ ] **Step 1: Add failing session-ownership tests**

Add a path helper after `assert_file_absent` in `tests/git-stack.bash`:

```bash
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
```

Add a fixture that creates two consecutive conflicts:

```bash
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
```

Add the two tests before `run_test`:

```bash
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
    if (cd "$repo" && git rebase --force-rebase --exec false main); then
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
```

Append both test names to the `for test_name in` list:

```bash
        test_rebase_marker_survives_repeated_conflicts \
        test_done_refuses_unrelated_rebase
```

- [ ] **Step 2: Run the suite and verify the marker test fails**

Run:

```bash
bash tests/git-stack.bash
```

Expected: existing tests PASS; `test_rebase_marker_survives_repeated_conflicts`
FAILS with `stack session ID missing`.

- [ ] **Step 3: Add session state and rebase ownership helpers**

Add `session_id=` with the other state globals in
`files/.local/bin/git-stack`, and include `session-id` in both the explicit
file removal list in `clear_state` and the required file list in `load_state`.
Load it with:

```bash
session_id=$(<"$state_dir/session-id")
```

Add these helpers after `rebase_in_progress`:

```bash
new_session_id() {
    local target=$1
    local old_oid=$2
    local return=$3
    printf '%s\0%s\0%s\0%s\0%s\n' \
        "$target" "$old_oid" "$return" "$$" "$RANDOM" |
        git hash-object --stdin
}

rebase_merge_dir() {
    git rev-parse --git-path rebase-merge
}

mark_rebase_session() {
    local directory
    directory=$(rebase_merge_dir)
    [[ -d $directory ]] || return 1
    printf '%s\n' "$session_id" >"$directory/git-stack-session"
}

rebase_belongs_to_session() {
    local directory marker
    directory=$(rebase_merge_dir)
    marker=$directory/git-stack-session
    [[ -f $marker ]] && [[ $(<"$marker") == "$session_id" ]]
}
```

Change `write_edit_state` to accept and write a fourth argument:

```bash
write_edit_state() {
    local target=$1
    local old_target_oid=$2
    local return_branch=$3
    local new_session=$4

    mkdir "$state_dir"
    printf '%s\n' "$target" >"$state_dir/target-branch"
    printf '%s\n' "$old_target_oid" >"$state_dir/old-target-oid"
    printf '%s\n' "$return_branch" >"$state_dir/return-branch"
    printf '%s\n' "$new_session" >"$state_dir/session-id"
    printf '%s\n' edit >"$state_dir/phase"
}
```

In `command_edit`, create and pass the session:

```bash
session_id=$(new_session_id "$target" "$old_target_oid" "$current")
write_edit_state "$target" "$old_target_oid" "$current" "$session_id"
```

- [ ] **Step 4: Enforce marker ownership during refresh and continuation**

Change `refresh_state` to accept the requested subcommand and replace its
`rebase)` arm:

```bash
refresh_state() {
    local subcommand=$1
    local current=
    [[ -d $state_dir ]] || return 0
    load_state

    case $phase in
        edit)
            current=$(current_branch || :)
            if [[ $current != "$target_branch" ]]; then
                clear_state
            fi
            ;;
        rebase)
            if ! rebase_in_progress; then
                clear_state
            elif ! rebase_belongs_to_session; then
                clear_state
                if [[ $subcommand == done ]]; then
                    die "active rebase does not belong to this stack edit"
                fi
            fi
            ;;
    esac
}
```

Pass `edit`, `list`, or `done` from the corresponding `main` case:

```bash
refresh_state edit
refresh_state list
refresh_state done
```

In the rebase-phase branch of `command_done`, require both checks:

```bash
rebase_in_progress && rebase_belongs_to_session ||
    die "active rebase does not belong to this stack edit"
```

After the initial rebase returns nonzero, replace the final cleanup with:

```bash
if rebase_in_progress; then
    mark_rebase_session ||
        die "could not mark the active rebase as a stack session"
else
    clear_state
fi
return 1
```

- [ ] **Step 5: Run session tests and static analysis**

Run:

```bash
set -e
bash tests/git-stack.bash
shellcheck_path=$(nix eval --raw .#nixosConfigurations.nixos.pkgs.shellcheck.outPath)
"$shellcheck_path/bin/shellcheck" files/.local/bin/git-stack tests/git-stack.bash
git diff --check
```

Expected: every integration test prints `ok`; shellcheck and diff checks have
no diagnostics.

- [ ] **Step 6: Commit session ownership**

```bash
git add files/.local/bin/git-stack tests/git-stack.bash
git commit -m "fix(git-stack): rebase session の取り違えを防ぐ"
```

### Task 2: Preserve merge topology

**Files:**
- Modify: `files/.local/bin/git-stack`
- Modify: `tests/git-stack.bash`

**Interfaces:**
- Consumes: the existing initial rebase in `command_done`.
- Produces: descendant replay with `--rebase-merges`.

- [ ] **Step 1: Add a failing merge-topology test**

Add the fixture and test before `run_test` in `tests/git-stack.bash`:

```bash
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
```

Append `test_done_preserves_merge_topology` to the test list.

- [ ] **Step 2: Run the suite and verify normal rebase flattens the merge**

Run:

```bash
bash tests/git-stack.bash
```

Expected: session tests PASS; `test_done_preserves_merge_topology` FAILS with
`preserved merge count: expected [1], got [0]`.

- [ ] **Step 3: Enable Git's merge-recreating backend**

Change the initial rebase command in `command_done` to:

```bash
if git rebase \
    --rebase-merges \
    --onto "refs/heads/$target_branch" \
    "$old_target_oid" \
    --update-refs; then
```

- [ ] **Step 4: Run complete verification**

Run:

```bash
set -e
bash tests/git-stack.bash
shellcheck_path=$(nix eval --raw .#nixosConfigurations.nixos.pkgs.shellcheck.outPath)
"$shellcheck_path/bin/shellcheck" files/.local/bin/git-stack tests/git-stack.bash
PATH="$PWD/files/.local/bin:$PATH" git stack --help >/dev/null
git diff --check
nix flake check --no-build
```

Expected: every integration test prints `ok`; shellcheck, Git discovery,
diff checking, and flake evaluation exit 0. The existing
`greetd.tuigreet` rename warning is acceptable.

- [ ] **Step 5: Commit merge preservation**

```bash
git add files/.local/bin/git-stack tests/git-stack.bash
git commit -m "feat(git-stack): rebase 時に merge topology を維持する"
```
