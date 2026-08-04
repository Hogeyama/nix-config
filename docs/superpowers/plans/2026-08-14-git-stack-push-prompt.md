# `git stack done` Push Prompt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After `git stack done` finishes its rebase, ask branch by branch whether to push the branches the rebase moved.

**Architecture:** `git stack edit` records a snapshot of every stack branch's object ID in `.git/stack-edit/pre-oids`. When `git stack done` completes its rebase, it reads that snapshot into memory, clears the stack state, then compares each recorded branch against its current object ID. Branches whose object ID changed are offered for a force push, one prompt at a time, in base-to-tip order.

**Tech Stack:** Bash 5 with `set -euo pipefail`, Git 2.43, `shellcheck`, and a hand-rolled integration test harness in `tests/git-stack.bash`.

## Global Constraints

- The script is `files/.local/bin/git-stack`. It keeps `set -euo pipefail`, 4-space indentation, and `local` declarations at the top of each function, matching the existing code.
- Every change must keep `shellcheck files/.local/bin/git-stack` clean.
- The whole suite is run with `bash tests/git-stack.bash` from the repository root. It must exit 0.
- Every new test function must be added to the list inside `main` at the bottom of `tests/git-stack.bash`, otherwise it never runs.
- Test functions are invoked by name through a variable, so the file-level `# shellcheck disable=SC2329` at the top already covers them. Do not add per-function disables.
- Pushes always use `--force-with-lease --force-if-includes`.
- Prompts and diagnostics go to standard error. `git stack done` writes nothing to standard output of its own.
- Answers are read from standard input. Only `y` and `yes`, in any letter case, accept.
- The design this implements is `docs/superpowers/specs/2026-08-14-git-stack-push-prompt-design.md`.

---

### Task 1: Record the pre-rebase object ID snapshot

`git stack edit` gains a `pre-oids` file listing every stack branch and the object ID it had when the edit began. The file is one line per branch, `<oid><TAB><branch>`, in base-to-tip order, ending with the return branch. Git branch names cannot contain whitespace, so a TAB never appears inside a field.

**Files:**
- Modify: `files/.local/bin/git-stack:32-41` (`clear_state`), `:75-92` (`load_state`), `:125-137` (`write_edit_state`)
- Test: `tests/git-stack.bash:115-129` (`test_edit_switches_and_records_state`)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the file at `$state_dir/pre-oids`, read by Task 2's `collect_moved_branches`.

- [ ] **Step 1: Extend the existing edit-state test to assert the snapshot**

Replace the body of `test_edit_switches_and_records_state` in `tests/git-stack.bash` with this. The `expected` value is built from the branch tips, which `edit` does not change.

```bash
test_edit_switches_and_records_state() {
    local repo old_b state_dir expected
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/git-stack.bash`
Expected: FAIL at `test_edit_switches_and_records_state` with `not ok - stored pre oids: expected [...], got []`, because `$state_dir/pre-oids` does not exist yet.

- [ ] **Step 3: Add `pre-oids` to `clear_state`**

In `files/.local/bin/git-stack`, extend the `rm -f` list in `clear_state`:

```bash
clear_state() {
    [[ -d $state_dir ]] || return 0
    rm -f -- \
        "$state_dir/target-branch" \
        "$state_dir/old-target-oid" \
        "$state_dir/return-branch" \
        "$state_dir/session-id" \
        "$state_dir/phase" \
        "$state_dir/pre-oids"
    rmdir -- "$state_dir"
}
```

- [ ] **Step 4: Require `pre-oids` in `load_state`**

Change the `for` loop in `load_state` to include the new file:

```bash
    for file in target-branch old-target-oid return-branch session-id phase pre-oids; do
```

- [ ] **Step 5: Write the snapshot in `write_edit_state`**

`write_edit_state` runs while the return branch is still checked out, and `stack_branches` takes the branch name as an argument, so the listing is correct here. Replace `write_edit_state` with:

```bash
write_edit_state() {
    local target=$1
    local old_target_oid=$2
    local return_branch=$3
    local new_session=$4
    local branch

    mkdir "$state_dir"
    printf '%s\n' "$target" >"$state_dir/target-branch"
    printf '%s\n' "$old_target_oid" >"$state_dir/old-target-oid"
    printf '%s\n' "$return_branch" >"$state_dir/return-branch"
    printf '%s\n' "$new_session" >"$state_dir/session-id"
    printf '%s\n' edit >"$state_dir/phase"
    {
        while IFS= read -r branch; do
            printf '%s\t%s\n' "$(git rev-parse "refs/heads/$branch")" "$branch"
        done < <(stack_branches "$return_branch")
        printf '%s\t%s\n' \
            "$(git rev-parse "refs/heads/$return_branch")" "$return_branch"
    } >"$state_dir/pre-oids"
}
```

