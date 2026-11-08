#!/usr/bin/env bash

# Sync the same home paths (and optional project dirs) that the backup scripts
# cover to another machine on the local network via rsync over SSH.
# On conflicts, this machine (the sender) wins.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/core.sh
source "$SCRIPT_DIR/../utils/core.sh"

ECHO_PREFIX="[sync-local]"

DIRS_TO_SYNC=(
	"$HOME/.config/Cursor"
	"$HOME/.cursor"
	"$HOME/.mozilla"
	"$HOME/.oh-my-zsh"
	"$HOME/.ssh"
	"$HOME/.thunderbird"
	"$HOME/.vpn"
)

FILES_TO_SYNC=(
	"$HOME/.private.aliases"
	"$HOME/.zsh_history"
)

# Same excludes as backup-projects.sh
PROJECT_EXCLUDE_PATTERNS=(
	"__pycache__"
	".gradle"
	".m2"
	".mypy_cache"
	".npm"
	".pnpm-store"
	".pytest_cache"
	".tox"
	".venv"
	".yarn/cache"
	"*.egg-info"
	"build"
	"dist"
	"node_modules"
	"out"
	"output"
	"target"
	"vendor"
	"venv"
  ".cache"
  ".angular"
  ".dart_tool"
  ".direnv"
  ".DS_Store"
  ".eggs"
  ".eslintcache"
  ".expo"
  ".idea/caches"
  ".ipynb_checkpoints"
  ".next"
  ".nox"
  ".nuxt"
  ".nyc_output"
  ".parcel-cache"
  ".pytype"
  ".ruff_cache"
  ".serverless"
  ".svelte-kit"
  ".terraform"
  ".turbo"
  "*.log"
  "*.pyc"
  "bower_components"
  "cmake-build-*"
  "coverage"
  "DerivedData"
  "Pods"
  "Thumbs.db"
)

usage() {
	cat <<EOF
Usage: $(basename "$0") [options] <host>
       $(basename "$0") --receive

Copy home backup paths (and optional project directories) to another machine
over SSH. Local (sender) files win on conflicts.

Arguments:
  host                 SSH target, e.g. laptop or user@192.168.1.50

Options:
  -r, --receive        Run on the RECEIVING machine: ensure sshd is running,
                       detect its LAN IP, and print the command to run on the
                       sender. No host argument needed.
  -p, --project DIR    Project directory to sync (repeatable; must be under \$HOME)
  -n, --dry-run        Show what would be transferred without writing
  -d, --delete         Remove files on the remote that are gone locally
  -h, --help           Show this help

Auth:
  Works with SSH keys or a password. A multiplexed SSH connection is used so a
  password is only entered once per run. Prefer the .local hostname on LAN,
  e.g. laptop.local

Examples:
  $(basename "$0") --receive
  $(basename "$0") laptop.local
  $(basename "$0") user@192.168.1.50 -p ~/projects/app
  $(basename "$0") --dry-run laptop.local -p ~/Code/foo -p ~/Code/bar
EOF
}

DRY_RUN=0
DELETE=0
RECEIVE=0
REMOTE=""
PROJECT_DIRS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
	-r | --receive)
		RECEIVE=1
		shift
		;;
	-p | --project)
		if [[ $# -lt 2 || "$2" == -* ]]; then
			util_die "$ECHO_PREFIX" "$1 requires a directory argument."
		fi
		PROJECT_DIRS+=("$2")
		shift 2
		;;
	-n | --dry-run)
		DRY_RUN=1
		shift
		;;
	-d | --delete)
		DELETE=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	-*)
		util_die "$ECHO_PREFIX" "Unknown option: $1"
		;;
	*)
		if [[ -n "$REMOTE" ]]; then
			util_die "$ECHO_PREFIX" "Unexpected argument: $1 (use -p/--project for project directories)."
		fi
		REMOTE="$1"
		shift
		;;
	esac
done

# Receiver mode: make sure sshd is up and print the sender command.
receive_mode() {
	local lan_ip

	util_require_commands "$ECHO_PREFIX" rsync ip systemctl

	if systemctl is-active --quiet sshd; then
		echo "$ECHO_PREFIX sshd is already running."
	else
		echo "$ECHO_PREFIX sshd is not running, starting it (sudo)..."
		sudo systemctl enable --now sshd
		if ! systemctl is-active --quiet sshd; then
			util_die "$ECHO_PREFIX" "Failed to start sshd."
		fi
	fi

	# Source IP of the default route = the LAN address other machines can reach.
	lan_ip="$(ip -4 route get 1.1.1.1 2>/dev/null |
		awk '{for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit }}' || true)"
	if [[ -z "$lan_ip" ]]; then
		lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
	fi
	if [[ -z "$lan_ip" ]]; then
		util_die "$ECHO_PREFIX" "Could not determine LAN IP address."
	fi

	echo "$ECHO_PREFIX Receiver ready: ${USER}@${lan_ip}"
	echo "$ECHO_PREFIX Run this on the sender (add --dry-run first to preview):"
	echo "sync_local ${USER}@${lan_ip} -p ~/Projects/example"
	echo
}

if [[ "$RECEIVE" -eq 1 ]]; then
	receive_mode
	exit 0
