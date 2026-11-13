# ADR-0010: Develop loosely related applications together in one monorepo

- **Status:** accepted
- **Date:** 2026-11-13
- **Origin:** foundation decision inherited from [sdd-template-for-monorepo-with-claude](https://github.com/belaboros/sdd-template-for-monorepo-with-claude); builds on ADR-0005 and ADR-0006

## Context
The project is a family of applications that are related but separately useful: they serve different users or steps of a workflow, and some of them hand data to each other. A typical example is a pipeline where one app ingests and processes documents, a second answers questions from the result, and a third lets an administrator review and correct it. Developing them in separate repositories makes cross-app changes (a new field in shared data, a common library) slow and hard to keep consistent, and it splits the specs, ADRs and session history. Developing them as one application couples everything to everything.

## Decision
We will keep all applications in one repository with this layout:

| Path | Holds |
|------|-------|
| `apps/<app>/` | One application: its code, its own `CLAUDE.md`, `.env.example` and `docs/` (ADR-0011) |
| `shared/<component>/` | Shared code used by two or more apps, imported only through its `public` entry points |
| `shared/contracts/<dataset>/` | The contract for a dataset that apps share (ADR-0013) |
| `docs/` | System-level documentation for all apps (ADR-0011) |
| `tools/` | Repo-wide tooling: quality gate, env loader, scaffolding, system map |

The root `docs/architecture/components.json` declares every app (`kind: app`), every shared component (`kind: shared`) and every shared dataset, with `mayDependOn`, `reads` and `writes`. Rules:

1. **Apps never depend on each other.** An app's `mayDependOn` may list only shared components. Apps cooperate through shared datasets (ADR-0013) or, if they ever need it, through a network API documented as a contract.
2. **Shared code never depends on an app**, and the shared components form no cycle.
3. **Every app folder is registered**, and every registered unit has its folder.

`tools/monorepo/system-map.sh` checks these rules and renders the system map in `docs/architecture/architecture.md`; it runs in pre-commit and CI. `tools/monorepo/new.sh` (the `/scaffold` skill) creates apps, shared components and datasets from skeletons. The modularity metrics of ADR-0005 apply at both levels: between apps and shared components, and between the components inside each app. The language quality gate of ADR-0006 is repo-wide, and its boundary checker must also forbid imports between apps.

## Alternatives considered
| Option | Why not chosen |
|--------|----------------|
| One repository per app | Cross-app changes need coordinated PRs and releases; specs, ADRs and sessions are scattered |
| One application with modules | Apps have different users, lifecycles and possibly languages; a single deployable couples them |
| A JS/Python workspace tool (Nx, Turborepo, uv workspaces, Bazel) as the backbone | Picks a language before the first app is specified; can still be added per language through `/add-language` |
| Allowing app-to-app imports | Turns loosely related apps into one tangled application; shared needs belong in `shared/` |

## Consequences
- **Positive:** one place for every spec, decision and session; cross-app changes are one PR; loose coupling between apps is checked, not hoped for.
- **Negative:** CI runs for the whole repo on every change; a broken shared component can affect several apps at once.
- **Follow-up:** `/add-language` generates boundary rules from both the root and the app `components.json` files. Per-app CI path filters can be added when the build gets slow.