- [ ] **Step 6: Run the suite to verify it passes**

Run: `bash tests/git-stack.bash`
Expected: every line reports `ok - <name>`, exit status 0.

- [ ] **Step 7: Run shellcheck**

Run: `shellcheck files/.local/bin/git-stack tests/git-stack.bash`
Expected: no output, exit status 0.

- [ ] **Step 8: Commit**

```bash
git add files/.local/bin/git-stack tests/git-stack.bash
git commit -m "feat(git-stack): edit 時にスタックの OID を記録する"
```

---

### Task 2: Prompt and push branches that have an upstream

After a conflict-free `git stack done`, compare the snapshot against the current branch tips and offer a force push for each branch that moved. This task handles only branches that already have an upstream; branches without one are skipped silently and are picked up in Task 4.

**Files:**
- Modify: `files/.local/bin/git-stack` (new functions above `command_done`, and the success path inside `command_done`)
- Test: `tests/git-stack.bash` (new `make_remote_stack`, `rewrite_b`, and three new test functions)

**Interfaces:**
- Consumes: `$state_dir/pre-oids` from Task 1.
- Produces:
  - `moved` — a global array of branch names, filled by `collect_moved_branches`, in snapshot order.
  - `collect_moved_branches()` — reads `$state_dir/pre-oids` and fills `moved`. Must run before `clear_state`.
  - `prompt_pushes()` — prompts for each entry of `moved`; returns 0 when no push failed, 1 otherwise.
  - `finish_session()` — the success tail of `command_done`: collect, clear, prompt. Returns `prompt_pushes`'s status.

- [ ] **Step 1: Add the remote test helpers**

Insert these two helpers into `tests/git-stack.bash` immediately after `make_stack` (which ends around line 80). `make_remote_stack` creates the usual `main <- A <- B <- C <- D` stack plus a bare repository at `$TEST_ROOT/<name>.git` with every branch pushed and tracking. `rewrite_b` performs the standard edit-and-amend of `B` used by several tests.

```bash
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
```

- [ ] **Step 2: Write the failing tests**

Append these three test functions to `tests/git-stack.bash`, just before `run_test`.

```bash
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
```

Add the three names to the list inside `main`, after `test_done_handles_commits_added_to_target`:

```bash
        test_done_prompts_only_moved_branches \
        test_done_declines_leave_remote_untouched \
        test_done_pushes_accepted_branches \
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `bash tests/git-stack.bash`
Expected: FAIL at `test_done_prompts_only_moved_branches` with `not ok - B prompt missing`, because `done` prints no prompts yet.

- [ ] **Step 4: Declare the `moved` global**

In `files/.local/bin/git-stack`, add the array to the global declarations near the top, after `phase=`:

```bash
phase=
moved=()
```

- [ ] **Step 5: Add the collection, prompting, and finishing functions**

Insert these four functions into `files/.local/bin/git-stack` directly above `command_done`. `default_remote` is defined now but only used from Task 4; keeping it here keeps the remote-resolution logic in one place.

```bash
collect_moved_branches() {
    local oid branch current

    moved=()
    while IFS=$'\t' read -r oid branch; do
        local_branch_exists "$branch" || continue
        current=$(git rev-parse "refs/heads/$branch")
        [[ $current == "$oid" ]] && continue
        moved+=("$branch")
    done <"$state_dir/pre-oids"
}

