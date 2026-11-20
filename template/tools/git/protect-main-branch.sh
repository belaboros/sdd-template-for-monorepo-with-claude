#!/usr/bin/env bash
# Claude Code PreToolUse hook for Bash (ADR-0017).
# Blocks commands that would delete the `main` branch, locally or on the remote:
#   git branch -d|-D|--delete main      git push <remote> --delete main | :main
#   git update-ref -d refs/heads/main   gh api -X DELETE .../git/refs/heads/main | .../branches/main/...
# GitHub's branch protection (ADR-0009) also blocks remote deletion; this hook covers the local branch
# and repos where protection is not applied yet.
set -uo pipefail

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# `main` as a whole ref name: after a space, quote, ':' or 'heads/'; before a space, quote or the end.
main_ref='(^|[[:space:]:"'\'']|heads/)main($|[[:space:]"'\'')])'
git_cmd='^[[:space:]]*(sudo[[:space:]]+)?(command[[:space:]]+)?git([[:space:]]+(-C|-c)[[:space:]]+[^[:space:]]+|[[:space:]]+--[^[:space:]]+)*[[:space:]]+'

blocked=""
# Check each simple command on its own, so `git branch -d foo && git switch main` is not flagged.
while IFS= read -r seg; do
  if [[ "$seg" =~ ${git_cmd}branch[[:space:]] ]] \
     && [[ "$seg" =~ [[:space:]](--delete|-[a-zA-Z]*[dD][a-zA-Z]*)([[:space:]]|$) ]] \
     && [[ "$seg" =~ $main_ref ]]; then
    blocked="$seg"
  elif [[ "$seg" =~ ${git_cmd}push[[:space:]] ]] \
       && { [[ "$seg" =~ [[:space:]](--delete|-d)([[:space:]]|$) && "$seg" =~ $main_ref ]] \
            || [[ "$seg" =~ [[:space:]]\+?:(refs/heads/)?main($|[[:space:]]) ]]; }; then
    blocked="$seg"
  elif [[ "$seg" =~ ${git_cmd}update-ref[[:space:]]+(-d|--delete)[[:space:]]+(refs/heads/)?main($|[[:space:]]) ]]; then
    blocked="$seg"
  elif [[ "$seg" =~ ^[[:space:]]*gh[[:space:]]+api[[:space:]] ]] \
       && [[ "$seg" =~ DELETE ]] \
       && [[ "$seg" =~ (refs/heads|branches)/main($|[[:space:]/\"\']) ]]; then
    blocked="$seg"
  fi
  [ -n "$blocked" ] && break
done < <(printf '%s\n' "$cmd" | sed -E 's/(&&|\|\||;|\|)/\n/g')

[ -z "$blocked" ] && exit 0

cat >&2 <<EOF
Blocked: this command would delete the 'main' branch (ADR-0017):
  $(printf '%s' "$blocked" | sed -E 's/^[[:space:]]+//')
'main' is the integration branch and must never be deleted. Delete feature branches only.
Do not run the command another way to get around this check.
EOF
exit 2
