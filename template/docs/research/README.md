# Research

Background work that informs ideas and specs but is not itself a requirement (ADR-0011).

| Folder | Holds |
|--------|-------|
| `reports/` | Finished research reports, one Markdown file per topic (e.g. the output of a deep-research session) |
| `notes/<topic>/` | Supporting notes and sources behind a report |
| `brainstorming/` | Curated brainstorming transcripts: `YYYYMMDD-HHMMSS-brainstorming.md` |

Research that concerns a single app can live in `apps/<app>/docs/research/` with the same layout. Link reports from the ideas and specs they inform. Research files are evidence, not decisions: specs and ADRs take precedence, and the figures they quote should be re-checked before they drive a decision.
