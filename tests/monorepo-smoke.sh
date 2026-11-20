#!/usr/bin/env bash
# Smoke test of the monorepo tooling in a project generated from this template.
# Usage: tests/monorepo-smoke.sh <generated-project-dir>
# Works on a throwaway copy, so the generated project itself is left unchanged.
set -euo pipefail

src="$(cd "${1:?usage: $0 <generated-project-dir>}" && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
cp -R "$src/." "$work/"
cd "$work"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok: $*"; }
expect_fail() { if "$@" >/dev/null 2>&1; then fail "expected failure: $*"; fi; }

tools/monorepo/system-map.sh --check >/dev/null || fail "fresh project: system map check"
ok "fresh project passes the system map check"

# --- scaffolding and the system map ---
for app in smoke-writer smoke-reader; do
  [ -d "apps/$app" ] || tools/monorepo/new.sh app "$app" "Smoke-test app $app." >/dev/null
done
tools/monorepo/new.sh dataset smoke-data smoke-writer ignore "Data handed from writer to reader." >/dev/null
tools/monorepo/new.sh dataset smoke-seed smoke-writer commit "Small reference data, committed." >/dev/null
tools/monorepo/new.sh lib smoke-lib "Code both smoke apps use." >/dev/null
tools/monorepo/new.sh lib smoke-base "Code smoke-lib builds on." >/dev/null
jq '.components |= map(if .name == "smoke-reader" then .reads = ["smoke-data"] | .mayDependOn = ["smoke-lib"]
                       elif .name == "smoke-lib" then .mayDependOn = ["smoke-base"] else . end)' \
  docs/architecture/components.json >tmp.json && mv tmp.json docs/architecture/components.json
expect_fail tools/monorepo/system-map.sh --check                      # block is stale now
tools/monorepo/system-map.sh >/dev/null
tools/monorepo/system-map.sh --check >/dev/null || fail "system map after render"
grep -q 'ds_smoke_data -. read by .-> app_smoke_reader' docs/architecture/architecture.md || fail "data flow edge not rendered"
grep -q 'lib_smoke_lib -- uses --> lib_smoke_base' docs/architecture/architecture.md || fail "lib -> lib edge not rendered"
[ -f apps/smoke-reader/CLAUDE.md ] && [ -f libs/contracts/smoke-data/README.md ] && [ -f libs/smoke-lib/README.md ] && [ ! -e shared ] || fail "skeleton files"
! grep -rl '__NAME__\|__TEXT__\|__OWNER__\|__DATE__' apps libs >/dev/null || fail "unreplaced skeleton placeholders"
ok "scaffold app/lib/dataset, render and check the system map"

cp docs/architecture/components.json good.json
jq '.components |= map(if .name == "smoke-reader" then .mayDependOn = ["smoke-writer"] else . end)' good.json >docs/architecture/components.json
expect_fail tools/monorepo/system-map.sh --check
jq '.components |= map(if .name == "smoke-reader" then .writes = ["smoke-data"] | .reads = [] else . end)' good.json >docs/architecture/components.json
expect_fail tools/monorepo/system-map.sh --check
cp good.json docs/architecture/components.json; mkdir apps/unregistered
expect_fail tools/monorepo/system-map.sh --check
rmdir apps/unregistered
jq '.components |= map(if .name == "smoke-base" then .mayDependOn = ["smoke-lib"] else . end)' good.json >docs/architecture/components.json
expect_fail tools/monorepo/system-map.sh --check                      # lib cycle
jq '.components |= map(if .name == "smoke-lib" then .mayDependOn = ["smoke-reader"] else . end)' good.json >docs/architecture/components.json
expect_fail tools/monorepo/system-map.sh --check                      # lib -> app
cp good.json docs/architecture/components.json; rm good.json
expect_fail tools/monorepo/new.sh lib contracts
expect_fail tools/monorepo/new.sh app smoke-writer
expect_fail tools/monorepo/new.sh app Bad_Name
expect_fail tools/monorepo/new.sh dataset other-data no-such-app ignore
expect_fail tools/monorepo/new.sh dataset other-data smoke-writer
expect_fail tools/monorepo/new.sh dataset other-data smoke-writer maybe
cp .gitignore good.gitignore
grep -vxF '/data/smoke-data/' good.gitignore >.gitignore
expect_fail tools/monorepo/system-map.sh --check                      # ignore without .gitignore line
cp good.gitignore .gitignore; echo '/data/smoke-seed/' >>.gitignore
expect_fail tools/monorepo/system-map.sh --check                      # commit, but listed in .gitignore
cp good.gitignore .gitignore; rm good.gitignore
cp docs/architecture/components.json good.json
jq '.datasets |= map(del(.git))' good.json >docs/architecture/components.json
expect_fail tools/monorepo/system-map.sh --check                      # no git decision
cp good.json docs/architecture/components.json; rm good.json
ok "rule violations are rejected (app->app, lib->app, lib cycle, second writer, unregistered app, bad and reserved names, git choice)"

# --- layered environment ---
printf 'ANTHROPIC_API_KEY=base-key\nCLAUDE_MODEL=base-model\nSHARED_DATA_DIR=data\nLOG_LEVEL=info   # comment\n' >.env
printf 'CLAUDE_MODEL=app-model\nREADER_ONLY="a # b"\n' >apps/smoke-reader/.env
# shellcheck disable=SC2016  # the variables must expand in the child shell, not here
out="$(LOG_LEVEL=debug tools/env/with-env.sh smoke-reader -- sh -c 'echo "$ANTHROPIC_API_KEY|$CLAUDE_MODEL|$LOG_LEVEL|$READER_ONLY|$APP_NAME"')"
[ "$out" = "base-key|app-model|debug|a # b|smoke-reader" ] || fail "env precedence: got '$out'"
# shellcheck disable=SC2016
out="$(tools/env/with-env.sh smoke-writer -- sh -c 'echo "$CLAUDE_MODEL|${READER_ONLY:-unset}|$LOG_LEVEL"')"
[ "$out" = "base-model|unset|info" ] || fail "env isolation between apps: got '$out'"
tools/env/with-env.sh smoke-reader --check >/dev/null || fail "env check with all keys set"
printf 'READER_PORT=\n' >>apps/smoke-reader/.env.example
expect_fail tools/env/with-env.sh smoke-reader --check
printed="$(tools/env/with-env.sh smoke-reader --print)"   # captured: grep -q in a pipe would SIGPIPE it
grep -q 'CLAUDE_MODEL .*apps/smoke-reader/.env' <<<"$printed" || fail "env --print source"
! grep -q 'base-key' <<<"$printed" || fail "env --print leaked a value"
ok "layered env: process > app > base, isolation, --check, --print without values"

for f in .env apps/smoke-reader/.env data/smoke-data/x; do git check-ignore -q "$f" || fail "$f must be git-ignored"; done
for f in data/README.md data/smoke-seed/x data/unlisted/x; do ! git check-ignore -q "$f" || fail "$f must not be ignored"; done
! git check-ignore -q apps/smoke-reader/.env.example || fail ".env.example must not be ignored"
ok "gitignore covers nested .env files; data/<dataset>/ is ignored only by choice"
echo "monorepo smoke test passed"
