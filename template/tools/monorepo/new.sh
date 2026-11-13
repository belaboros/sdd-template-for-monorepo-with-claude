#!/usr/bin/env bash
# Scaffolds a unit of the monorepo from tools/monorepo/skeletons/ and registers it in
# docs/architecture/components.json, then re-renders the system map (ADR-0010, ADR-0013).
#
#   tools/monorepo/new.sh app     <name> ["one-sentence responsibility"]
#   tools/monorepo/new.sh shared  <name> ["one-sentence responsibility"]
#   tools/monorepo/new.sh dataset <name> <owner-app> ["one-sentence description"]
#
# Names are kebab-case. Readers of a dataset and dependencies on shared code are added afterwards
# by editing components.json (reads / mayDependOn) and running tools/monorepo/system-map.sh.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
map="$root/docs/architecture/components.json"
skeletons="$root/tools/monorepo/skeletons"

usage() { sed -n '5,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 64; }
die() { echo "new: $*" >&2; exit 1; }

[ $# -ge 2 ] || usage
kind="$1" name="$2"; shift 2
owner=""
if [ "$kind" = dataset ]; then
  [ $# -ge 1 ] || usage
  owner="$1"; shift
fi
text="${1:-_TBD: one sentence; refined by /spec._}"

[[ "$name" =~ ^[a-z][a-z0-9-]*$ ]] || die "'$name' is not kebab-case (a-z, 0-9, '-'; starts with a letter)"
case "$text" in *$'\n'*|*'|'*) die "the description must be one line without '|'" ;; esac
jq -e --arg n "$name" 'any(((.components // []) + (.datasets // []))[]; .name == $n)' "$map" >/dev/null \
  && die "'$name' is already registered in docs/architecture/components.json"

case "$kind" in
  app)     target="apps/$name" ;;
  shared)  target="shared/$name"; [ "$name" != contracts ] || die "'contracts' is reserved" ;;
  dataset) target="shared/contracts/$name"
           jq -e --arg o "$owner" 'any((.components // [])[]; .kind == "app" and .name == $o)' "$map" >/dev/null \
             || die "owner '$owner' is not a registered app" ;;
  *) usage ;;
esac
[ ! -e "$root/$target" ] || die "$target already exists"

# Copy the skeleton, replacing placeholders literally (no regex or '&' surprises).
mkdir -p "$root/$target"
(cd "$skeletons/$kind" && find . -type f) | while read -r rel; do
  mkdir -p "$(dirname "$root/$target/$rel")"
  NAME="$name" TEXT="$text" OWNER="$owner" TODAY="$(date +%Y-%m-%d)" awk '
    function repl(s, from, to,   out, i) {
      out = ""
      while ((i = index(s, from)) > 0) { out = out substr(s, 1, i - 1) to; s = substr(s, i + length(from)) }
      return out s
    }
    { s = repl($0, "__NAME__", ENVIRON["NAME"]); s = repl(s, "__TEXT__", ENVIRON["TEXT"])
      s = repl(s, "__OWNER__", ENVIRON["OWNER"]); print repl(s, "__DATE__", ENVIRON["TODAY"]) }
  ' "$skeletons/$kind/$rel" >"$root/$target/$rel"
done

# Register it.
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
case "$kind" in
  app) jq --arg n "$name" --arg t "$text" '.components = ((.components // []) + [{
          name: $n, kind: "app", responsibility: $t, paths: ["apps/\($n)/**"],
          mayDependOn: [], reads: [], writes: []}])' "$map" >"$tmp" ;;
  shared) jq --arg n "$name" --arg t "$text" '.components = ((.components // []) + [{
          name: $n, kind: "shared", responsibility: $t, paths: ["shared/\($n)/**"],
          mayDependOn: [], public: []}])' "$map" >"$tmp" ;;
  dataset) jq --arg n "$name" --arg o "$owner" --arg t "$text" '
          .datasets = ((.datasets // []) + [{name: $n, owner: $o, description: $t,
            contract: "shared/contracts/\($n)/", location: "${SHARED_DATA_DIR}/\($n)"}])
          | .components |= map(if .name == $o then .writes = ((.writes // []) + [$n]) else . end)' "$map" >"$tmp" ;;
esac
cat "$tmp" >"$map"

echo "new: created $target/ and registered $kind '$name'"
"$root/tools/monorepo/system-map.sh"
