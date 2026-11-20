# ADR-0014: Save each session once, on demand or at its end, including subagent output

- **Status:** accepted
- **Scope:** system
- **Date:** 2026-11-20
- **Related:** supersedes [ADR-0007](0007-session-history-as-curated-transcripts.md)

## Context
ADR-0007 saves each session as a curated transcript when the session ends. In practice that left three gaps:
- A session can't be saved at a chosen moment or given a meaningful name.
- A lot of the work happens in subagents (research, reviews), and ADR-0007 left their messages out, so a saved session often showed only "the agents are done" without their findings.
- Saving more than once (by hand mid-session, then again by the `SessionEnd` hook) overwrote or duplicated files and changed history that might already have been reviewed or committed.

## Decision
We will keep ADR-0007's format and extraction with `jq` (summary, requests verbatim, text replies only; no thinking, tool calls, tool output or injected context), and change the following:
1. **On demand:** `/save-claude-chat-session [name]` saves the current session right away. The file is `docs/sessions/YYYYMMDD-HHMMSS[-name]-<id8>.md`, where the time is the session's first request in UTC and `name` is turned into a lowercase slug. The `SessionEnd` hook still saves sessions nobody saved by hand, without a name.
2. **Subagent output:** each subagent's prompt and text replies, including a background agent's final hand-back message, go in a collapsible `<details>` block right after the reply that launched it. Nested subagents are nested the same way. Their tool calls and tool output are left out, as in the main conversation.
3. **Saved once:** `tools/sessions/save-session.sh` writes nothing if a file ending in `-<id8>.md` already exists. The guard is in the script, so it holds for the command, the hook and manual runs alike. To save a session anew, delete its file first.
4. **Left out as well:** the `/save-claude-chat-session` call itself, and slash commands that got no reply (`/clear`, `/model`, ...).

## Alternatives considered
| Option | Pros | Cons | Why not chosen |
|--------|------|------|----------------|
| Overwrite on every save (ADR-0007) | File always has the complete history | Silently changes reviewed or committed history; manual and hook saves race | The user wants each session saved once |
| Refuse duplicates in the skill's instructions only | No script change | Relies on the model; the hook and manual runs bypass it | Not deterministic |
| Subagent output as links to the raw subagent JSONL | Small files | Raw transcripts hold tool output and possible secrets; they live outside the repo | Same reasons as in ADR-0007 |

## Consequences
- **Positive:** sessions can be saved at a meaningful point under a readable name. Research done by subagents is kept. A session file never changes behind the reviewer's back.
- **Negative / trade-offs:** anything said after `/save-claude-chat-session` is not saved. Files with many subagents get longer, and subagent replies can quote fetched web content, so review them before pushing, as with ADR-0007.
- **Follow-up:** `docs/sessions/README.md` and `CLAUDE.md` describe the command. ADR-0007's status line now points here.
