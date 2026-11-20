# Dataset contract: __NAME__

| | |
|---|---|
| **Description** | __TEXT__ |
| **Owner (only writer)** | `__OWNER__` |
| **Readers** | see the system map in the [root architecture](../../../docs/architecture/architecture.md) |
| **Location at runtime** | `${SHARED_DATA_DIR}/__NAME__/` (`SHARED_DATA_DIR` comes from the root `.env`) |
| **In git** | __GIT__: see `git` in the root `components.json` and `.gitignore` (ADR-0016) |
| **Contract version** | 0.1.0 (see [CHANGELOG.md](CHANGELOG.md)) |

The contract is what readers may rely on (ADR-0013). Anything not written here is an implementation detail of `__OWNER__` and may change without notice.

## Format

_Storage format (files, SQLite, a graph store, …), the layout under the location above, and the schema. Put machine-readable schemas (JSON Schema, SHACL, SQL DDL, …) next to this file._

## Guarantees

_What readers can rely on: completeness, ordering, atomic publication (e.g. "written to a temp folder, then renamed"), freshness, identifiers that never change._

## Versioning

Semantic versioning of the contract: **major** for anything that can break a reader (removed or renamed fields, changed meaning), **minor** for additions readers can ignore, **patch** for clarifications. A major change needs a root ADR and a plan for every reader listed in the system map.
