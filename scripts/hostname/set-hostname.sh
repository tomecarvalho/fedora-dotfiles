#!/bin/sh
# Sets hostname to "<alias>-fedora"
# Alias comes from neighbouring devices.yaml
# Matches by product version, family, or name.

set -eu

dir=$(cd "$(dirname "$0")" && pwd)
cfg="$dir/devices.yaml"
dmi=/sys/devices/virtual/dmi/id
suffix=-fedora

[ -r "$cfg" ] || { echo "missing $cfg" >&2; exit 1; }

# Print the alias for model $1 (flat "model: alias" YAML, optional quotes).
lookup() {
  awk -v m="$1" '
  /^[[:space:]]*(#|$)/ { next }
  {
    i = index($0, ":"); if (!i) next
    k = substr($0, 1, i - 1); v = substr($0, i + 1)
    sub(/[[:space:]]+#.*/, "", v)
    gsub(/^[ \t]+|[ \t]+$/, "", k); gsub(/^[ \t]+|[ \t]+$/, "", v)
    gsub(/^["\047]|["\047]$/, "", k); gsub(/^["\047]|["\047]$/, "", v)
    if (k == m) { print v; exit }
  }' "$cfg"
}

# Match the model against devices.yaml and get the alias.
alias_=""
for f in product_version product_family product_name; do
  [ -r "$dmi/$f" ] || continue
  model=$(tr -d '\n' < "$dmi/$f")
  [ -n "$model" ] || continue
  alias_=$(lookup "$model")
  if [ -n "$alias_" ]; then
    echo "Matched '$model' to '$alias_'"
    break
  fi
done

# No alias: print the model info and exit with error.
if [ -z "$alias_" ]; then
  echo "No alias in $cfg for this device:" >&2
  for f in product_version product_family product_name; do
    [ -r "$dmi/$f" ] && echo "  $f: $(cat "$dmi/$f")" >&2
  done
  exit 1
fi

new="$alias_$suffix"
[ "$(hostname)" = "$new" ] && { echo "Hostname is already '$new'"; exit 0; }

if [ "$(id -u)" -eq 0 ]; then sudo=""; else sudo="sudo"; fi
$sudo hostnamectl set-hostname "$new"
echo "Hostname set to $new"