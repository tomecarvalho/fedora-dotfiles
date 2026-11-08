#!/usr/bin/env bash
# Runs general installation, and asks about optional installation groups.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running the general installation..."
"$SCRIPT_DIR/scripts/install/general.sh"

skipped=()

read -r -p "Install optional software and services? [y/N] " install_optional
if [[ "$install_optional" =~ ^[Yy]$ ]]; then
  "$SCRIPT_DIR/scripts/install/optional.sh"
else
  skipped+=("$SCRIPT_DIR/scripts/install/optional.sh")
fi

read -r -p "Install work software? [y/N] " install_work
if [[ "$install_work" =~ ^[Yy]$ ]]; then
  "$SCRIPT_DIR/scripts/install/work.sh"
else
  skipped+=("$SCRIPT_DIR/scripts/install/work.sh")
fi

echo
echo "Installation complete."

if (( ${#skipped[@]} > 0 )); then
  echo "To run these groups later:"
  printf '%s\n' "${skipped[@]}"
fi