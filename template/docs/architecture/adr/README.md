# Architecture Decision Records

These are the **root** (system-level) ADRs; decisions that concern a single app live in `apps/<app>/docs/architecture/adr/` and are cited as `<app>/ADR-NNNN` (ADR-0011). Read them in order. Each ADR records one decision: its context, the options considered and the consequences. An accepted ADR is never edited. To change a decision, write a new ADR that supersedes it, and update the old one's status line only.

New ADRs are created with `/adr` from [../../templates/adr.md](../../templates/adr.md).

| ADR | Decision | Status | Date |
|-----|----------|--------|------|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions as ADRs | accepted | 2026-11-09 |
| [0002](0002-specification-driven-development.md) | Develop through specifications | accepted | 2026-11-09 |
| [0003](0003-documentation-layout.md) | Keep all project documentation under `docs/` | superseded by [0011](0011-two-level-documentation-and-architecture.md) | 2026-11-09 |
| [0004](0004-diagrams-as-mermaid.md) | Write diagrams as Mermaid in Markdown | accepted | 2026-11-09 |
| [0005](0005-modularity-metrics.md) | Measure modularity with complexity and coupling metrics and store snapshots | accepted | 2026-11-09 |
| [0006](0006-enforce-modularity-per-language.md) | Enforce modularity rules per language, gated at the language's introduction | accepted | 2026-11-09 |
| [0007](0007-session-history-as-curated-transcripts.md) | Save session history as curated transcripts in `docs/sessions/` | superseded by [0014](0014-save-each-session-once-with-subagent-output.md) | 2026-11-09 |
| [0008](0008-security-checks-for-a-public-repository.md) | Layered security checks for a public repository | accepted | 2026-11-09 |
| [0009](0009-github-repository-protection.md) | Protect `main` and enable GitHub's security features | accepted | 2026-11-09 |
| [0010](0010-monorepo-of-loosely-coupled-applications.md) | Develop loosely related applications together in one monorepo | accepted; layout superseded by [0015](0015-libraries-in-libs-folder.md) | 2026-11-13 |
| [0011](0011-two-level-documentation-and-architecture.md) | Document the system at the root and each app in its own folder | accepted | 2026-11-13 |
| [0012](0012-layered-environment-configuration.md) | Layer environment configuration: a base `.env` plus one per app | accepted | 2026-11-13 |
| [0013](0013-shared-data-through-owned-datasets-and-contracts.md) | Share data through owned datasets with versioned contracts | accepted; contract location superseded by [0015](0015-libraries-in-libs-folder.md) | 2026-11-13 |
| [0014](0014-save-each-session-once-with-subagent-output.md) | Save each session once, on demand or at its end, including subagent output | accepted | 2026-11-20 |
| [0015](0015-libraries-in-libs-folder.md) | Keep libraries and dataset contracts in `libs/` | accepted | 2026-11-20 |
