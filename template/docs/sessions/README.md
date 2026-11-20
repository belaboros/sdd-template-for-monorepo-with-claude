# Sessions

One file per Claude Code session (ADR-0014): a short summary, the user's requests word for word, Claude's replies, and the prompt and replies of every subagent Claude launched (in collapsible blocks). Thinking, tool calls and tool output are left out, including the subagents' ones.

- **Save now:** `/save-claude-chat-session [name]` saves the current session at once. Anything said after that call is not saved.
- **Automatically:** a session nobody saved by hand is saved when it ends (`SessionEnd` hook → [tools/sessions/save-session.sh](../../tools/sessions/save-session.sh)).
- **Saved once:** if a file for the session already exists, the command, the hook and manual runs write nothing. To save a session anew, delete its file first.
- **Manually:** `tools/sessions/save-session.sh [--name NAME] [path/to/transcript.jsonl | session-id]`. Without a transcript it uses the newest session of this project.
- File name: `YYYYMMDD-HHMMSS[-name]-<first 8 characters of the session id>.md`; the time is the session's first request, in UTC, and the name is turned into a lowercase slug.
- Review before committing. These files are history, not the source of truth: specs, ADRs and idea files take precedence.
