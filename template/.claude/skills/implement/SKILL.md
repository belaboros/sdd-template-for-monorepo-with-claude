---
name: implement
description: Implement the next open tasks of an approved plan, test-first. Use when the user runs /implement.
argument-hint: <spec number, e.g. 0001> [task id]
disable-model-invocation: true
---

Implement spec `$ARGUMENTS`.

1. Find the spec folder: `docs/specs/<number>-*/` or `apps/*/docs/specs/<number>-*/`. Read `spec.md`, `plan.md` and `tasks.md`, the root `CLAUDE.md` and the `CLAUDE.md` of every app involved. If the plan is not `approved`, stop.
2. Set the idea's status to `in-progress`.
3. Take the first unticked task, or the one named in the arguments. For each task:
   - Write or extend the test that proves its acceptance criteria first, and confirm that it fails.
   - Implement just enough to make it pass. Stay inside the plan.
   - Run the task's check plus the full test suite and the quality gate (lint, complexity, boundary check; see `CLAUDE.md` Conventions). Tick the box only when they pass.
   - Run code with the app's environment: `tools/env/with-env.sh <app> -- <command>`. If a key is missing, run `tools/env/with-env.sh <app> --check` and ask the user to set it; never read `.env` files yourself.
   - Never import from another app. If you need its data, read the dataset through its contract; if you need its code, that is a plan change (move it to a library in `libs/`).
   - Never silence a complexity or boundary finding. Refactor instead: extract a function, move code to the component that owns it, or depend on a public entry point. If the fix needs a new dependency between components, a new dataset read or write, or a contract change, that is a plan change: ask, then update the `components.json` at the right level and add an ADR at the right level.
   - Make one commit per task when the user has asked for commits, with a message that names the task, e.g. `T2 (spec 0001): …`.
4. **Deviation:** if a task cannot be done as specified, or the spec turns out to be wrong, stop. Explain, ask with AskUserQuestion, log the question and answer in the idea file's `## Q&A log` (stage `implement`), update spec/plan/tasks, then continue.
5. When every task is ticked, run `/review-spec <number>`.
