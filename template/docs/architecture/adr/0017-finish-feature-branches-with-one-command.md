# ADR-0017: Finish a feature branch with one command, and never delete `main`

- **Status:** accepted
- **Scope:** system
- **Date:** 2026-11-20
- **Related:** [ADR-0008](0008-security-checks-for-a-public-repository.md), [ADR-0009](0009-github-repository-protection.md)

## Context
ADR-0009 sends every change to `main` through a PR whose checks must pass. Finishing a branch is then the same chain of steps each time: commit, push, open the PR, wait for the checks, merge, delete the branch locally and on the remote, update `main`. Done by hand, steps get skipped (stale local branches, a forgotten `git pull`), and a mistyped branch name in a delete command can hit `main`. GitHub blocks deleting the protected remote `main`, but not the local branch, and not a repo where `tools/bootstrap-github.sh` hasn't run yet.

## Decision
1. **`/commit-push-merge-feature-branch [message]`** does the whole chain. It stages and commits everything (with the pre-commit hooks, never `--no-verify`), pushes, and on a feature branch opens or reuses a PR to `main`, waits for its checks, merges it with a merge commit and deletes the branch on the remote and locally. On `main` it only commits and pushes. It stops at the first failure and leaves the PR and the branch in place. Only the user can start it (`disable-model-invocation`).
2. **`tools/git/protect-main-branch.sh`**, a `PreToolUse` hook on Bash, blocks any command Claude runs that would delete `main`: `git branch -d|-D main`, `git push --delete main` or `:main`, `git update-ref -d refs/heads/main`, and `gh api -X DELETE` on the branch or its protection.

## Alternatives considered
| Option | Pros | Cons | Why not chosen |
|--------|------|------|----------------|
| Merge locally and push `main` | No `gh` needed | Rejected by branch protection; skips the required checks | Kept only as a fallback without `gh` |
| Squash or rebase merge | Linear history | Differs from the repo's merge-commit history | Merge commits keep the branch's commits as written |
| `permissions.deny` rules instead of a hook | No script | Prefix rules miss `-C <dir>`, chained commands and `:main` refspecs | Not precise enough |
| Rely on GitHub's protection only | Nothing to maintain | Doesn't cover the local branch or an unprotected repo | Leaves a gap |

## Consequences
- **Positive:** finishing a branch is one command with the same steps every time; no stale branches; `main` can't be deleted by Claude.
- **Negative / trade-offs:** the command waits for CI, so it can take minutes. The hook matches command text, so an unusual way to delete a branch (for example a script) can get past it; GitHub's protection remains the backstop for the remote. Deleting `main` by hand in a terminal is not blocked.
- **Follow-up:** if the repo moves from a merge commit to squash merges, change step 6 of the skill.
