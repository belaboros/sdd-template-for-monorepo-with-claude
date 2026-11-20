---
name: save-claude-chat-session
description: Save the current Claude Code session now as docs/sessions/YYYYMMDD-HHMMSS[-name]-<id8>.md. Only when the user runs /save-claude-chat-session.
argument-hint: [name]
disable-model-invocation: true
allowed-tools: Bash(tools/sessions/save-session.sh:*)
---

The session has already been saved by the command below (ADR-0014). Its output:

!`tools/sessions/save-session.sh --name "$ARGUMENTS" ${CLAUDE_SESSION_ID}`

Report that output to the user in one line, with the file as a link. Then stop: don't run the script again, and don't edit, move or delete the file. A session is saved only once, so the `SessionEnd` hook won't save it again either. Anything said after this point stays out of the file.
