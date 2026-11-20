# Shared runtime data

Default location of the shared datasets at runtime (`SHARED_DATA_DIR=data` in the root `.env`). Each dataset lives in `data/<dataset>/`, has exactly one owning app (its only writer) and is described by its contract in [libs/contracts/](../libs/contracts/README.md) (ADR-0013). Point `SHARED_DATA_DIR` somewhere else (an absolute path, a mounted volume) to share data between machines or containers.

## In git or not (ADR-0016)

The developer decides for each `data/<dataset>/` whether it is committed. `data/` is committed by default; a dataset that must stay out of git gets a `/data/<dataset>/` line at the end of the root [.gitignore](../.gitignore). The choice is `"git": "commit"` or `"git": "ignore"` on the dataset in [docs/architecture/components.json](../docs/architecture/components.json); `tools/monorepo/new.sh dataset` asks for it and adds the `.gitignore` line, and `tools/monorepo/system-map.sh` checks that the two agree.

- **ignore** if the data is large, holds personal or confidential data, changes on every run, or its owner can rebuild it. If unsure, ignore.
- **commit** if it is small, safe to publish and a fresh clone (or CI) needs it: seed data, reference lists, fixtures.

To change the choice later, edit `git` in `components.json` and the `.gitignore` line together; when switching to `ignore`, also run `git rm -r --cached data/<dataset>` (it stays in history).
