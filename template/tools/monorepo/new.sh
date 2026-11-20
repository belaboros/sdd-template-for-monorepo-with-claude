#!/usr/bin/env bash
# Scaffolds a unit of the monorepo from tools/monorepo/skeletons/ and registers it in
# docs/architecture/components.json, then re-renders the system map (ADR-0010, ADR-0013, ADR-0016).
#
#   tools/monorepo/new.sh app     <name> ["one-sentence responsibility"]
#   tools/monorepo/new.sh lib     <name> ["one-sentence responsibility"]
#   tools/monorepo/new.sh dataset <name> <owner-app> <commit|ignore> ["one-sentence description"]
#
# For a dataset, commit|ignore says whether data/<name>/ goes into git (ADR-0016);
# ignore adds /data/<name>/ to the root .gitignore.
#
# Names are kebab-case. Readers of a dataset and dependencies on libraries are added afterwards
# by editing components.json (reads / mayDependOn) and running tools/monorepo/system-map.sh.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
map="$root/docs/architecture/components.json"
skeletons="$root/tools/monorepo/skeletons"

usage() { sed -n '5,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 64; }
die() { echo "new: $*" >&2; exit 1; }

[ $# -ge 2 ] || usage
kind="$1" name="$2"; shift 2
owner="" git=""
if [ "$kind" = dataset ]; then
  [ $# -ge 2 ] || usage
  owner="$1" git="$2"; shift 2
  case "$git" in commit|ignore) ;; *) die "say whether data/$name/ is committed: 'commit' or 'ignore', not '$git' (ADR-0016)" ;; esac
fi
text="${1:-_TBD: one sentence; refined by /spec._}"

[[ "$name" =~ ^[a-z][a-z0-9-]*$ ]] || die "'$name' is not kebab-case (a-z, 0-9, '-'; starts with a letter)"
case "$text" in *$'\n'*|*'|'*) die "the description must be one line without '|'" ;; esac
jq -e --arg n "$name" 'any(((.components // []) + (.datasets // []))[]; .name == $n)' "$map" >/dev/null \
  && die "'$name' is already registered in docs/architecture/components.json"

case "$kind" in
  app)     target="apps/$name" ;;
  lib)     target="libs/$name"; [ "$name" != contracts ] || die "'contracts' is reserved for dataset contracts" ;;
  dataset) target="libs/contracts/$name"
           jq -e --arg o "$owner" 'any((.components // [])[]; .kind == "app" and .name == $o)' "$map" >/dev/null \
             || die "owner '$owner' is not a registered app" ;;
  *) usage ;;
esac
[ ! -e "$root/$target" ] || die "$target already exists"

# Copy the skeleton, replacing placeholders literally (no regex or '&' surprises).
mkdir -p "$root/$target"
(cd "$skeletons/$kind" && find . -type f) | while read -r rel; do
  mkdir -p "$(dirname "$root/$target/$rel")"
  NAME="$name" TEXT="$text" OWNER="$owner" GIT="$git" TODAY="$(date +%Y-%m-%d)" awk '
    function repl(s, from, to,   out, i) {
      out = ""
      while ((i = index(s, from)) > 0) { out = out substr(s, 1, i - 1) to; s = substr(s, i + length(from)) }
      return out s
    }
    { s = repl($0, "__NAME__", ENVIRON["NAME"]); s = repl(s, "__TEXT__", ENVIRON["TEXT"])
      s = repl(s, "__OWNER__", ENVIRON["OWNER"]); s = repl(s, "__GIT__", ENVIRON["GIT"]); print repl(s, "__DATE__", ENVIRON["TODAY"]) }
  ' "$skeletons/$kind/$rel" >"$root/$target/$rel"
done

# Register it.
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
case "$kind" in
  app) jq --arg n "$name" --arg t "$text" '.components = ((.components // []) + [{
          name: $n, kind: "app", responsibility: $t, paths: ["apps/\($n)/**"],
          mayDependOn: [], reads: [], writes: []}])' "$map" >"$tmp" ;;
  lib) jq --arg n "$name" --arg t "$text" '.components = ((.components // []) + [{
          name: $n, kind: "lib", responsibility: $t, paths: ["libs/\($n)/**"],
          mayDependOn: [], public: []}])' "$map" >"$tmp" ;;
  dataset) jq --arg n "$name" --arg o "$owner" --arg t "$text" --arg g "$git" '
          .datasets = ((.datasets // []) + [{name: $n, owner: $o, description: $t,
            contract: "libs/contracts/\($n)/", location: "${SHARED_DATA_DIR}/\($n)", git: $g}])
          | .components |= map(if .name == $o then .writes = ((.writes // []) + [$n]) else . end)' "$map" >"$tmp" ;;
esac
cat "$tmp" >"$map"
if [ "$git" = ignore ] && ! grep -qxF "/data/$name/" "$root/.gitignore"; then
  [ -z "$(tail -c1 "$root/.gitignore")" ] || echo >>"$root/.gitignore"
  echo "/data/$name/" >>"$root/.gitignore"
fi

echo "new: created $target/ and registered $kind '$name'"
"$root/tools/monorepo/system-map.sh"
