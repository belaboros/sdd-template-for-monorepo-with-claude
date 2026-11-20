# ADR-0013: Share data through owned datasets with versioned contracts

- **Status:** accepted; the contract location is superseded by [ADR-0015](0015-libraries-in-libs-folder.md)
- **Date:** 2026-11-13
- **Origin:** foundation decision inherited from [sdd-template-for-monorepo-with-claude](https://github.com/belaboros/sdd-template-for-monorepo-with-claude); builds on ADR-0010

## Context
Apps in this monorepo may share data: one app produces something (an index, a knowledge graph, a list of quality issues) that others read. Without rules, several apps write the same files or tables, readers depend on whatever the producer happens to write, and a change in one app silently breaks another. Because apps do not import each other (ADR-0010), shared data is their main coupling, so it needs to be as explicit as code dependencies.

## Decision
- A **dataset** is any data that more than one app uses. Each dataset is declared in the root `components.json` (`datasets`) with exactly one **owner** app, its **only writer**. Other apps declare it in `reads`.
- Its **contract** lives in `shared/contracts/<dataset>/`: format, schema, location layout, guarantees (e.g. atomic publication), and a semantic version with a `CHANGELOG.md`. Readers rely only on the contract. Machine-readable schemas sit next to it.
- At runtime the data lives in `${SHARED_DATA_DIR}/<dataset>/` (`SHARED_DATA_DIR` from the base `.env`, default `data/` at the repo root, git-ignored). Datasets are reproducible by their owner, so they are not committed.
- A **breaking** contract change is a major version, needs a root ADR, and its plan lists the change for every reader. Each reader has a contract test against the schema.
- Data that only one app uses is that app's private data and stays out of this mechanism.

`tools/monorepo/system-map.sh` enforces one writer per dataset and the existence of each contract, and draws the data flow in the system map.

## Alternatives considered
| Option | Why not chosen |
|--------|----------------|
| Apps read each other's internal files or tables freely | Hidden coupling; any internal change can break another app |
| A shared database owned by nobody | Unclear responsibility for schema changes and data quality |
| Apps call each other's APIs for all data | Requires every producer to run a service; heavier than needed for batch-style hand-offs. Still possible later, documented as a contract |
| Shared data committed to git | Size, personal data in a possibly public repository, merge conflicts |

## Consequences
- **Positive:** every cross-app data dependency is declared, visible in the system map, and protected by a versioned contract.
- **Negative:** a contract and a changelog to maintain per dataset; a second writer needs a redesign (split the dataset, or move the writing into the owner).
- **Follow-up:** datasets may contain personal data; keep it out of session transcripts and the repository (ADR-0007, ADR-0008). If needed, add `Read(./data/**)` to the deny list in `.claude/settings.json`.
