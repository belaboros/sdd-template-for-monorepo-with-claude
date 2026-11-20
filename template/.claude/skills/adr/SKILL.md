---
name: adr
description: Record an architecture decision as a new ADR, at system level (docs/architecture/adr/) or for one app (apps/<app>/docs/architecture/adr/). Use when a plan or implementation makes an architecturally significant decision (structure, component boundaries, technology, external dependency, cross-cutting concern, quality thresholds, shared data or contracts), or when the user runs /adr.
argument-hint: [--app <name>] <decision title> [supersedes NNNN]
---

Record the decision: $ARGUMENTS

1. **Pick the level** (ADR-0011). Root (`docs/architecture/adr/`) if another app could notice the decision: shared code, a dataset or its contract, a base environment variable, repo tooling or rules, a new app. App (`apps/<app>/docs/architecture/adr/`) if it stays inside one app. `--app <name>` asks for the app level; if it looks like a root decision anyway, say so and ask.
2. Find the next free number in that folder (4 digits). Root and each app number separately; cite app ADRs as `<app>/ADR-NNNN`.
3. Create `NNNN-slug.md` from `docs/templates/adr.md` and set its `Scope:`. Write the Context so that an average engineer with no chat history understands why a decision was needed. List the real alternatives that were considered.
4. Status: `accepted` if the user has already agreed (log that question in the idea's Q&A log); otherwise `proposed`, and ask.
5. If it supersedes an earlier ADR, change **only** the old ADR's status line to `superseded by ADR-NNNN` (or `<app>/ADR-NNNN`). Never edit the rest of an accepted ADR.
6. Add a row to the `README.md` index in the same folder.
7. Carry out the follow-ups the ADR lists in the same change: `architecture.md` and `components.json` at the right level (then `tools/monorepo/system-map.sh` for root changes), contracts, `.env.example` files, thresholds in `metrics/README.md`, or tooling.
