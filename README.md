# sdd-template-for-monorepo-with-claude

A [Copier](https://copier.readthedocs.io/) template for a **monorepo of loosely related applications**, built with **specification-driven development in Claude Code**. It extends [sdd-template-for-claude](https://github.com/belaboros/sdd-template-for-claude) with:

- several apps in one repository;
- libraries (shared source code) and shared data between them;
- a layered `.env`;
- documentation and architecture at two levels: the system and each app.

## What a new project gets

```
<project>/
├── CLAUDE.md                  # rules for the whole repo
├── .env.example               # base env for every app: ANTHROPIC_API_KEY, CLAUDE_MODEL, SHARED_DATA_DIR, LOG_LEVEL
├── apps/
│   └── <app>/
│       ├── CLAUDE.md          # app-specific rules (Claude Code loads it when working in the folder)
│       ├── .env.example       # keys this app adds or overrides
│       └── docs/
│           ├── specs/         # specs that concern this app only
│           └── architecture/  # the app's architecture.md, components.json, adr/, metrics/
├── libs/
│   ├── <lib>/                 # library: source code apps and other libs import, only through public entry points
│   └── contracts/<dataset>/   # contract of a shared dataset: owner, format, schema, version
├── data/                      # default SHARED_DATA_DIR (git-ignored)
├── docs/                      # system level
│   ├── ideas/                 # every idea, verbatim, with a Q&A log (one number sequence)
│   ├── specs/                 # cross-app specs + the index of all specs
│   ├── architecture/          # system architecture.md (generated system map), components.json, root ADRs, metrics
│   ├── research/              # reports, notes, brainstorming transcripts
│   ├── sessions/              # saved Claude Code sessions
│   └── templates/
└── tools/
    ├── env/with-env.sh        # run a command with the layered environment of an app
    ├── monorepo/              # new.sh (scaffold) + system-map.sh (check rules, render the map)
    ├── quality/               # language registry + quality-gate hook
    └── sessions/              # session saver
```

| Area | Contents |
|------|----------|
| **Monorepo** (ADR-0010, ADR-0015) | `apps/`, `libs/`, `libs/contracts/`. The root `components.json` declares apps, libraries and datasets. `tools/monorepo/system-map.sh` enforces the rules in pre-commit and CI: no app-to-app dependencies, no cycles between libraries, every folder registered. It also renders the system map (Mermaid diagram + tables) into `docs/architecture/architecture.md`. `/scaffold app|lib|dataset` creates new units from skeletons. |
| **Shared data** (ADR-0013, ADR-0015) | Each dataset has one owning app, its only writer. Readers rely on a versioned contract in `libs/contracts/<dataset>/`. Runtime data lives in `${SHARED_DATA_DIR}`, which is git-ignored. |
| **Layered env** (ADR-0012) | Root `.env` is the base; `apps/<app>/.env` adds or overrides keys. Precedence: process env > app `.env` > root `.env`. `tools/env/with-env.sh <app> -- <cmd>` runs a command with that environment. `--check` reports missing keys; `--print` shows each key's source, never its value. The loader never `eval`s anything and runs on bash 3.2. |
| **Two-level docs** (ADR-0011) | The system level sits at the root, each app in `apps/<app>/docs/`. Ideas are always captured at the root; `/spec` decides the scope and writes the spec at the matching level. Root ADRs are `ADR-NNNN`; app ADRs are `<app>/ADR-NNNN`. Nested `CLAUDE.md` files layer the instructions. |
| **Workflow** | `/idea` → `/spec` → `/plan` → `/implement` → `/review-spec`, plus `/adr`, `/scaffold`, `/arch-metrics`, `/add-language`, and a `spec-reviewer` subagent. Original ideas are stored verbatim, with a Q&A log of every question. |
| **Modularity** | Complexity and coupling metrics at system level (apps and libraries) and at app level. A hook blocks code in any language that has no quality gate yet; `/add-language` generates boundary rules from both levels. |
| **Session history and security** | Inherited unchanged: curated session transcripts; gitleaks, shellcheck and zizmor in pre-commit and CI; Dependabot; branch protection via `tools/bootstrap-github.sh`. Claude is denied reading `.env` files at every level. |

## Start a new project

Prerequisites: `brew install copier gitleaks pre-commit gh jq` (or `uv tool install copier`), and `gh auth login`.

```bash
copier copy --trust gh:belaboros/sdd-template-for-monorepo-with-claude my-project
cd my-project
git add -A && git commit -m "Initial project from sdd-template-for-monorepo-with-claude"
gh repo create belaboros/my-project --public --source . --push
tools/bootstrap-github.sh          # branch protection + security settings (once)
cp .env.example .env               # set ANTHROPIC_API_KEY; never commit .env
```

Copier asks for:

- the project name, repository name, description and GitHub owner;
- the visibility and the license;
- optionally, the apps to create straight away (`initial_apps`, e.g. `downloader,assistant,reviewer`).

`--trust` lets it run its setup tasks: `git init`, `chmod`, scaffolding the initial apps, and `pre-commit install`.

Then open Claude Code in the project and run `/idea <your first idea>`.

### Example: a family of domain-assistant apps

Three apps share the results of processing user manuals:

```bash
copier copy --trust -d initial_apps=downloader,assistant,reviewer gh:belaboros/sdd-template-for-monorepo-with-claude domain-assistants
# in Claude Code:
/scaffold dataset knowledge-graph downloader "Glossary, ontology and knowledge graph built from the manuals"
/scaffold dataset quality-issues downloader "Gaps, contradictions and terminology drift found in the manuals"
# then let assistant and reviewer read both datasets (components.json "reads") and run tools/monorepo/system-map.sh
```

The downloader is the only writer of both datasets. The assistant and the reviewer read them through their contracts. The system map shows the flow, and any second writer or app-to-app import fails the checks.

## Pull template improvements into an existing project

```bash
git switch -c chore/template-update
copier update --trust              # to the latest tag; resolves conflicts as inline markers
tools/monorepo/system-map.sh       # re-render the system map if architecture.md conflicted
pre-commit run --all-files
# review the diff, commit, open a PR
```

Copier remembers your answers and the template version in `.copier-answers.yml`. A project generated from [sdd-template-for-claude](https://github.com/belaboros/sdd-template-for-claude) can move to this template with `copier copy --trust gh:belaboros/sdd-template-for-monorepo-with-claude .`. Review every overwrite, and move existing code into `apps/<app>/` with `/scaffold app <app>`.

## Developing the template

- Template files live in [template/](template/). Files ending in `.jinja` are rendered; everything else is copied verbatim. App, library and dataset skeletons are in [template/tools/monorepo/skeletons/](template/tools/monorepo/skeletons/) and use `__NAME__`-style placeholders, not Jinja, because they are filled in when an app is created, not when the project is generated. Questions and tasks are defined in [copier.yml](copier.yml).
- Test locally:

  ```bash
  copier copy --trust --defaults -d project_name=Demo -d initial_apps=a,b . /tmp/demo
  (cd /tmp/demo && git add -A && pre-commit run --all-files)
  tests/monorepo-smoke.sh /tmp/demo
  ```
- CI (`template-test.yml`) generates projects in several variants. On every PR it runs their hooks and [tests/monorepo-smoke.sh](tests/monorepo-smoke.sh), which covers scaffolding, rule violations, env precedence and gitignore.
- Release: merge to `main`, then tag `vX.Y.Z` (semver); `copier update` uses the latest tag. A breaking change (renamed files, new required answers) is a major version.
- Changes to the foundation decisions go in `template/docs/architecture/adr/` as new, superseding ADRs.

## License

[Apache-2.0](LICENSE)
