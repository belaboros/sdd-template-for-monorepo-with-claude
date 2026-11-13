---
name: spec
description: Interview the user about a captured idea, decide its scope (system or one app), and write the spec at the matching level. Use when the user runs /spec or asks to turn an idea into a specification.
argument-hint: <idea number, e.g. 0001>
disable-model-invocation: true
---

Turn idea `$ARGUMENTS` into an approved specification by interviewing the user.

## 1. Read
- Read `docs/ideas/$ARGUMENTS-*.md` in full, including the earlier Q&A log, so you never repeat a question that was already answered.
- Read the system map in `docs/architecture/architecture.md` and `docs/architecture/components.json`, the specs index `docs/specs/README.md`, and any linked research. Skim the apps and specs this might overlap with or depend on.
- Set the idea's status to `specifying`.

## 2. Interview
Use AskUserQuestion. Ask about things the user may not have thought through: the real users and their scenarios, scope and non-goals, edge cases and failure modes, data sources, constraints (cost, privacy, latency), what "done" looks like, and tradeoffs. Skip the obvious questions. Ask 1–4 related questions per round and keep going until the open questions are resolved or the user says stop.

**Always settle the scope** (ADR-0011): does this concern one existing app, a new app, or the system (several apps, shared code, a shared dataset or its contract, base environment variables, repo tooling)? Ask which datasets it reads or writes and whether another app depends on what changes. Propose the answer you think fits and let the user confirm.

**After every answer, before your next question,** append each question to the idea file's `## Q&A log` using the format in the template: date, stage `spec`, the question exactly as asked, the options offered, the user's answer verbatim, and its effect. That log is a permanent record and nothing in it gets removed.

## 3. Write
- Location by scope: one app → `apps/<app>/docs/specs/NNNN-slug/spec.md`; system → `docs/specs/NNNN-slug/spec.md`. Same number and slug as the idea. If the scope is a **new app**, the spec lives at the root until `/plan` scaffolds the app; then move it into the app.
- Create it from `docs/templates/spec.md`. Write behaviour, not implementation. Every acceptance criterion must be testable and must link to a requirement ID. Fill in "Apps and shared data affected".
- Anything still unresolved goes under `## Open questions`.
- Set the idea's `Scope:` line.

## 4. Approve
Show the user a short summary (the scope, the goals, the must-have requirements and the open questions) and ask for approval. Log that question too. Once it is approved, set the spec to `approved` and the idea to `specified`, update `docs/ideas/README.md` (scope, status) and add the spec to `docs/specs/README.md` (the index of all specs), and suggest `/plan NNNN` in a fresh session.
