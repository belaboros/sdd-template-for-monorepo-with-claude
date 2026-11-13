# Shared runtime data

Default location of the shared datasets at runtime (`SHARED_DATA_DIR=data` in the root `.env`). Everything in this folder except this README is git-ignored: datasets can be large, can contain personal data, and are reproduced by their owning app.

Each dataset lives in `data/<dataset>/`, has exactly one owning app (its only writer) and is described by its contract in [shared/contracts/](../shared/contracts/README.md) (ADR-0013). Point `SHARED_DATA_DIR` somewhere else (an absolute path, a mounted volume) to share data between machines or containers.
