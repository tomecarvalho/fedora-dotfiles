#!/usr/bin/env bash
# Installs optional software and services.

set -euo pipefail

ALL_STEPS=(
  jellyfin
  vscode_install
  zed_install
)

VIDEOS_DIR="$HOME/Videos"
SHOWS_DIR="$VIDEOS_DIR/shows"
FILMS_DIR="$VIDEOS_DIR/films"
JELLYFIN_MEDIA_DIR="/mnt/media"
JELLYFIN_SHOWS_DIR="$JELLYFIN_MEDIA_DIR/shows"
JELLYFIN_FILMS_DIR="$JELLYFIN_MEDIA_DIR/films"

jellyfin() {
  echo "[jellyfin] Set up Jellyfin media server"

  mkdir -p "$SHOWS_DIR"
  mkdir -p "$FILMS_DIR"

  sudo mkdir -p "$JELLYFIN_SHOWS_DIR"
  sudo mkdir -p "$JELLYFIN_FILMS_DIR"

  FSTAB_LINE_SHOWS="$SHOWS_DIR $JELLYFIN_SHOWS_DIR none bind 0 0"
  FSTAB_LINE_FILMS="$FILMS_DIR $JELLYFIN_FILMS_DIR none bind 0 0"

  grep -qsF "$FSTAB_LINE_SHOWS" /etc/fstab ||
    echo "$FSTAB_LINE_SHOWS" | sudo tee -a /etc/fstab

  grep -qsF "$FSTAB_LINE_FILMS" /etc/fstab ||
    echo "$FSTAB_LINE_FILMS" | sudo tee -a /etc/fstab

  sudo mount -a

  if id jellyfin &>/dev/null; then
    sudo setfacl -R -m u:jellyfin:rx "$SHOWS_DIR" "$FILMS_DIR"
    sudo setfacl -m u:jellyfin:x "$VIDEOS_DIR" "$HOME"
  else
    echo "[jellyfin] Warning: jellyfin user not found, skipping ACL setup"
  fi

  echo "[jellyfin] Done"
}

vscode_install() {
  local prefix="[vscode_install]"

  if command -v code &>/dev/null; then
    echo "$prefix VS Code is already installed"
    return
  fi

  echo "$prefix Add VS Code repository and install Code"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
  echo "$prefix Install VS Code"
  sudo dnf in -y code
}

zed_install() {
  local prefix="[zed_install]"

  if command -v zed &>/dev/null; then
    echo "$prefix Zed is already installed"
    return
  fi

  echo "$prefix Install Zed through its installation script"
  curl -fsSL https://zed.dev/install.sh | sh
}

usage() {
  cat <<EOF
Usage: $0 [-s "step1,step2" | -s "name1,name2"] [-l]

Options:
  -s, --steps   Comma-separated list of steps to run. Accepts either descriptive names or (deprecated) numbers.
                Steps run in the default order; duplicates are ignored.
                Examples: -s "jellyfin,vscode_install" or -s "1,2"
  -l, --list    List all available steps in order.
  -h, --help    Show this help message.

Available steps (in order):
$(
  i=1
  for name in "${ALL_STEPS[@]}"; do
    printf "  %2d) %s\n" "$i" "$name"
    ((i++))
  done
)
EOF
}

STEPS_ARG=""
LIST_ONLY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--steps)
      if [[ -n "${2-}" ]]; then
        STEPS_ARG="$2"
        shift 2
        continue
      fi
      echo "Error: --steps requires an argument" >&2
      usage
      exit 2
      ;;
    -l|--list)
      LIST_ONLY=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$LIST_ONLY" == true ]]; then
  usage
  exit 0
fi

declare -a RUN_STEPS=()
if [[ -z "$STEPS_ARG" ]]; then
  RUN_STEPS=("${ALL_STEPS[@]}")
else
  declare -A requested=()
  IFS=',' read -ra raw <<<"$STEPS_ARG"
  for token in "${raw[@]}"; do
    step=$(echo "$token" | xargs)
    if [[ -z "$step" ]]; then
      continue
    fi
    if [[ "$step" =~ ^[0-9]+$ ]]; then
      idx=$((10#$step))
      if ((idx < 1 || idx > ${#ALL_STEPS[@]})); then
        echo "Invalid step number: $step" >&2
        exit 2
      fi
      name="${ALL_STEPS[$((idx - 1))]}"
      requested["$name"]=1
    else
      valid=false
      for name in "${ALL_STEPS[@]}"; do
        if [[ "$name" == "$step" ]]; then
          valid=true
          requested["$name"]=1
          break
        fi
      done
      if [[ "$valid" != true ]]; then
        echo "Invalid step name: $step" >&2
        exit 2
      fi
    fi
  done
  for name in "${ALL_STEPS[@]}"; do
    if [[ -n "${requested[$name]+x}" ]]; then
      RUN_STEPS+=("$name")
    fi
  done
fi

for s in "${RUN_STEPS[@]}"; do
  if declare -F "$s" >/dev/null; then
    "$s"
  else
    echo "Unknown step function: $s" >&2
    exit 3
  fi
done
