#!/usr/bin/env bash
# Sets remotes of fedora-dotfiles aad us-pt-keyboard-layout to SSH URLs 
# if they're currently set to HTTPS URLs.

set -euo pipefail

prefix="[set-ssh-remotes]"

if ! command -v git >/dev/null 2>&1; then
  echo "$prefix git is not installed." >&2
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "$prefix ssh is not installed." >&2
  exit 1
fi

echo "$prefix Testing SSH authentication with GitHub..."
ssh_output=""
ssh_status=0
ssh_output="$(ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1)" || ssh_status=$?

if [[ "$ssh_output" != *"successfully authenticated"* ]]; then
  echo "$prefix GitHub SSH authentication failed." >&2
  [[ -n "$ssh_output" ]] && echo "$ssh_output" >&2
  if (( ssh_status == 0 )); then
    ssh_status=1
  fi
  exit "$ssh_status"
fi

set_remote_to_ssh() {
  local repository="$1"
  local remote_url
  local remote_path
  local ssh_url

  if [[ ! -d "$repository" ]]; then
    echo "$prefix Repository not found: $repository" >&2
    return 1
  fi

  if ! git -C "$repository" rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "$prefix Not a Git repository: $repository" >&2
    return 1
  fi

  if ! remote_url="$(git -C "$repository" remote get-url origin 2>/dev/null)"; then
    echo "$prefix Missing origin remote: $repository" >&2
    return 1
  fi

  if [[ "$remote_url" == git@*:* || "$remote_url" == ssh://* ]]; then
    echo "$prefix origin is already an SSH remote: $repository"
    return 0
  fi

  if [[ "$remote_url" == https://github.com/* ]]; then
    remote_path="${remote_url#https://github.com/}"
  elif [[ "$remote_url" == http://github.com/* ]]; then
    remote_path="${remote_url#http://github.com/}"
  else
    echo "$prefix Unsupported origin URL in $repository: $remote_url" >&2
    return 1
  fi

  if [[ "$remote_path" != *.git ]]; then
    remote_path="$remote_path.git"
  fi

  if [[ ! "$remote_path" =~ ^[^/]+/[^/]+\.git$ ]]; then
    echo "$prefix Unsupported GitHub origin URL in $repository: $remote_url" >&2
    return 1
  fi

  ssh_url="git@github.com:$remote_path"
  git -C "$repository" remote set-url origin "$ssh_url"
  echo "$prefix Updated $repository origin to $ssh_url"
}

set_remote_to_ssh "$HOME/fedora-dotfiles"
set_remote_to_ssh "$HOME/us-pt-keyboard-layout"

echo "$prefix Done."