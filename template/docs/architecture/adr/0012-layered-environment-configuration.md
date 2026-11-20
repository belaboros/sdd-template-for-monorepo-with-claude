# ADR-0012: Layer environment configuration: a base `.env` plus one per app

- **Status:** accepted
- **Date:** 2026-11-13
- **Origin:** foundation decision inherited from [sdd-template-for-monorepo-with-claude](https://github.com/belaboros/sdd-template-for-monorepo-with-claude); builds on ADR-0008

## Context
Every app needs some of the same settings (the Claude API key, the default model, where shared data lives, the log level), and each app needs some of its own. Copying the common values into every app drifts, and secrets end up in more files than necessary. Apps may be written in different languages, so the mechanism can't depend on one language's library.

## Decision
- The root `.env` holds the **base** variables for every app. `apps/<app>/.env` **adds** app-specific variables and may **override** base ones. Both are git-ignored; the committed `.env.example` files list every key (with safe example values) and are the source of truth for which keys exist.
- **Precedence, highest first:** variables already in the process environment (CI, container, shell) > `apps/<app>/.env` > `.env`.
- `tools/env/with-env.sh <app> -- <command>` loads the files in that order and runs the command; `--check` fails when a key from an `.env.example` is unset or empty (unless marked `# optional`); `--print` lists keys and their source, never values. It also sets `REPO_ROOT` and `APP_NAME`.
- File format: `KEY=value`, optional `export`, quotes for literal values, comments; **no interpolation and no multi-line values**. The loader never evaluates file content.
- Code that loads `.env` files itself (e.g. in tests) must give the same result: load the **most specific file first without overriding** existing variables, e.g. Python `load_dotenv(app_env); load_dotenv(root_env)` or Node `dotenv.config({ path: [appEnv, rootEnv] })`.
- Base keys: `ANTHROPIC_API_KEY`, `CLAUDE_MODEL` (default `claude-opus-5-5`), `SHARED_DATA_DIR` (ADR-0013), `LOG_LEVEL`. Adding or renaming a base key is a root-level change: update `.env.example` and the cross-cutting table in `docs/architecture/architecture.md`.

## Alternatives considered
| Option | Why not chosen |
|--------|----------------|
| One `.env` for all apps | App-specific keys of every app leak into all of them; no per-app override |
| A full `.env` per app | Shared secrets duplicated in many files; values drift |
| Language-specific loaders only (dotenv-flow, pydantic-settings) | Different behaviour per language; the shell loader works for any command |
| A secrets manager (Vault, 1Password CLI, SOPS) | Worth it for deployment; too heavy for local development. Can feed the process environment, which has the highest precedence anyway |

## Consequences
- **Positive:** the API key is set once; each app sees exactly the variables it needs; CI and containers override anything without files.
- **Negative:** apps must be started through the loader (or replicate its order); dotenv features such as interpolation are unavailable.
- **Follow-up:** `.gitignore` ignores `.env` files at every level; `.claude/settings.json` denies Claude reading them (ADR-0008).
