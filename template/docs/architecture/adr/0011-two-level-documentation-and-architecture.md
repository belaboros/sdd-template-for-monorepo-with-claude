# ADR-0011: Document the system at the root and each app in its own folder

- **Status:** accepted
- **Date:** 2026-11-13
- **Origin:** foundation decision inherited from [sdd-template-for-monorepo-with-claude](https://github.com/belaboros/sdd-template-for-monorepo-with-claude); supersedes ADR-0003

## Context
ADR-0003 kept all documentation under one `docs/`. With several apps (ADR-0010) that folder would mix decisions about the whole system with details of one app, and a reader of one app would have to filter everything. Claude Code also reads a `CLAUDE.md` in a subfolder when it works on files there, so instructions can be layered the same way.

## Decision
Documentation has two levels.

| Level | Location | Contents |
|-------|----------|----------|
| **System (root)** | `CLAUDE.md`, `docs/` | Rules for everyone; `docs/ideas/` (all ideas, one number sequence); `docs/specs/` (specs that span apps or concern shared code or data, plus an index of **all** specs); `docs/architecture/` (system context, system map, cross-app flows, `components.json` of apps, shared code and datasets, root ADRs, system-level metrics); `docs/research/` (reports, notes, brainstorming); `docs/sessions/`; `docs/templates/` |
| **App** | `apps/<app>/CLAUDE.md`, `apps/<app>/docs/` | App-specific instructions; `docs/specs/` (specs that concern this app only); `docs/architecture/` (the app's internal architecture, its `components.json`, app ADRs, app metrics); optionally `docs/research/` |

- **Ideas** are always captured at the root. Their scope (`system` or one app) is decided by `/spec`, which then writes the spec at the matching level. Spec numbers equal idea numbers and are unique across the repo.
- **ADRs**: a decision that another app could notice (shared code, a dataset contract, a base environment variable, repo tooling, a rule for all apps) is a **root ADR**, `ADR-NNNN`. A decision inside one app is an **app ADR** in `apps/<app>/docs/architecture/adr/`, numbered separately and cited as `<app>/ADR-NNNN`.
- **Architecture documents** never repeat each other: the root shows apps as boxes and links to each app's document; an app document links up to the system map instead of copying it.
- Templates, metric definitions and thresholds exist once, at the root.

## Alternatives considered
| Option | Why not chosen |
|--------|----------------|
| Keep everything in the root `docs/` (ADR-0003) | Mixes system and app concerns; app folders can't be read on their own |
| Only app-level docs | Nowhere to record what spans apps: shared data, shared code, the overall context |
| Separate numbering of ideas per app | Ideas often span apps, and their scope isn't known when they are captured |

## Consequences
- **Positive:** each app is understandable from its own folder; system-wide decisions stay visible in one place; Claude gets the right instructions for the folder it works in.
- **Negative:** contributors must decide where a decision belongs; the skills encode the rule above, and `/review-spec` checks it.
- **Follow-up:** the skills (`/idea`, `/spec`, `/plan`, `/adr`, `/arch-metrics`, `/review-spec`) resolve paths at both levels; ADR-0003 is superseded.
