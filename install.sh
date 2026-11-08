#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_URL="https://github.com/tomecarvalho/fedora-dotfiles.git"
REPOSITORY_DIR="$HOME/fedora-dotfiles"

if ! command -v git >/dev/null 2>&1; then
  sudo dnf install -y git
fi

if [[ -e "$REPOSITORY_DIR" ]]; then
  echo "Error: $REPOSITORY_DIR already exists." >&2
  exit 1
fi

git clone --branch main --single-branch "$REPOSITORY_URL" "$REPOSITORY_DIR"
exec "$REPOSITORY_DIR/scripts/install/interactive.sh"
