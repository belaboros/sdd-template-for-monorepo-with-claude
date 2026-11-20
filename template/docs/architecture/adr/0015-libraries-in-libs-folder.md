# ADR-0015: Keep libraries and dataset contracts in `libs/`

- **Status:** accepted
- **Scope:** system
- **Date:** 2026-11-20
- **Related:** supersedes the `shared/` layout of [ADR-0010](0010-monorepo-of-loosely-coupled-applications.md) and the contract location of [ADR-0013](0013-shared-data-through-owned-datasets-and-contracts.md); their other decisions stay in force

## Context
ADR-0010 put shared code in `shared/<component>/` (`kind: shared`) and ADR-0013 put dataset contracts in `shared/contracts/<dataset>/`. "Shared" says *that* something is used by several units, not *what* it is, and it collides with "shared data" (`SHARED_DATA_DIR`, which is runtime data and not in git). It also left open whether shared code may use other shared code. `libs/` is the name most monorepo tools and readers expect for reusable source code.

## Decision
We will replace the `shared/` folder with `libs/`:

| Path | Holds |
|------|-------|
| `libs/<lib>/` | A **library**: source code that apps **and other libraries** import or call, only through its `public` entry points |
| `libs/contracts/<dataset>/` | The contract of a shared dataset: owner, format, schema, version, with a `CHANGELOG.md` (ADR-0013's rules unchanged) |

- In `components.json` a library has `kind: "lib"` (was `shared`). Any app or library may list libraries in `mayDependOn`; nothing may list an app.
- A library never depends on an app and never declares `reads` or `writes` (only apps own or read datasets), and libraries form no cycle.
- `contracts` is reserved and can't be a library name. Contract folders hold no code; typed access to a dataset is a library.
- `/scaffold lib <name>` (`tools/monorepo/new.sh lib`) replaces `/scaffold shared`; `tools/monorepo/system-map.sh` checks `libs/<lib>/` and `libs/contracts/<dataset>/README.md`.
- `SHARED_DATA_DIR` and the runtime `data/` folder keep their names: they are about shared *data*, not about this folder.

## Alternatives considered
| Option | Pros | Cons | Why not chosen |
|--------|------|------|----------------|
| Keep `shared/` | No change | Vague name; easily confused with shared runtime data | Says nothing about what the folder holds |
| `libs/` for code, contracts in a separate top-level `contracts/` | Contracts clearly not code | One more top-level folder; contracts are what apps build against, like library interfaces | Contracts sit next to the code that depends on them |
| `packages/` | Common in JS workspaces | Language-specific connotation | Template stays language-neutral (ADR-0006) |

## Consequences
- **Positive:** a clear name for reusable code; library-to-library use is explicit and cycle-checked; contracts stay one level from the code that uses them.
- **Negative / trade-offs:** projects already generated with `shared/` need a one-off move (`git mv shared libs`, `kind: shared` → `lib` in `components.json`, then `tools/monorepo/system-map.sh`) and new boundary rules from `/add-language`.
