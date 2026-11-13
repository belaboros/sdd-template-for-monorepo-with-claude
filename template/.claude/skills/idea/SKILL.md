---
name: idea
description: Capture a new idea verbatim into docs/ideas/ with a Q&A log. Use when the user brings a new feature, product, app or research idea, or runs /idea.
argument-hint: <the idea, in your own words>
---

Capture this idea: $ARGUMENTS

1. Find the next free number `NNNN` in `docs/ideas/` (4 digits, zero-padded). Ideas are always captured at the root, even if they look like they concern one app; numbers are unique across the whole repo (ADR-0011).
2. Pick a short kebab-case slug and create `docs/ideas/NNNN-slug.md` from `docs/templates/idea.md`.
3. Paste the user's text **verbatim** under `## Original idea`, as a block quote. Do not fix typos, summarise or reorder it. If the idea came over several messages, quote each one and date it.
4. Set `Status: captured`, `Scope: TBD` and today's date. If the user named an app, you may note it after `TBD` as a hint (e.g. `TBD (mentions: assistant)`); `/spec` decides.
5. Add a row to the table in `docs/ideas/README.md`.
6. If the idea refers to research (`docs/research/…`), link it under the original idea, outside the quote.
7. Do not ask clarifying questions here; that is what `/spec` is for. If you must ask something (for example, whether this duplicates an existing idea), log the question and the answer in the new file's `## Q&A log`.
8. Tell the user the file path and suggest running `/spec NNNN` in a fresh session.