fi

if [[ -z "$REMOTE" ]]; then
	usage >&2
	exit 1
fi

util_require_commands "$ECHO_PREFIX" rsync ssh

RSYNC_OPTS=(-aH --partial --human-readable --info=progress2)
if [[ "$DRY_RUN" -eq 1 ]]; then
	RSYNC_OPTS+=(--dry-run)
fi
if [[ "$DELETE" -eq 1 ]]; then
	RSYNC_OPTS+=(--delete)
fi

# Multiplex SSH so password auth only prompts once (keys still work if you
# set IdentityFile for the host). IdentitiesOnly avoids "Too many
# authentication failures" from offering every key in ~/.ssh / the agent.
mkdir -p "${HOME}/.ssh"
CONTROL_PATH="${HOME}/.ssh/cm-sync-local-%C"
SSH_OPTS=(
	-o "ControlMaster=auto"
	-o "ControlPath=${CONTROL_PATH}"
	-o "ControlPersist=60"
	-o "ConnectTimeout=10"
	-o "IdentitiesOnly=yes"
	-o "PreferredAuthentications=password,keyboard-interactive,publickey"
)
RSYNC_RSH="ssh ${SSH_OPTS[*]}"

cleanup_ssh() {
	ssh -O exit "${SSH_OPTS[@]}" "$REMOTE" 2>/dev/null || true
}
trap cleanup_ssh EXIT

echo "$ECHO_PREFIX Connecting to ${REMOTE} (password once if needed)..."
if ! ssh "${SSH_OPTS[@]}" "$REMOTE" "true"; then
	util_die "$ECHO_PREFIX" "Cannot reach '${REMOTE}' over SSH. Use the .local hostname (e.g. host.local) or the LAN IP, and confirm Remote Login is enabled."
fi

remote_home_path() {
	local abs_path="$1"
	local rel="${abs_path#"$HOME"/}"
	if [[ "$rel" == "$abs_path" ]]; then
		util_die "$ECHO_PREFIX" "Path is not under \$HOME: $abs_path"
	fi
	printf '%s\n' "$rel"
}

# Ensure a path relative to the remote home exists (rsync will not create parents).
remote_mkdir() {
	local dest_rel="$1"
	ssh "${SSH_OPTS[@]}" "$REMOTE" "mkdir -p -- $(printf '%q' "$dest_rel")"
}

sync_dir() {
	local src="$1"
	local dest_rel
	dest_rel="$(remote_home_path "$src")"

	if [[ ! -d "$src" ]]; then
		echo "$ECHO_PREFIX Skipping missing directory: $src"
		return 0
	fi

	remote_mkdir "$dest_rel"
	echo "$ECHO_PREFIX Syncing directory: $src -> ${REMOTE}:${dest_rel}/"
	rsync "${RSYNC_OPTS[@]}" -e "$RSYNC_RSH" "${src}/" "${REMOTE}:${dest_rel}/"
}

sync_file() {
	local src="$1"
	local dest_rel
	local dest_dir
	dest_rel="$(remote_home_path "$src")"
	dest_dir="$(dirname -- "$dest_rel")"

	if [[ ! -f "$src" ]]; then
		echo "$ECHO_PREFIX Skipping missing file: $src"
		return 0
	fi

	if [[ "$dest_dir" != "." ]]; then
		remote_mkdir "$dest_dir"
	fi
	echo "$ECHO_PREFIX Syncing file: $src -> ${REMOTE}:${dest_rel}"
	rsync "${RSYNC_OPTS[@]}" -e "$RSYNC_RSH" "$src" "${REMOTE}:${dest_rel}"
}

sync_project() {
	local src="$1"
	local dest_rel
	local exclude_args=()
	local pattern

	if [[ ! -d "$src" ]]; then
		util_die "$ECHO_PREFIX" "Project directory does not exist: $src"
	fi

	# Resolve to absolute path for home-relative destination mapping
	src="$(cd "$src" && pwd)"
	dest_rel="$(remote_home_path "$src")"

	for pattern in "${PROJECT_EXCLUDE_PATTERNS[@]}"; do
		exclude_args+=(--exclude="$pattern")
	done

	remote_mkdir "$dest_rel"
	echo "$ECHO_PREFIX Syncing project: $src -> ${REMOTE}:${dest_rel}/"
	rsync "${RSYNC_OPTS[@]}" "${exclude_args[@]}" -e "$RSYNC_RSH" "${src}/" "${REMOTE}:${dest_rel}/"
}

if [[ "$DRY_RUN" -eq 1 ]]; then
	echo "$ECHO_PREFIX Dry run — no files will be written on ${REMOTE}"
fi

echo "$ECHO_PREFIX Syncing home paths to ${REMOTE}..."
for dir in "${DIRS_TO_SYNC[@]}"; do
	sync_dir "$dir"
done
for file in "${FILES_TO_SYNC[@]}"; do
	sync_file "$file"
done

if [[ ${#PROJECT_DIRS[@]} -gt 0 ]]; then
	echo "$ECHO_PREFIX Syncing project directories to ${REMOTE}..."
	for project in "${PROJECT_DIRS[@]}"; do
		sync_project "$project"
	done
fi

echo "$ECHO_PREFIX Done."