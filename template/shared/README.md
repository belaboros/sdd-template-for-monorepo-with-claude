# Shared

What the applications in [../apps/](../apps/README.md) have in common (ADR-0010, ADR-0013):

| Folder | Holds | Created with |
|--------|-------|--------------|
| `shared/<component>/` | Shared code: a library several apps import through its public entry points. Shared code never imports from an app. | `/scaffold shared <name>` |
| [`shared/contracts/<dataset>/`](contracts/README.md) | The contract for a shared dataset: format, schema, guarantees, version, owner. The data itself lives under `${SHARED_DATA_DIR}`, not in git. | `/scaffold dataset <name> <owner-app>` |

Everything here is registered in [docs/architecture/components.json](../docs/architecture/components.json). Add shared code only when two or more apps actually need it; duplicating a little code is cheaper than coupling apps through a library that has to serve everyone.
