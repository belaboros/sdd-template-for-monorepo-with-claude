---
name: plan
description: Produce plan.md and tasks.md for an approved spec, at the spec's level (system or app). Use when the user runs /plan.
argument-hint: <spec number, e.g. 0001>
disable-model-invocation: true
---

Create the technical plan for spec `$ARGUMENTS`.

1. Find the spec: `docs/specs/$ARGUMENTS-*/spec.md` or `apps/*/docs/specs/$ARGUMENTS-*/spec.md` (exactly one exists). Read it and its idea file (including the Q&A log). If the spec is not `approved`, stop and say so. Plans and tasks go in the same folder as the spec.
2. Explore the codebase before you design anything; use an Explore subagent for wide searches. Do not write code in this stage. Read the root `CLAUDE.md` and, for every app involved, `apps/<app>/CLAUDE.md`.
3. Write `plan.md` from `docs/templates/plan.md`. Compare at least two approaches when the choice is not obvious. Fill in the **Verification map** so that every acceptance criterion has a concrete test or command.
4. Write `tasks.md` from `docs/templates/tasks.md`: small, ordered tasks, each tagged with the acceptance criteria it covers and the check that proves it. Prefix tasks with the app they touch when several apps are involved (e.g. `T3 · [assistant] …`).
5. If a design choice really belongs to the user, ask with AskUserQuestion and log each question and answer in the idea file's `## Q&A log` (stage `plan`).
6. If planning shows the spec is wrong or incomplete, propose the spec change, ask, log it, and update `spec.md` before you continue.
7. **Architecture, at both levels** (ADR-0010, ADR-0011, ADR-0013). Read the root `architecture.md`, `components.json` and ADRs, and the same files of every app involved. In the plan:
   - **System level.** New apps, libraries or datasets are created with `/scaffold` (make that a task, or do it now if the user agrees). New `reads`, `writes` and `mayDependOn` edges go in the root `components.json`; never an app-to-app dependency. A dataset contract change gets a version bump; a breaking one gets a root ADR and a task for every reader. New base env variables go in the root `.env.example`. Run `tools/monorepo/system-map.sh`.
   - **App level.** Place every new piece of code in an existing component of the app, or add one with a one-sentence responsibility (if you need "and", split it). Keep dependencies acyclic and pointing towards more stable components. Update the app's `components.json` and diagrams in its `architecture.md`. App-only env variables go in `apps/<app>/.env.example`.
   - Record every architecturally significant decision with `/adr` at the right level (root if another app could notice it, else `--app <app>`), and link the ADRs from `plan.md`.
   - If the plan needs a language that isn't in `tools/quality/languages.json`, make the first task `/add-language <lang>`.
8. If this plan picks the tech stack or the build/test/run commands, add them to the Conventions of the root `CLAUDE.md` (repo-wide) or to the `## Commands` section of `apps/<app>/CLAUDE.md` (one app).
9. Ask the user to approve the plan (log it). Then set the plan to `approved`, the idea to `planned`, update `docs/ideas/README.md` and `docs/specs/README.md`, and suggest `/implement NNNN` in a fresh session.
