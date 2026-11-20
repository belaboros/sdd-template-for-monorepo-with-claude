# ADR-0016: Decide per dataset whether `data/<dataset>/` is committed or git-ignored

- **Status:** accepted
- **Scope:** system
- **Date:** 2026-11-20
- **Related:** supersedes "datasets are not committed" in [ADR-0013](0013-shared-data-through-owned-datasets-and-contracts.md); its other decisions stay in force. Builds on ADR-0008.

## Context
ADR-0013 git-ignored everything under `data/` except its README, because datasets can be large, can hold personal data, and can be rebuilt by their owner. That is not true of every dataset. Some are small and hand-curated (seed data, reference lists, test fixtures, a vocabulary), cannot be rebuilt by running the owner, or are needed by a fresh clone and by CI. Forcing them out of git makes them hard to share and easy to lose.

## Decision
We will let the developer decide, for each sub-directory of `data/`, whether it is committed:

- **Committed by default.** `.gitignore` no longer ignores `data/`.
- **Ignored by exception.** A `data/<dataset>/` that must stay out of git gets its own `/data/<dataset>/` line in the shared-data section at the end of the root `.gitignore`.
- **Recorded.** Each dataset in the root `components.json` has `"git": "commit"` or `"git": "ignore"`, and its contract shows it. `tools/monorepo/new.sh dataset <name> <owner> <commit|ignore>` requires the choice and adds the `.gitignore` line for `ignore`. `tools/monorepo/system-map.sh` fails if a dataset has no choice, or if `.gitignore` doesn't match it.
- **Ignore** when the data is large, holds personal or confidential data, changes on every run, or the owner can rebuild it. **Commit** when it is small, safe to publish, and a fresh clone needs it. If unsure, ignore.
- Committed data goes through the same hooks as code (gitleaks, ADR-0008). A dataset that moves to `SHARED_DATA_DIR` outside the repo is not affected by `.gitignore` at all.

## Alternatives considered
| Option | Pros | Cons | Why not chosen |
|--------|------|------|----------------|
| Keep everything ignored (ADR-0013) | Personal or large data can't be committed by accident | Small, curated data can't be shared through git | Too strict for seed and reference data |
| Ignore by default, `!/data/<dataset>/` exceptions to commit | Safe default | The "safe" choice is never made explicitly; negated patterns are easy to get wrong | We want an explicit decision per dataset, written where it is checked |
| Commit everything | Simplest | Large or personal data ends up in a possibly public repository | Unsafe |

## Consequences
- **Positive:** each dataset's place in git is a visible, checked decision; small datasets travel with the code and reach CI.
- **Negative / trade-offs:** a new folder in `data/` that is not a registered dataset is committable by default, so look at `git status` before committing; an ignored dataset that was committed earlier stays in history until removed with `git rm -r --cached`.
- **Follow-up:** projects generated before this ADR: add `"git": "ignore"` to each dataset in `docs/architecture/components.json`, replace the `/data/*` and `!/data/README.md` lines in `.gitignore` with one `/data/<dataset>/` line per dataset, then run `tools/monorepo/system-map.sh`.
