#!/usr/bin/env bash
# The system map (ADR-0010, ADR-0013): validates docs/architecture/components.json against the rules
# and the folders on disk, then renders the generated block in docs/architecture/architecture.md.
#
#   tools/monorepo/system-map.sh           validate, then regenerate the block
#   tools/monorepo/system-map.sh --check   validate, and fail if the block is out of date (pre-commit, CI)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
map="$root/docs/architecture/components.json"
doc="$root/docs/architecture/architecture.md"
begin='<!-- system-map:begin'
end='<!-- system-map:end -->'
check=0; [ "${1:-}" = "--check" ] && check=1

jq -e . "$map" >/dev/null || { echo "system-map: $map is not valid JSON" >&2; exit 1; }

# ---- 1. Rules on the declarations ------------------------------------------------------------
rule_errors=$(jq -r '
  (.components // []) as $c | (.datasets // []) as $d
  | [$c[] | select(.kind == "app")    | .name] as $apps
  | [$c[] | select(.kind == "lib") | .name] as $libs
  | [$d[] | .name] as $ds
  | def deps($n): [$c[] | select(.name == $n) | (.mayDependOn // [])[]];
    def has($v): any(.[]; . == $v);
  ( ([$c[].name] + $ds) | group_by(.) | map(select(length > 1) | .[0]) | .[] | "duplicate name: \(.)" ),
  ( ($c + $d)[] | select(.name | test("^[a-z][a-z0-9-]*$") | not) | "\(.name): names must be kebab-case" ),
  ( $c[] | select(.kind != "app" and .kind != "lib") | "\(.name): kind must be \"app\" or \"lib\"" ),
  ( $c[] | select((.responsibility // "") == "") | "\(.name): responsibility is missing" ),
  ( $c[] | . as $x | (.mayDependOn // [])[] | . as $v | select(($libs | has($v)) | not)
      | "\($x.name) -> \(.): only libraries may be depended on; apps never depend on each other (ADR-0010)" ),
  ( $c[] | select(.kind == "lib") | select(((.reads // []) + (.writes // [])) | length > 0)
      | "\(.name): only apps read or write datasets (ADR-0013)" ),
  ( $c[] | select(.kind == "app") | . as $x | ((.reads // []) + (.writes // []))[] | . as $v | select(($ds | has($v)) | not)
      | "\($x.name): unknown dataset \(.)" ),
  ( $c[] | select(.kind == "app") | . as $x | (.reads // [])[] | . as $v | select(($x.writes // []) | has($v))
      | "\($x.name): lists \(.) in both reads and writes; the owner only lists writes" ),
  ( $d[] | . as $y | select(($apps | has($y.owner)) | not) | "dataset \(.name): owner \(.owner) is not an app" ),
  ( $d[] | . as $y | $c[] | select(.kind == "app" and ((.writes // []) | has($y.name)) and .name != $y.owner)
      | "dataset \($y.name): written by \(.name), but only its owner \($y.owner) may write it (ADR-0013)" ),
  ( $d[] | . as $y | select([$c[] | select(.name == $y.owner and ((.writes // []) | has($y.name)))] | length == 0)
      | "dataset \($y.name): its owner \($y.owner) must list it in writes" ),
  ( $libs[] as $l
      | {seen: [], next: deps($l)}
      | until(.next | length == 0; .seen as $s | (.next - $s) as $new | {seen: ($s + $new), next: ([$new[] | deps(.)[]] | unique)})
      | select(.seen | has($l)) | "dependency cycle through library \($l)" )
' "$map")

# ---- 2. Declarations match the folders -------------------------------------------------------
fs_errors=""
add() { fs_errors="${fs_errors}$1
"; }
while IFS=$'\t' read -r kind name; do
  case "$kind" in
    app)     [ -f "$root/apps/$name/docs/architecture/components.json" ] || add "app $name: apps/$name/docs/architecture/components.json is missing (create apps with tools/monorepo/new.sh app $name)" ;;
    lib)     [ -d "$root/libs/$name" ] || add "library $name: folder libs/$name/ is missing" ;;
    dataset) [ -f "$root/libs/contracts/$name/README.md" ] || add "dataset $name: contract libs/contracts/$name/README.md is missing" ;;
  esac
done < <(jq -r '((.components // [])[] | "\(.kind)\t\(.name)"), ((.datasets // [])[] | "dataset\t\(.name)")' "$map" | sort -u)
for dir in "$root"/apps/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  jq -e --arg n "$name" 'any((.components // [])[]; .kind == "app" and .name == $n)' "$map" >/dev/null \
    || add "apps/$name/ is not registered in docs/architecture/components.json"
done

errors="$(printf '%s\n%s' "$rule_errors" "$fs_errors" | awk 'NF')"
if [ -n "$errors" ]; then
  echo "system-map: docs/architecture/components.json breaks the monorepo rules:" >&2
  printf '%s\n' "$errors" | sed 's/^/  - /' >&2
  exit 1
fi

# ---- 3. Render ---------------------------------------------------------------------------------
render() {
  jq -r '
    (.components // []) as $c | (.datasets // []) as $d
    | def id: (if .kind == "app" then "app_" elif .kind == "lib" then "lib_" else "ds_" end) + (.name | gsub("-"; "_"));
      def esc: gsub("\""; "#quot;");
      def list: if length == 0 then "—" else join(", ") end;
      def app($n): {kind: "app", name: $n} | id;
      def lib($n): {kind: "lib", name: $n} | id;
      def ds($n):  {kind: "dataset", name: $n} | id;
      def readers($n): [$c[] | select(.kind == "app" and ((.reads // []) | any(. == $n))) | .name];
    if ($c | length) + ($d | length) == 0 then
      "_No applications, libraries or datasets yet. Add one with `/scaffold app <name>`._"
    else
      ( "```mermaid", "flowchart LR",
        ( [$c[] | select(.kind == "app")] | select(length > 0)
          | "    subgraph apps [Applications]", (.[] | "        \(id)[\"<b>\(.name)</b><br/><i>\(.responsibility | esc)</i>\"]"), "    end" ),
        ( $d | select(length > 0)
          | "    subgraph data [Shared datasets]", (.[] | "        \({kind: "dataset", name: .name} | id)[(\"<b>\(.name)</b><br/><i>owner: \(.owner)</i>\")]"), "    end" ),
        ( [$c[] | select(.kind == "lib")] | select(length > 0)
          | "    subgraph libs [Libraries]", (.[] | "        \(id)[\"<b>\(.name)</b><br/><i>\(.responsibility | esc)</i>\"]"), "    end" ),
        ( $c[] | select(.kind == "app") | . as $a | (.writes // [])[] | "    \($a | id) -- writes --> \(ds(.))" ),
        ( $c[] | select(.kind == "app") | . as $a | (.reads // [])[]  | "    \(ds(.)) -. read by .-> \($a | id)" ),
        ( $c[] | . as $a | (.mayDependOn // [])[] | "    \($a | id) -- uses --> \(lib(.))" ),
        "    classDef app fill:#1f6feb,color:#fff,stroke:#1f6feb",
        "    classDef lib fill:#eef,color:#333,stroke:#669",
        "    classDef data fill:#fff4e5,color:#333,stroke:#c80",
        ( [$c[] | select(.kind == "app")    | id] | select(length > 0) | "    class \(join(",")) app" ),
        ( [$c[] | select(.kind == "lib") | id] | select(length > 0) | "    class \(join(",")) lib" ),
        ( [$d[] | {kind: "dataset", name: .name} | id] | select(length > 0) | "    class \(join(",")) data" ),
        "```", "" ),
      ( [$c[] | select(.kind == "app")] | select(length > 0)
        | "| App | Responsibility | Writes | Reads | Uses libraries | Docs |",
          "|-----|----------------|--------|-------|----------------|------|",
          (.[] | "| **\(.name)** | \(.responsibility) | \(.writes // [] | list) | \(.reads // [] | list) | \(.mayDependOn // [] | list) | [architecture](../../apps/\(.name)/docs/architecture/architecture.md) · [specs](../../apps/\(.name)/docs/specs/README.md) · [ADRs](../../apps/\(.name)/docs/architecture/adr/README.md) |"),
          "" ),
      ( $d | select(length > 0)
        | "| Dataset | Owner (only writer) | Read by | Contract | Description |",
          "|---------|---------------------|---------|----------|-------------|",
          (.[] | "| **\(.name)** | \(.owner) | \(readers(.name) | list) | [libs/contracts/\(.name)/](../../libs/contracts/\(.name)/README.md) | \(.description // "") |"),
          "" ),
      ( [$c[] | select(.kind == "lib")] | select(length > 0)
        | "| Library | Responsibility | Uses | Used by |",
          "|---------|----------------|------|---------|",
          (.[] | . as $l | "| **\(.name)** | \(.responsibility) | \(.mayDependOn // [] | list) | \([$c[] | select((.mayDependOn // []) | any(. == $l.name)) | .name] | list) |"),
          "" )
    end
  ' "$map" | awk 'NF { if (blank && seen) print ""; print; seen = 1; blank = 0; next } { blank = 1 }'   # single blank lines, none at the end
}

if ! grep -q "^$begin" "$doc" || ! grep -q "^$end" "$doc"; then
  echo "system-map: markers '$begin' / '$end' not found in ${doc#"$root"/}" >&2; exit 1
fi

block="$(mktemp)"; new="$(mktemp)"
trap 'rm -f "$block" "$new"' EXIT
render >"$block"
awk -v b="$begin" -v e="$end" -v f="$block" '
  index($0, b) == 1 { print; while ((getline line < f) > 0) print line; skip = 1; next }
  index($0, e) == 1 { skip = 0 }
  !skip { print }
' "$doc" >"$new"

if cmp -s "$doc" "$new"; then
  [ "$check" = 1 ] && echo "system-map: ok"
  exit 0
fi
if [ "$check" = 1 ]; then
  echo "system-map: the generated block in docs/architecture/architecture.md is out of date; run tools/monorepo/system-map.sh" >&2
  diff -u "$doc" "$new" >&2 || true
  exit 1
fi
cat "$new" >"$doc"
echo "system-map: updated docs/architecture/architecture.md"
