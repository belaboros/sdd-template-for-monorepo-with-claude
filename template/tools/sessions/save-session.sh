#!/usr/bin/env bash
# Saves a Claude Code session as docs/sessions/YYYYMMDD-HHMMSS[-name]-<id8>.md (ADR-0014; time = first request, UTC).
# Kept: a short summary, the user's requests, Claude's text replies, and each subagent's prompt and text replies.
# Left out: thinking, tool calls, tool output, injected context, slash commands without a reply
# (/clear, /model, ...) and the /save-claude-chat-session call itself.
# A session is saved at most once: if a file for its id already exists, nothing is written.
#
# Usage:
#   as a SessionEnd hook: reads {"transcript_path": ...} from stdin
#   from /save-claude-chat-session: save-session.sh --name "<name>" <session-id>
#   manually:             save-session.sh [--name NAME] [transcript.jsonl | session-id]
#                         (default: newest session of this project)
set -uo pipefail

[ "${RA_SESSION_SUMMARY_CHILD:-}" = 1 ] && exit 0   # don't recurse from the summariser run

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
outdir="$root/docs/sessions"
projdir="$HOME/.claude/projects/$(printf '%s' "$root" | sed 's/[^a-zA-Z0-9]/-/g')"

resolve_transcript() {   # $1: transcript path, session id, or empty
  local src="${1:-}"
  # shellcheck disable=SC2016  # matches the literal, unsubstituted placeholder on purpose
  case "$src" in
    '' | '${CLAUDE_SESSION_ID}') ;;                      # not given, or not substituted
    *.jsonl) echo "$src"; return ;;
    *) echo "$projdir/$src.jsonl"; return ;;
  esac
  if [ ! -t 0 ]; then
    local p; p=$(jq -r '.transcript_path // empty' 2>/dev/null)
    [ -n "$p" ] && { echo "$p"; return; }
  fi
  # newest transcript by modification time (session ids are UUIDs, so ls is safe here)
  # shellcheck disable=SC2012
  ls -t "$projdir"/*.jsonl 2>/dev/null | head -1
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-60 | sed -E 's/-+$//'
}

existing_file() {   # $1: id8 → prints the saved file of this session, if any
  local f
  for f in "$outdir"/*-"$1".md; do
    [ -f "$f" ] && { echo "$f"; return; }
  done
}

# Shared jq definitions: cleaning user text, and reading content blocks in order.
# An item is a reply text (string) or {agent: <tool_use id>} where a subagent was launched.
JQ_DEFS='
  def unwrap_command:
    if test("<command-name>") then
      ((capture("<command-name>(?<n>[^<]*)</command-name>").n // "")
       + " " + ((capture("<command-args>(?<a>[\\s\\S]*?)</command-args>").a) // ""))
    else . end;
  def strip_injected: gsub("<(?<t>[a-z][a-z_-]*)>[\\s\\S]*?</\\k<t>>"; "");
  def clean: unwrap_command | strip_injected | gsub("^\\s+|\\s+$"; "");
  def texts: if type == "string" then [.] else [.[]? | select(.type == "text") | .text] end;
  def user_text: .message.content | texts | map(clean) | map(select(length > 0)) | join("\n\n");
  def items:
    if type == "string" then [.] else
      [ .[]? | if .type == "text" then .text
               elif .type == "tool_use" and (.name == "Agent" or .name == "Task") then {agent: .id}
               elif .type == "tool_use" and .name == "SubagentHandback" then   # final answer of a background subagent
                 (.input.message // .input.result // empty | select(type == "string"))
               else empty end ]
    end;
'

# Emits every subagent of the transcript as JSON: {<launching tool_use id>: {type, desc, prompt, items}}
extract_agents() {   # $1 transcript
  local dir="${1%.jsonl}/subagents" meta log
  [ -d "$dir" ] || { echo '{}'; return; }
  for meta in "$dir"/agent-*.meta.json; do
    log="${meta%.meta.json}.jsonl"
    [ -f "$meta" ] && [ -f "$log" ] || continue
    jq -s --slurpfile m "$meta" "$JQ_DEFS"'
      [ .[] | select((.isMeta | not) and (.type == "user" or .type == "assistant")) ] as $recs
      | ([ $recs[] | select(.type == "user") | user_text | select(length > 0) ]) as $users
      | {
          tool: $m[0].toolUseId,
          type: ($m[0].agentType // "agent"),
          desc: ($m[0].description // ""),
          prompt: ($users[0] // ""),
          items: ([ $recs[] | if .type == "assistant" then (.message.content | items[])
                              else (user_text | select(length > 0) | {user: .}) end ] | .[1:]
                  | map(select(type != "string" or length > 0)))
        }
      | select(.tool != null)
    ' "$log" 2>/dev/null
  done | jq -s 'map({key: .tool, value: (del(.tool))}) | from_entries'
}

# Emits the turns as JSON: [{ts, request, responses:[item...]}]
extract_turns() {   # $1 transcript
  jq -s "$JQ_DEFS"'
    [ .[] | select((.isSidechain | not) and (.isMeta | not) and (.isCompactSummary | not))
      | if .type == "user" then
          user_text as $t
          | select($t | length > 0)
          | {role: "user", ts: .timestamp, text: $t, skip: ($t | test("^/save-claude-chat-session( |$)"))}
        elif .type == "assistant" then
          (.message.content | items) as $i
          | select($i | length > 0) | {role: "assistant", items: $i}
        else empty end ]
    | reduce .[] as $m ([];
        if $m.role == "user" then . + [{ts: $m.ts, request: $m.text, skip: $m.skip, responses: []}]
        elif length > 0 then .[-1].responses += $m.items
        else . end)
    | map(select(.skip | not) | del(.skip))
    | map(select((.request | startswith("/")) and (.responses | length) == 0 | not))   # /clear, /model, ...
  ' "$1"
}

render_conversation() {   # $1 turns, $2 agents
  jq -r --argjson agents "$2" '
    def quote: split("\n") | map("> " + .) | join("\n");
    def render_items:
      map(if type == "string" then .
          elif has("user") then "**Follow-up to the subagent:**\n\n" + (.user | quote)
          else $agents[.agent] as $a
            | if $a == null then empty else
                "<details>\n<summary>Subagent · \($a.type) · \($a.desc)</summary>\n\n"
                + "**Prompt:**\n\n" + ($a.prompt | quote) + "\n\n**Output:**\n\n"
                + (if ($a.items | length) > 0 then ($a.items | render_items) else "_No text reply._" end)
                + "\n\n</details>"
              end
          end)
      | join("\n\n");
    to_entries[] |
    "## \(.key + 1) · \(.value.ts[11:16]) UTC\n\n### Request\n\n"
    + (.value.request | quote)
    + "\n\n### Response\n\n"
    + (if (.value.responses | length) > 0 then (.value.responses | render_items) else "_No text reply._" end)
    + "\n"
  ' <<<"$1"
}

summarise() {
  local prompt="Below is a conversation between a user and Claude Code, including the output of subagents Claude launched. Write an informal summary of what happened in the session, at most 5 sentences. Output only the summary."
  ( cd "${TMPDIR:-/tmp}" && printf '%s\n\n%s' "$prompt" "$(printf '%s' "$1" | head -c 300000)" \
      | RA_SESSION_SUMMARY_CHILD=1 CLAUDECODE='' timeout 120 claude -p --model haiku --no-session-persistence 2>/dev/null )
}

write_file() {   # $1 file, $2 title, $3 date, $4 session id, $5 summary, $6 conversation
  cat >"$1" <<EOF
# Session $3 · $2

- **Session:** \`$4\`
- **Saved:** $(date -u +%Y-%m-%dT%H:%MZ)

## Summary

$5

---

$6
EOF
}

main() {
  local name="" src=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --name) name="${2:-}"; shift 2 || shift ;;
      --name=*) name="${1#--name=}"; shift ;;
      *) src="$1"; shift ;;
    esac
  done

  local transcript; transcript=$(resolve_transcript "$src")
  [ -f "$transcript" ] || { echo "save-session: no transcript found${transcript:+ at $transcript}" >&2; exit 0; }

  local id id8 saved
  id=$(basename "$transcript" .jsonl)
  id8=${id:0:8}
  saved=$(existing_file "$id8")
  if [ -n "$saved" ]; then
    echo "save-session: session $id8 is already saved as ${saved#"$root"/}; not saving it again."
    exit 0
  fi

  local turns; turns=$(extract_turns "$transcript")
  [ "$(jq length <<<"$turns")" -gt 0 ] || { echo "save-session: session $id8 has no requests to save"; exit 0; }

  local agents date stamp title slug conv file
  agents=$(extract_agents "$transcript")
  date=$(jq -r '.[0].ts[0:10]' <<<"$turns")
  stamp=$(jq -r '.[0].ts | gsub("[-:]"; "") | .[0:8] + "-" + .[9:15]' <<<"$turns")
  title=$(jq -r 'select(.type == "ai-title") | .aiTitle' "$transcript" | tail -1)
  [ -n "$title" ] || title="Untitled session"
  slug=$(slugify "$name")
  conv=$(render_conversation "$turns" "$agents")
  mkdir -p "$outdir"
  file="$outdir/$stamp${slug:+-$slug}-$id8.md"

  write_file "$file" "$title" "$date" "$id" "_Summary is being generated…_" "$conv"
  # The summary takes a model call; run it detached so the session can go on (or close) straight away.
  ( summary=$(summarise "$conv"); [ -n "$summary" ] || summary="_Summary could not be generated; write one by hand if needed._"
    write_file "$file" "$title" "$date" "$id" "$summary" "$conv" ) </dev/null >/dev/null 2>&1 &
  disown 2>/dev/null || true
  echo "save-session: wrote ${file#"$root"/}"
}

main "$@"
