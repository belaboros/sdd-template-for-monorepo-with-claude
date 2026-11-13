# Plan NNNN · <Title>

- **Status:** draft | approved
- **Spec:** [spec.md](spec.md)
- **Last updated:** YYYY-MM-DD

## Approach
<A short summary of the design and why this one was picked over the alternatives.>

## Alternatives considered
- <Option>: <why it was not chosen>

## Components and files
| Path | New/changed | Responsibility |
|------|-------------|----------------|

## Data and interfaces
<Data models, APIs, CLI flags, prompts: whatever the boundaries are.>

## Architecture impact
- **System level** (root `docs/architecture/components.json`, then `tools/monorepo/system-map.sh`):
  - apps / shared components / datasets added: <names, or none; created with `/scaffold`>
  - new `reads` / `writes` / `mayDependOn` edges: <app → dataset or shared component; never app → app>
  - dataset contract changes: <dataset, version bump (major = breaking, needs a root ADR and a task per reader)>
  - base environment variables added or changed: <keys in the root `.env.example`>
- **App level** (`apps/<app>/docs/architecture/components.json` and `architecture.md`):
- **Components added/changed:** <names>
- **New dependencies between components:** <A → B, each allowed by mayDependOn and acyclic>
- **ADRs:** <links to ADRs created for this plan; root `ADR-NNNN` or `<app>/ADR-NNNN`>
- **App environment variables:** <keys added to `apps/<app>/.env.example`>
- **New languages:** <none, or "/add-language X" as task T1>

## Verification map
| Acceptance criterion | How it is verified (test name / command) |
|----------------------|------------------------------------------|
| AC-1                 |                                          |

## Risks and mitigations
- <Risk> → <mitigation>

## Out of scope for this plan
- <Deferred items>