default_remote() {
    local remote
    local -a remotes=()

    mapfile -t remotes < <(git remote)
    if ((${#remotes[@]} == 1)); then
        printf '%s\n' "${remotes[0]}"
        return 0
    fi
    for remote in "${remotes[@]}"; do
        if [[ $remote == origin ]]; then
            printf '%s\n' origin
            return 0
        fi
    done
    return 1
}

prompt_pushes() {
    local branch remote merge_ref display reply
    local failed=0
    local -a args=()

    ((${#moved[@]} > 0)) || return 0
    for branch in "${moved[@]}"; do
        remote=$(git config --get "branch.$branch.remote" || :)
        merge_ref=$(git config --get "branch.$branch.merge" || :)
        [[ -n $remote && -n $merge_ref ]] || continue
        display=$remote/${merge_ref#refs/heads/}
        args=(push --force-with-lease --force-if-includes
            "$remote" "refs/heads/$branch:$merge_ref")
        printf 'Push %s to %s? [y/N] ' "$branch" "$display" >&2
        IFS= read -r reply
        case ${reply,,} in
            y | yes) ;;
            *) continue ;;
        esac
        if ! git "${args[@]}"; then
            echo "git stack: push failed: $branch" >&2
            failed=1
        fi
    done
    return "$failed"
}

finish_session() {
    local status=0

    collect_moved_branches
    clear_state
    prompt_pushes || status=$?
    return "$status"
}
```

- [ ] **Step 6: Call `finish_session` from the conflict-free success path**

In `command_done`, replace the success branch of the initial rebase. Change:

```bash
    if git rebase \
        --rebase-merges \
        --onto "refs/heads/$target_branch" \
        "$old_target_oid" \
        --update-refs; then
        clear_state
        return 0
    fi
```

into:

```bash
    if git rebase \
        --rebase-merges \
        --onto "refs/heads/$target_branch" \
        "$old_target_oid" \
        --update-refs; then
        local status=0
        finish_session || status=$?
        return "$status"
    fi
```

Leave the `phase == rebase` continuation branch alone; Task 6 changes it.

- [ ] **Step 7: Run the suite to verify it passes**

Run: `bash tests/git-stack.bash`
Expected: every line reports `ok - <name>`, exit status 0.

- [ ] **Step 8: Run shellcheck**

Run: `shellcheck files/.local/bin/git-stack tests/git-stack.bash`
Expected: no output, exit status 0.

- [ ] **Step 9: Commit**

```bash
git add files/.local/bin/git-stack tests/git-stack.bash
git commit -m "feat(git-stack): done 後に動いたブランチの push を確認する"
```

---

### Task 3: Stop cleanly when standard input ends

With `set -euo pipefail`, a bare `read -r` that hits end of input aborts the script. Running `git stack done </dev/null` must instead skip the remaining prompts, report why, and exit 0.

**Files:**
- Modify: `files/.local/bin/git-stack` (`prompt_pushes`)
- Test: `tests/git-stack.bash` (one new test function)

**Interfaces:**
- Consumes: `prompt_pushes` from Task 2.
- Produces: no new names.

- [ ] **Step 1: Write the failing test**

Append to `tests/git-stack.bash`, just before `run_test`:

```bash
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
```

Add `test_done_without_input_skips_pushes` to the list inside `main`, after `test_done_pushes_accepted_branches`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/git-stack.bash`
Expected: FAIL at `test_done_without_input_skips_pushes` with `not ok - done with no input exited nonzero`, because the failing `read` aborts the script under `set -e`.

- [ ] **Step 3: Handle end of input inside `prompt_pushes`**

Replace the bare read in `prompt_pushes` with:

```bash
        if ! IFS= read -r reply; then
            printf '\n' >&2
            echo "git stack: no input; skipping remaining pushes" >&2
            break
        fi
```

- [ ] **Step 4: Run the suite to verify it passes**

Run: `bash tests/git-stack.bash`
Expected: every line reports `ok - <name>`, exit status 0.

- [ ] **Step 5: Run shellcheck**

Run: `shellcheck files/.local/bin/git-stack tests/git-stack.bash`
Expected: no output, exit status 0.

- [ ] **Step 6: Commit**

```bash
git add files/.local/bin/git-stack tests/git-stack.bash
git commit -m "feat(git-stack): 入力が尽きたら残りの push 確認を打ち切る"
```

---

### Task 4: Offer `--set-upstream` for branches without an upstream

A moved branch with no upstream gets a remote chosen by rule: the only remote if exactly one exists, otherwise `origin` if it exists, otherwise the branch is skipped without a prompt.

**Files:**
- Modify: `files/.local/bin/git-stack` (`prompt_pushes`)
- Test: `tests/git-stack.bash` (two new test functions)

**Interfaces:**
- Consumes: `default_remote` and `prompt_pushes` from Task 2.
- Produces: no new names.

- [ ] **Step 1: Write the failing tests**

Append to `tests/git-stack.bash`, just before `run_test`. `make_untracked_remote_stack` pushes only `main`, so `A` through `D` have no upstream.

```bash
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
```

Add both test names to the list inside `main`, after `test_done_without_input_skips_pushes`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/git-stack.bash`
Expected: FAIL at `test_done_sets_upstream_for_untracked_branches` with `not ok - set-upstream prompt missing`, because `prompt_pushes` currently skips branches with no upstream.

- [ ] **Step 3: Handle branches without an upstream**

In `prompt_pushes`, replace the skip line and the prompt setup. Change:

```bash
        [[ -n $remote && -n $merge_ref ]] || continue
        display=$remote/${merge_ref#refs/heads/}
        args=(push --force-with-lease --force-if-includes
            "$remote" "refs/heads/$branch:$merge_ref")
        printf 'Push %s to %s? [y/N] ' "$branch" "$display" >&2
```

into:

```bash
        if [[ -n $remote && -n $merge_ref ]]; then
            display=$remote/${merge_ref#refs/heads/}
            args=(push --force-with-lease --force-if-includes
                "$remote" "refs/heads/$branch:$merge_ref")
            printf 'Push %s to %s? [y/N] ' "$branch" "$display" >&2
        else
            remote=$(default_remote) || continue
            display=$remote/$branch
            args=(push --force-with-lease --force-if-includes --set-upstream
                "$remote" "refs/heads/$branch:refs/heads/$branch")
            printf 'Push %s to %s and set upstream? [y/N] ' \
                "$branch" "$display" >&2
        fi
```

- [ ] **Step 4: Run the suite to verify it passes**

Run: `bash tests/git-stack.bash`
Expected: every line reports `ok - <name>`, exit status 0.

- [ ] **Step 5: Run shellcheck**

Run: `shellcheck files/.local/bin/git-stack tests/git-stack.bash`
Expected: no output, exit status 0.

- [ ] **Step 6: Commit**

```bash
git add files/.local/bin/git-stack tests/git-stack.bash
git commit -m "feat(git-stack): upstream 未設定のブランチに -u 付き push を提案する"
```

---

### Task 5: Report push failures and exit nonzero

A failed push must not stop the remaining prompts, and the command must end with status 1 when any push failed. `prompt_pushes` already implements this; this task proves it and pins the behavior with a test.

**Files:**
- Test: `tests/git-stack.bash` (one new test function)

**Interfaces:**
- Consumes: `prompt_pushes` from Task 2 and `finish_session` from Task 2.
- Produces: no new names.

- [ ] **Step 1: Write the test**

Append to `tests/git-stack.bash`, just before `run_test`. Pointing `origin` at a path with no repository makes every push fail while leaving the rebase result intact.

```bash
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
```

Add `test_done_reports_push_failures` to the list inside `main`, after `test_done_without_remote_prompts_nothing`.

- [ ] **Step 2: Run the suite**

Run: `bash tests/git-stack.bash`
Expected: every line reports `ok - <name>`, exit status 0. If `test_done_reports_push_failures` fails, the cause is in `prompt_pushes` or `finish_session` from Task 2 — fix it there rather than weakening the test.

- [ ] **Step 3: Commit**

```bash
git add tests/git-stack.bash
git commit -m "test(git-stack): push 失敗時も残りを確認し 1 で終わることを検証する"
```

---

### Task 6: Prompt after a conflict is resolved

The continuation `git stack done` that completes a conflicted rebase must prompt exactly like the conflict-free path.

**Files:**
- Modify: `files/.local/bin/git-stack:245-255` (the `phase == rebase` branch of `command_done`)
- Test: `tests/git-stack.bash` (one new test function)

**Interfaces:**
- Consumes: `finish_session` from Task 2.
- Produces: no new names.

- [ ] **Step 1: Write the failing test**

Append to `tests/git-stack.bash`, just before `run_test`. It reuses `make_conflicting_stack`, which builds a stack where rebasing `C` onto the rewritten `B` conflicts on `conflict.txt`.

```bash
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
```

Add `test_done_prompts_after_conflict_resolution` to the list inside `main`, after `test_done_reports_push_failures`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/git-stack.bash`
Expected: FAIL at `test_done_prompts_after_conflict_resolution` with `not ok - continuation B prompt missing`, because the continuation path still calls `clear_state` directly.

- [ ] **Step 3: Call `finish_session` from the continuation path**

In `command_done`, change:

```bash
        if git rebase --continue; then
            clear_state
            return 0
        fi
```

into:

```bash
        if git rebase --continue; then
            local status=0
            finish_session || status=$?
            return "$status"
        fi
```

- [ ] **Step 4: Run the suite to verify it passes**

Run: `bash tests/git-stack.bash`
Expected: every line reports `ok - <name>`, exit status 0.

- [ ] **Step 5: Run shellcheck**

Run: `shellcheck files/.local/bin/git-stack tests/git-stack.bash`
Expected: no output, exit status 0.

- [ ] **Step 6: Commit**

```bash
git add files/.local/bin/git-stack tests/git-stack.bash
git commit -m "feat(git-stack): コンフリクト解消後の done でも push を確認する"
```
