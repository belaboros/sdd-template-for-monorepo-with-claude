---
name: commit-push-merge-feature-branch
description: Commit all changes, push, and (on a feature branch) merge it into main through a PR, then delete the branch. Only when the user runs /commit-push-merge-feature-branch.
argument-hint: [commit message]
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git switch:*), Bash(git pull:*), Bash(git fetch:*), Bash(git branch:*), Bash(git merge:*), Bash(git rev-parse:*), Bash(gh pr:*), Bash(gh auth status:*)
---

Commit, push and merge the current branch (ADR-0017). Running this command is the user's approval for every step below, including the merge into `main` and the deletion of the feature branch; don't ask again unless a step fails.

## Current state

- Branch: !`git rev-parse --abbrev-ref HEAD`
- Changes:
!`git status --short`
- Unpushed commits: !`git log --oneline @{u}..HEAD 2>/dev/null || echo "(branch has no upstream yet)"`
- Recent commit messages (style to follow): !`git log --oneline -5`

Commit message given by the user (may be empty): $ARGUMENTS

## Steps

Stop at the first step that fails and report what failed, with its output. Never use `--no-verify`, `--force` or `git reset --hard`, and never delete `main` (a hook blocks it).

1. **Check.** If the branch is `HEAD` (detached), stop. If there are no changes and no unpushed commits, and the branch is `main`, say there is nothing to do and stop.
2. **Commit.** If there are changes:
   - `git add -A`, then read `git diff --cached` to see what goes in.
   - Look at the staged files for secrets, `.env` files, tokens and personal data, and for `data/<dataset>/` folders whose dataset is not `commit` (ADR-0016). If you find any, unstage them and stop, telling the user why.
   - Use the user's message if given; otherwise write one in the style of the recent commits: an imperative subject under 72 characters, then a short body on why, if the change is not obvious.
   - `git commit`. If the pre-commit hooks fail, fix the cause, `git add -A` again and make a **new** commit (don't amend). If a hook only reformatted files, re-stage and commit again.
3. **Push.** `git push -u origin <branch>`.
   - On `main`, that's the end: report the commit and stop. If GitHub rejects the push because `main` is protected (ADR-0009), say so and suggest moving the commit to a feature branch (`git switch -c <branch>`, then run this command again); don't do it unasked.
4. **Open the PR** (feature branch only). `gh pr view --json number,url,state` shows whether one exists. If not: `gh pr create --base main --head <branch> --title "<subject>" --body "<summary of all commits on the branch>"`. If `gh` is missing or not logged in (`gh auth status`), go to step 7.
5. **Wait for the checks.** `gh pr checks --watch --fail-fast`. If a check fails, stop and report it with `gh pr checks`; leave the PR and the branch as they are. If the PR has no checks, continue.
6. **Merge and delete.** `gh pr merge --merge --delete-branch` (a merge commit, as in the repo's history). It deletes the remote branch, switches to `main` and deletes the local branch. If GitHub says the branch is behind `main`, run `gh pr update-branch`, then go back to step 5.
   Then: `git switch main`, `git pull --ff-only`, `git fetch --prune`, and `git branch -d <branch>` if it still exists (`-d`, not `-D`: it refuses unless the branch is merged).
7. **Without GitHub CLI** (fallback only): `git switch main`, `git pull --ff-only`, `git merge --no-ff <branch>`, `git push origin main`, then `git branch -d <branch>` and `git push origin --delete <branch>`. If the push to `main` is rejected, stop: the branch is protected and the merge must go through a PR.
8. **Report** in a few lines: the commit(s), the PR link, the merge commit on `main`, and that `<branch>` was deleted locally and on the remote.
