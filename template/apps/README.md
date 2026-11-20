# Applications

One folder per application (ADR-0010). Apps are loosely related: they are developed together, may use the same libraries from [../libs/](../libs/README.md) and may share data through owned datasets (ADR-0013), but they never import from each other.

The list of apps, what each one writes and reads, and the libraries it uses is the **system map** in [docs/architecture/architecture.md](../docs/architecture/architecture.md#3-system-map-applications-shared-datasets-libraries), generated from [docs/architecture/components.json](../docs/architecture/components.json).

## Add an app

Run `/scaffold app <name> "<one-sentence responsibility>"` in Claude Code, or `tools/monorepo/new.sh app <name> "<responsibility>"`. Both create:

```
apps/<name>/
├── README.md                     # what the app is, how to run it
├── CLAUDE.md                     # app-specific instructions for Claude (adds to the root CLAUDE.md)
├── .env.example                  # variables this app adds or overrides (layered over the root .env)
└── docs/
    ├── architecture/
    │   ├── architecture.md       # the app's internal architecture
    │   ├── components.json       # the app's internal components and allowed dependencies
    │   ├── adr/                  # app-level decisions, cited as <name>/ADR-NNNN
    │   └── metrics/              # app-level modularity snapshots
    └── specs/                    # specs whose scope is this app only
```

and register the app in `docs/architecture/components.json`. Source code goes in `apps/<name>/` in whatever layout the app's language uses, once `/add-language` has set up its quality gate.
