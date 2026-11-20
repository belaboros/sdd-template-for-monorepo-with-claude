---
name: review-spec
description: Independently verify an implementation against its spec's acceptance criteria using the spec-reviewer subagent. Use when the user runs /review-spec or after /implement finishes.
argument-hint: <spec number, e.g. 0001>
---

Verify spec `$ARGUMENTS`.

1. Find the spec folder (`docs/specs/$ARGUMENTS-*/` or `apps/*/docs/specs/$ARGUMENTS-*/`). Launch the `spec-reviewer` subagent with only that path. Do not pass it your own conclusions, so its review stays independent.
2. Relay its findings to the user: each acceptance criterion marked pass, fail or unverified, with evidence.
3. Run `tools/monorepo/system-map.sh --check`, then `/arch-metrics` for the system and for every app the spec touched, and relay the results and the change since the previous snapshots. A `fail` result (a cycle, a boundary violation, an app-to-app import, a second writer of a dataset, CC > 15) counts as a failed review. Check that the architecture documents and `components.json` files at both levels describe what was built, that every new decision is an ADR at the right level, and that new env variables are in the right `.env.example`.
4. If everything passes: set the spec to `implemented` and the idea to `done`, and update `docs/ideas/README.md` and `docs/specs/README.md`.
5. If anything fails: add follow-up tasks to `tasks.md`. If a fix needs a decision from the user, ask, and log the question and answer in the idea file (stage `review`).
