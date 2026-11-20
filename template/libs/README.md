# Libraries

Source code that applications in [../apps/](../apps/README.md) and other libraries import or call (ADR-0010, ADR-0015), plus the contracts of the datasets apps share (ADR-0013):

| Folder | Holds | Created with |
|--------|-------|--------------|
| `libs/<lib>/` | A library: source code that apps and other libraries import or call through its public entry points. A library never imports from an app, and libraries form no dependency cycle. | `/scaffold lib <name>` |
| [`libs/contracts/<dataset>/`](contracts/README.md) | The contract of a shared dataset: owner, format, schema, version. The data itself lives under `${SHARED_DATA_DIR}`, not in git. | `/scaffold dataset <name> <owner-app>` |

Everything here is registered in [docs/architecture/components.json](../docs/architecture/components.json): libraries with `kind: "lib"`, contracts under `datasets`. A user of a library (app or library) lists it in its `mayDependOn`. Add a library only when two or more units actually need the code; duplicating a little code is cheaper than coupling apps through a library that has to serve everyone. `contracts` is reserved and can't be a library name.
