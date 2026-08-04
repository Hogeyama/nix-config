# `git stack done` Push Prompt Design

## Goal

After `git stack done` finishes its rebase, offer to push each branch that the
rebase actually moved, one branch at a time.

Given the stack from the original design:

```text
main <- A <- B <- C <- D
```

editing `B` and running `git stack done` rewrites `B`, `C`, and `D`, while `A`
stays where it was. The command now continues with:

```console
$ git stack done
Push B to origin/B? [y/N] y
...
Push C to origin/C? [y/N] y
...
Push D to origin/D? [y/N] n
```

`A` is never offered, because the rebase did not move it.

This extends the design in `2026-08-05-git-stack-design.md`. Everything not
described here stays as specified there.

## Candidate Branches

`git stack edit` records the stack's branches and their object IDs in a new
`pre-oids` file inside the state directory. Each line holds an object ID, a
TAB, and a branch name. Git branch names cannot contain whitespace, so the
separator is unambiguous.

The recorded set is the output of the stack listing for the return branch,
followed by the return branch itself. For the example stack, editing `B` from
`D` records `A`, `B`, `C`, and `D` in that order — base side first, tip last.

`pre-oids` joins the required files that `load_state` validates and the files
that `clear_state` removes. Writing it during `edit` means both the
single-shot `done` and the post-conflict continuation read the same snapshot.

After the rebase succeeds, the command re-resolves each recorded branch and
keeps an entry as a push candidate when the branch still exists and its object
ID differs from the recorded one. Candidates keep the recorded order.

## Prompting and Pushing

Candidates are handled one at a time.

When the branch has an upstream, the push destination comes from
`branch.<name>.remote` and `branch.<name>.merge`. The prompt is:

```text
Push B to origin/B? [y/N]
```

On acceptance the command runs:

```console
$ git push --force-with-lease --force-if-includes <remote> refs/heads/B:<merge-ref>
```

The explicit refspec pushes a branch that is not checked out and keeps the
result independent of `push.default`. `--force-with-lease` takes its expected
value from the remote-tracking ref, and `--force-if-includes` additionally
requires that the local history incorporates what was last fetched.

When the branch has no upstream, the command picks a remote: the only remote
if exactly one exists, otherwise `origin` if it exists. If neither applies, the
branch is skipped without a prompt. The prompt is:

```text
Push B to origin/B and set upstream? [y/N]
```

On acceptance the command runs the same push with `--set-upstream` added, using
`refs/heads/B:refs/heads/B` as the refspec.

Answers are read from standard input with `read -r`. Only `y` and `yes`, in any
case, count as acceptance; anything else declines. Reaching end of input stops
the remaining prompts and writes `git stack: no input; skipping remaining
pushes` to standard error. End of input is not itself a failure: the exit
status still depends only on whether an attempted push failed. This keeps
`git stack done </dev/null` non-interactive and makes
`printf 'y\nn\n' | git stack done` testable.

## Placement in the `done` Flow

Prompting runs only on the paths where the rebase succeeded: the edit-phase
`done` that completes without conflict, and the continuation `done` whose
`git rebase --continue` completes the rebase.

The command reads `pre-oids` into memory, calls `clear_state`, and only then
starts prompting. Interrupting the pushes therefore never leaves stale stack
state behind.

## Errors and Exit Status

A failed push shows Git's own output, writes `git stack: push failed: <branch>`
to standard error, and moves on to the next candidate. After all candidates are
handled, the command exits 1 if any push failed. The rebase has already
completed, so a push failure never rewinds the stack.

With no candidates, or with no usable remote, the command prints nothing extra
and exits 0, matching the previous behavior.

## Repository Changes

- Extend `files/.local/bin/git-stack`.
- Extend `tests/git-stack.bash`.

The navi cheat needs no change; the subcommand surface is unchanged.

## Tests

The integration test gains a helper that creates a stack whose branches track a
bare repository used as a remote. It covers:

- offering only the branches the rebase moved, leaving `A` unmentioned;
- accepting a prompt and observing the remote ref advance;
- declining a prompt and observing the remote ref stay put;
- pushing a branch without an upstream with `--set-upstream`, then finding
  `branch.<name>.merge` set;
- prompting nothing in a repository with no remote;
- running with standard input at `/dev/null`, pushing nothing, and exiting 0;
- prompting after a conflict is resolved and the continuation `done` succeeds.

Verification also runs `shellcheck` on the script and the repository's
applicable Nix flake checks.
