# `git stack` Design

## Goal

Add a small Git subcommand for editing a branch in a linear stack and
rebasing all descendant stack branches onto the edited result.

Given local branches arranged like this:

```text
main <- A <- B <- C <- D
```

while on `D`, the workflow is:

```console
$ git stack edit B
# edit B, producing B'
$ git stack done
```

The result is:

```text
main <- A <- B' <- C' <- D'
```

`git stack done` returns to `D`, and `--update-refs` moves the intermediate
branch refs such as `C`.

## Command Surface

The command is implemented as `files/.local/bin/git-stack`, following the
existing `git-find-merges` convention. Git discovers it as the following
subcommands:

```text
git stack edit <local-branch>
git stack done
git stack list
git stack --help
```

`edit` and the initial `done` require a clean worktree, including no untracked
files. The `done` used to continue a conflicted rebase permits staged conflict
resolutions and lets `git rebase --continue` perform its normal validation.

## Base Branch Selection

The base branch defines the lower boundary of the stack. It does not become an
argument to the descendant rebase.

Users may configure any number of local base branches with Git's multivar
syntax:

```console
$ git config --add stack.baseBranch main
$ git config --add stack.baseBranch develop
```

The command reads all values with `git config --get-all stack.baseBranch`. If
the key is unset, existing local `main` and `master` branches become the
default candidates.

For the current branch, base selection works as follows:

1. Ignore candidates that do not name a local branch.
2. Ignore candidates that are not ancestors of the current branch.
3. If several remain, choose the candidate with the shortest ancestry path to
   the current branch.
4. Break an equal-distance tie by the order returned from
   `git config --get-all`; for the defaults, prefer `main` before `master`.
5. If none remain, fail with a message that shows how to configure
   `stack.baseBranch`.

## Stack Branch Listing

`git stack list` prints eligible local branches between the selected base and
the current branch, excluding both endpoints. It walks commits on the ancestry
path in topological, base-to-tip order and prints local branch refs whose tips
point at those commits. If several local branches point at one commit, it
prints each of them in lexicographic order.

For the example stack, running the command on `D` prints:

```text
A
B
C
```

`git stack edit` uses the same set of commits for validation, ensuring that
the completion candidates and accepted targets cannot diverge.

The navi cheat delegates completion to the command rather than duplicating
the graph logic:

```text
git stack edit <stack-branch>

$ stack-branch: git stack list
```

## Edit State

The command resolves the state location with:

```console
$ git rev-parse --git-path stack-edit
```

This is `.git/stack-edit/` in a normal checkout and the worktree-specific Git
directory in a linked worktree. Worktrees therefore cannot overwrite one
another's edit state.

The directory records:

- the target branch name;
- the target branch's complete pre-edit object ID;
- the return branch name;
- a unique session ID;
- the current phase, either `edit` or `rebase`.

Only one active edit is permitted per worktree. State is created after all
validation succeeds. If `git switch` fails, the newly created state is
removed.

## `edit` Flow

`git stack edit B`, invoked on `D`, validates that:

- it is inside a Git worktree;
- the worktree is clean;
- `HEAD` is a local branch;
- `B` names a local branch;
- `B` differs from the current branch;
- `B` is in the set produced by the same graph logic as `git stack list`;
- there is no other active edit.

It records `B`, the old object ID of `B`, `D`, a unique session ID, and the
`edit` phase, then runs:

```console
$ git switch B
```

The user may amend, reset, interactively rebase, or add commits on `B`.

## `done` Flow

For an edit-phase session, `git stack done` requires a clean worktree and
requires the target branch to remain checked out. It resolves the new target
tip, switches to the recorded return branch, records the `rebase` phase, and
runs:

```console
$ git rebase --rebase-merges --onto B <old-B-object-id> --update-refs
```

The replay set is `<old-B-object-id>..D`. It therefore contains `C` and `D`,
but excludes the old `B`. The new base is the branch `B`, which now points at
`B'`. This works both when `B` was rewritten and when commits were merely
added to it, without replaying or duplicating `B`.

`--rebase-merges` recreates merge topology within the replayed range. As with
Git's native behavior, conflict resolutions and manual amendments made only
in an old merge commit may need to be resolved or reapplied while rebasing.

On success, the command removes its edit state. On a conflict, it leaves the
state in the `rebase` phase, preserves Git's own rebase state, and writes the
session ID to `git-stack-session` inside Git's active `rebase-merge`
directory. If the rebase fails without leaving an active rebase, the command
removes its edit state.

## Conflicts and Cancellation

After a conflict, the user resolves files, stages them, and runs:

```console
$ git stack done
```

When the stored phase is `rebase`, the command checks both Git's rebase state
and the session marker before running `git rebase --continue`:

- A missing rebase directory means the stack rebase was aborted or completed
  directly. The command clears stale stack state.
- A missing marker or a marker whose session ID differs means another rebase
  is in progress. The command clears only the stale stack state, fails with a
  diagnostic, and never continues that rebase.
- A matching marker proves that the active rebase was started by this stack
  session. The command runs `git rebase --continue`.

The merge rebase backend preserves the unknown marker file between repeated
conflicts. Successful completion or `git rebase --abort` removes the entire
rebase directory, including the marker.

No custom `abort` subcommand is provided:

- During the edit phase, `git switch D` cancels the workflow. The next
  `git stack` invocation observes that `B` is no longer checked out and clears
  the stale edit state.
- During the rebase phase, `git rebase --abort` cancels the rebase. The next
  `git stack` invocation observes that no rebase is in progress and clears the
  stale state.
- If the user completes the rebase directly with `git rebase --continue`, the
  next `git stack` invocation clears the now-stale state in the same way.

Cancellation never rewinds or deletes commits made while editing `B`.

## Errors

Failures use a nonzero exit status and a concise diagnostic. Expected
validation errors include:

- dirty worktree;
- detached `HEAD`;
- missing or inapplicable base branches;
- missing or ineligible target branch;
- an active edit session;
- invoking `done` without a session;
- finding a rebase whose session marker does not match the recorded stack
  session;
- unexpected arguments or subcommands.

Output from Git commands, including hooks and rebase conflicts, remains
visible rather than being replaced by generic errors.

## Repository Changes

- Add `files/.local/bin/git-stack`.
- Add `tests/git-stack.bash`.
- Update `files/.local/share/navi/cheats/git.cheat` with `edit` and `done`
  examples and a `git stack list`-backed completion variable.

## Tests

The integration test creates temporary Git repositories and invokes the real
script. It covers:

- amending `B` and rebasing `C` and `D` onto `B'`;
- updating the intermediate `C` ref with `--update-refs`;
- adding commits to `B` without duplicating old commits;
- preserving merge topology in the replayed range;
- multiple configured bases and nearest-applicable-base selection;
- the `main` and `master` defaults;
- ordered `list` output and its exclusion of the base and current branch;
- rejection of dirty worktrees, detached `HEAD`, non-stack branches, and bad
  arguments;
- conflict continuation through a repeated `git stack done`;
- preserving the session marker through multiple conflict/continue cycles;
- refusing to continue an unrelated rebase started after aborting the stack
  rebase;
- stale-state cleanup after `git switch`, `git rebase --abort`, and direct
  `git rebase --continue`;
- help output.

Verification also runs `shellcheck` on the script and the repository's
applicable Nix flake checks.
