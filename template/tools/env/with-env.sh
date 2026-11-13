#!/usr/bin/env bash
# Layered environment loader (ADR-0012). Works with bash 3.2 (macOS default) and later.
#
#   tools/env/with-env.sh <app> -- <command> [args...]   run a command with the merged environment
#   tools/env/with-env.sh <app> --check                  fail if a key from an .env.example is unset or empty
#   tools/env/with-env.sh <app> --print                  list the keys and where each comes from (never the values)
#
# <app> is a folder name under apps/, or "-" for the root environment only.
#
# Precedence, highest first:
#   1. variables already set in the process environment (CI, the shell, a container)
#   2. apps/<app>/.env    (app-specific: adds keys or overrides base keys)
#   3. .env               (base, shared by every app; e.g. ANTHROPIC_API_KEY)
# The .env.example files are documentation and the list of required keys; they are never loaded.
#
# File format: KEY=value per line; "export KEY=value" is accepted; '#' starts a comment line or,
# after whitespace, an inline comment in an unquoted value; 'single' or "double" quotes keep the
# value literally. No ${VAR} interpolation and no multi-line values. Nothing is ever eval'ed.
# A key in an .env.example whose line ends with "# optional" may stay empty.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

usage() { sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 64; }

[ $# -ge 2 ] || usage
app="$1"; shift
mode="$1"; shift
case "$mode" in --|--check|--print) ;; *) usage ;; esac

base_file="$root/.env"
base_example="$root/.env.example"
app_file=""; app_example=""
if [ "$app" != "-" ]; then
  [ -d "$root/apps/$app" ] || { echo "with-env: no such app: apps/$app" >&2; exit 64; }
  app_file="$root/apps/$app/.env"
  app_example="$root/apps/$app/.env.example"
fi

# Prints "KEY<US>VALUE<US>OPTIONAL(0|1)" for every assignment in a dotenv file. US (\037) is not
# whitespace for read, so empty fields survive (a tab would collapse them).
US=$'\037'
parse() {
  local file="$1" line key val optional
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"          # trim leading whitespace
    case "$line" in ''|'#'*) continue ;; esac
    line="${line#export }"
    case "$line" in *=*) ;; *) continue ;; esac
    key="${line%%=*}"; key="${key%"${key##*[![:space:]]}"}"
    val="${line#*=}";  val="${val#"${val%%[![:space:]]*}"}"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || { echo "with-env: ignoring invalid key '$key' in ${file#"$root"/}" >&2; continue; }
    optional=0
    case "$val" in *'# optional'*) optional=1 ;; esac
    case "$val" in
      \"*) val="${val#\"}"; val="${val%%\"*}" ;;
      \'*) val="${val#\'}"; val="${val%%\'*}" ;;
      *)   val="$(printf '%s' "$val" | sed -E 's/[[:space:]]+#.*$//; s/[[:space:]]+$//')" ;;
    esac
    printf '%s\037%s\037%s\n' "$key" "$val" "$optional"
  done <"$file"
}

sources=""   # lines "KEY<TAB>source", for --print
preset=""    # keys that were already in the process environment
note_source() { sources="${sources}$1	$2
"; }
source_of() { printf '%s' "$sources" | awk -F'\t' -v k="$1" '$1 == k { print $2; exit }'; }

# Load the most specific file first and never overwrite: process env > app .env > base .env.
load() {
  local file="$1" label="$2" key val _opt
  while IFS="$US" read -r key val _opt; do
    if [ -n "${!key+x}" ]; then
      [ -n "$(source_of "$key")" ] || { note_source "$key" "environment"; preset="$preset $key"; }
      continue
    fi
    export "$key=$val"
    note_source "$key" "$label"
  done < <(parse "$file")
}

[ -n "$app_file" ] && load "$app_file" "apps/$app/.env"
load "$base_file" ".env"
export REPO_ROOT="${REPO_ROOT:-$root}"
[ "$app" != "-" ] && export APP_NAME="${APP_NAME:-$app}"

required_keys() {   # "KEY<US>OPTIONAL<US>example-file", from the example files
  local f key _val opt
  for f in "$base_example" ${app_example:+"$app_example"}; do
    while IFS="$US" read -r key _val opt; do printf '%s\037%s\037%s\n' "$key" "$opt" "${f#"$root"/}"; done < <(parse "$f")
  done
}

case "$mode" in
  --)
    [ $# -gt 0 ] || usage
    exec "$@"
    ;;
  --check)
    missing=0
    [ -f "$base_file" ] || echo "with-env: .env not found; copy .env.example to .env and fill it in" >&2
    while IFS="$US" read -r key opt example; do
      [ "$opt" = 1 ] && continue
      if [ -z "${!key:-}" ]; then echo "missing: $key (listed in $example)" >&2; missing=1; fi
    done < <(required_keys)
    [ "$missing" = 0 ] && echo "with-env: all required keys are set for ${app/#-/root}"
    exit "$missing"
    ;;
  --print)
    { required_keys | cut -d "$US" -f1; printf '%s' "$sources" | cut -f1; } | awk 'NF && !seen[$0]++' | while read -r key; do
      src="$(source_of "$key")"; state="unset"
      [ -n "${!key+x}" ] && { state="set"; [ -z "${!key}" ] && state="empty"; }
      printf '%-32s %-6s %s\n' "$key" "$state" "${src:-—}"
    done
    ;;
esac
