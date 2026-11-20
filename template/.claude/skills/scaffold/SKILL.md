---
name: scaffold
description: Create a new application, library or shared dataset in the monorepo from the skeletons, register it in docs/architecture/components.json and regenerate the system map. Use when the user runs /scaffold, or when a plan needs a new app, library or dataset.
argument-hint: app <name> ["responsibility"] | lib <name> ["responsibility"] | dataset <name> <owner-app> <commit|ignore> ["description"]
---

Scaffold: $ARGUMENTS

1. **Check the fit** (ADR-0010, ADR-0013, ADR-0015). Read `docs/architecture/components.json` and the system map in `docs/architecture/architecture.md`.
   - **app**: a separately useful application with its own users or workflow step. If it is really a part of an existing app, say so and stop.
   - **lib**: source code that at least two units (apps or libraries) need *now*. One user is not enough; say so and suggest keeping it where it is. The name `contracts` is reserved.
   - **dataset**: data that more than one app uses, with exactly one owning app (its only writer). If two apps need to write it, propose splitting it, and ask. Also settle whether `data/<name>/` is committed (ADR-0016): **ignore** if it is large, holds personal or confidential data, changes on every run or can be rebuilt by the owner; **commit** if it is small, safe to publish and a fresh clone needs it. This is the developer's decision: propose one with the reason, and ask unless the plan or the user already says.
   If the name, the responsibility, the owner or the git choice is missing or unclear, ask (one round, AskUserQuestion) and log the question in the related idea's Q&A log (stage `scaffold`) when there is one.
2. **Create it:** run `tools/monorepo/new.sh <kind> <name> [...]` with a one-sentence responsibility (if it needs "and", it is probably two things). The script copies the skeleton, registers the unit and regenerates the system map; for a dataset it records the git choice and, for `ignore`, adds `/data/<name>/` to `.gitignore`.
3. **Wire it up** in `docs/architecture/components.json`, as the plan or the user says:
   - readers of a dataset: add the dataset to each reader app's `reads`;
   - users of the library (apps or other libraries): add it to their `mayDependOn`; list its entry points in `public` once they exist.
   Then run `tools/monorepo/system-map.sh` and fix anything it reports.
4. **Fill in what the skeleton can't know:** for a dataset, the format, guarantees and schema in `libs/contracts/<name>/README.md` (ask the owner app's spec or the user; leave `_TBD_` rather than invent). For an app, its purpose in `apps/<name>/docs/architecture/architecture.md` §1.
5. **Record the decision.** A new app, a new dataset or a new library changes the system, so add a root ADR with `/adr` unless the current plan already has one that covers it. Add any new base env variable to the root `.env.example`, any app-only variable to `apps/<name>/.env.example`.
6. Report what was created and what is still `_TBD_`. Suggest `/idea` or `/spec` for the new app's first feature if none exists.
