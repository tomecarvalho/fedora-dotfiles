#!/usr/bin/env bash

OH_MY_ZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
US_PT_KEYBOARD_LAYOUT_GITHUB_SUFFIX="tomecarvalho/us-pt-keyboard-layout.git"

BLEX_MONO_NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/IBMPlexMono.zip"

VIDEOS_DIR="$HOME/Videos"
SHOWS_DIR="$VIDEOS_DIR/shows"
FILMS_DIR="$VIDEOS_DIR/films"
JELLYFIN_MEDIA_DIR="/mnt/media"
JELLYFIN_SHOWS_DIR="$JELLYFIN_MEDIA_DIR/shows"
JELLYFIN_FILMS_DIR="$JELLYFIN_MEDIA_DIR/films"

set -euo pipefail

# Default, ordered list of descriptive step names
ALL_STEPS=(
  set_hostname
  dnf_up
  rpm_fusion
  repos
  copr
  dnf_install
  codecs
  flatpak_install
  snap_install
  system_services
  ca_bundle_symlink
  us_pt_keyboard_layout
  oh_my_zsh
  oh_my_zsh_plugins
  starship_install
  snapper
  aliases
  blex_mono_nerd_font
  set_fonts_ibm_plex
  jellyfin
  stow_apply
  niri_dms
  dms_greeter
  vscode_install
  zed_install
  node_install
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALIASES_DIR="$SCRIPT_DIR/../aliases"
PKGS_DIR="$SCRIPT_DIR/../packages"
GENERAL_PKGS_DIR="$PKGS_DIR/general"
STOW_DIR="$SCRIPT_DIR/../stow"

# shellcheck source=utils/packages.sh
source "$SCRIPT_DIR/utils/packages.sh"
# shellcheck source=utils/core.sh
source "$SCRIPT_DIR/utils/core.sh"

set_hostname() {
  echo "[set_hostname] Set hostname based on devices.yaml"

  if ! "$SCRIPT_DIR/hostname/set-hostname.sh"; then
    echo "[set_hostname] Failed to set hostname" >&2
  fi
}

dnf_up() {
  echo "[dnf_up] Update packages"
  sudo dnf up -y --refresh
}

rpm_fusion() {
  echo "[rpm_fusion] Enable RPM Fusion Free and Nonfree"

  local fedora_version
  fedora_version="$(rpm -E %fedora)"

  sudo dnf in -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$fedora_version.noarch.rpm
  sudo dnf in -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$fedora_version.noarch.rpm
}

repos() {
  echo "[repos] Enable additional repositories"

  local repos_file="$GENERAL_PKGS_DIR/repos.txt"
  local repos=($(util_read_package_list "$repos_file"))

  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "[repos] No additional repositories to enable"
    return
  fi

  echo "[repos] Enabling ${#repos[@]} additional repository(ies)..."
  for repo in "${repos[@]}"; do
    sudo dnf config-manager addrepo --from-repofile="$repo"
  done
}

copr() {
  echo "[copr] Enable COPR repositories"

  local copr_file="$GENERAL_PKGS_DIR/copr.txt"
  local repos=($(util_read_package_list "$copr_file"))

  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "[copr] No COPR repositories to enable"
    return
  fi

  echo "[copr] Enabling ${#repos[@]} COPR repository(ies)..."

  for repo in "${repos[@]}"; do
    sudo dnf copr enable -y "$repo"
  done
}

dnf_install() {
  echo "[dnf_install] Install DNF packages"

  local pkg_file="$GENERAL_PKGS_DIR/dnf.txt"
  local packages=($(util_read_package_list "$pkg_file"))

  echo "[dnf_install] Installing ${#packages[@]} package(s) with dnf..."
  sudo dnf in -y --allowerasing "${packages[@]}"
}

codecs() {
  # https://rpmfusion.org/Howto/Multimedia

  local prefix="[codecs]"

  echo "$prefix Switch to full ffmpeg"
  sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

  echo "$prefix Install additional codecs"
  sudo dnf group install -y multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

  echo "$prefix Install packages for DVD"
  sudo dnf install -y rpmfusion-free-release-tainted
  sudo dnf --repo=rpmfusion-free-tainted install -y libdvdcss

  echo "$prefix Install various firmwares from nonfree tainted"
  sudo dnf install -y rpmfusion-nonfree-release-tainted
  sudo dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"

  echo "$prefix Delete GStreamer registry cache to fix H265/E-AC-3 playback"
  rm -f ~/.cache/gstreamer-1.0/registry.x86_64.bin
}

flatpak_install() {
  local prefix="[flatpak_install]"

  echo "$prefix Enable Flathub"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  echo "$prefix Installing Flatpak packages"

  local pkg_file="$GENERAL_PKGS_DIR/flatpak.txt"
  local packages=($(util_read_package_list "$pkg_file"))

  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "$prefix No packages to install"
    return
  fi

  echo "$prefix Installing ${#packages[@]} package(s) with flatpak..."
  for package in "${packages[@]}"; do
    flatpak install -y flathub "$package"
  done
}

snap_install() {
  local prefix="[snap_install]"

  echo "$prefix Install Snap packages"

  local pkg_file="$GENERAL_PKGS_DIR/snap.txt"
  local packages=($(util_read_package_list "$pkg_file"))

  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "$prefix No packages to install"
    return
  fi

  echo "$prefix Enabling snapd service..."
  sudo systemctl enable --now snapd.socket
  sudo ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true

  echo "$prefix Waiting for snapd to finish seeding..."
  if ! timeout 600 sudo snap wait system seed.loaded; then
    echo "$prefix snapd did not finish seeding in time" >&2
    return 1
  fi

  echo "$prefix Installing ${#packages[@]} package(s) with snap..."
  for package in "${packages[@]}"; do
    sudo snap install "$package"
  done
}

system_services() {
  local prefix="[system_services]"

  echo "$prefix Enable system services"

  sudo systemctl enable --now NetworkManager
  sudo systemctl enable --now bluetooth

  systemctl --user enable --now \
    pipewire.socket \
    pipewire-pulse.socket \
    wireplumber.service
}

niri_dms() {
  local prefix="[niri_dms]"

  echo "$prefix Attach DMS to the Niri user service"
  systemctl --user daemon-reload
  systemctl --user add-wants niri.service dms

  echo "$prefix Enable and start the Dsearch user indexer"
  systemctl --user enable --now dsearch.service
}

dms_greeter() {
  local prefix="[dms_greeter]"

  if ! command -v dms-greeter >/dev/null 2>&1; then
    echo "$prefix dms-greeter is not installed" >&2
    return 1
  fi

  echo "$prefix Install and enable DMS Greeter"
  DMS_PRIVESC=sudo dms-greeter install --yes
}

# Symlink the system CA bundle to the location expected by some tools, if not already set up.
ca_bundle_symlink() {
  local prefix="[ca_bundle_symlink]"

  echo "$prefix Set up /etc/pki/tls/certs/ca-bundle.crt symlink"

  local target="/etc/pki/tls/certs/ca-bundle.crt"
  local source="/etc/ssl/certs/ca-bundle.crt"

  # If target already exists, exit.
  if [[ -e "$target" ]]; then
    echo "$prefix $target already exists, skipping symlink setup"
    return
  fi

  # If source doesn't exist, warn and exit.
  if [[ ! -e "$source" ]]; then
    echo "$prefix Warning: source CA bundle not found at $source. Cannot create symlink at $target." >&2
    return 1
  fi

  sudo ln -s "$source" "$target"

  echo "$prefix Created symlink from $source to $target"
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

  # https://zed.dev/docs/installation
  curl -fsSL https://zed.dev/install.sh | sh
}

oh_my_zsh() {
  echo "[oh_my_zsh] Install oh-my-zsh"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "oh-my-zsh is already installed at $HOME/.oh-my-zsh"
  else
    sh -c "$(curl -fsSL $OH_MY_ZSH_INSTALL_URL)"
  fi
}

oh_my_zsh_plugins() {
  local plugins="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

  echo "[oh_my_zsh_plugins] Install zsh-nvm"
  git clone https://github.com/lukechilds/zsh-nvm "$plugins/zsh-nvm"

  echo "[oh_my_zsh_plugins] Install zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins/zsh-autosuggestions"
}

starship_install() {
  local prefix="[starship]"
  echo "$prefix Install starship prompt"

  if command -v starship &>/dev/null; then
    echo "$prefix starship is already installed at $(command -v starship)"
  else
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi
}

node_install() {
  local prefix="[node_install]"

  echo "$prefix Removing Node packages and installing NVM, PNPM"
  sudo dnf remove -y nodejs nodejs-docs nodejs-full-i18n nodejs-npm

  # Install NVM if not already installed in ~/.nvm
  if [[ -d "$HOME/.nvm" ]]; then
    echo "$prefix NVM is already installed"
  else
    echo "$prefix Installing NVM"
    curl -o- "$NVM_INSTALL_URL" | bash
  fi

  # Load NVM
  local nvm_dir="$HOME/.nvm"
  [ -s "$nvm_dir/nvm.sh" ] && \. "$nvm_dir/nvm.sh"

  echo "$prefix Installing latest LTS version of Node via NVM"
  nvm install --lts

  echo "$prefix Setting LTS as default Node version"
  nvm use --lts
  nvm alias default node

  echo "$prefix Installing PNPM globally via NPM"
  npm install -g pnpm

  echo "$prefix Set up PNPM global packages directory"
  pnpm setup
}

us_pt_keyboard_layout() {
  echo "[us_pt_keyboard_layout] Install the us-pt keyboard layout"

  local layout_dir="$HOME/us-pt-keyboard-layout"

  if [[ ! -d "$layout_dir" ]]; then
    echo "[us_pt_keyboard_layout] Attempting to clone us-pt-keyboard-layout via SSH..."

    if ! git clone "git@github.com:$US_PT_KEYBOARD_LAYOUT_GITHUB_SUFFIX" "$layout_dir"; then
      echo "[us_pt_keyboard_layout] Failed to clone via SSH. Attempting via HTTPS..."

      if ! git clone "https://github.com/$US_PT_KEYBOARD_LAYOUT_GITHUB_SUFFIX" "$layout_dir"; then
        echo "[us_pt_keyboard_layout] Failed to clone us-pt-keyboard-layout via HTTPS."
        return 1
      fi
    fi
  fi

  local install_script="$layout_dir/linux/install.sh"

  if [[ -f "$install_script" ]]; then
    echo "[us_pt_keyboard_layout] Running install script at $install_script"
    sudo bash "$install_script"
  else
    echo "[us_pt_keyboard_layout] Install script not found at $install_script"
    return 1
  fi
}

snapper() {
  echo "[snapper] Configure snapper for Btrfs snapshots"

  # Create a snapper config for the root filesystem
  if sudo snapper list | grep -q "^root[[:space:]]"; then
    echo "[snapper] Snapper config for root already exists"
  else
    echo "[snapper] Creating snapper config for root"
    sudo snapper -c root create-config /
  fi

  # Set up automatic snapshots via systemd timers
  echo "[snapper] Enabling snapper-timeline.timer and snapper-cleanup.timer"
  sudo systemctl enable --now snapper-timeline.timer
  sudo systemctl enable --now snapper-cleanup.timer
}

aliases() {
  echo "[aliases] Symlink aliases/.aliases to ~/.aliases"

  local target="$HOME/.aliases"
  local source="$ALIASES_DIR/.aliases"

  if [[ -L "$target" ]]; then
    if [[ "$(readlink "$target")" == "$source" ]]; then
      echo "[aliases] Alias file is already correctly symlinked"
      return
    else
      echo "[aliases] Alias file is a symlink to the wrong location. Removing."
      rm "$target"
    fi
  elif [[ -e "$target" ]]; then
    echo "[aliases] Alias file already exists and is not a symlink. Please remove or rename $target and re-run this step."
    return
  fi

  ln -s "$source" "$target"
  echo "[aliases] Symlinked $source to $target"
}

blex_mono_nerd_font() {
  echo "[blex_mono_nerd_font] Install Blex Mono Nerd Font"

  local font_name="BlexMonoNerdFont"
  local font_dir="/usr/local/share/fonts/$font_name"

  util_install_font "[blex_mono_nerd_font]" "$font_name" "$BLEX_MONO_NERD_FONT_URL" "$font_dir"
}

set_fonts() {
  local font_option="${1:-}"
  local monospace_font
  local sans_serif_font

  case "$font_option" in
  ibm_plex)
    monospace_font="Blex Mono Nerd Font"
    sans_serif_font="IBM Plex Sans"
    serif_font="IBM Plex Serif"
    ;;
  *)
    echo "Usage: set_fonts {ibm_plex}" >&2
    return 2
    ;;
  esac

  local prefix="[set_fonts $font_option]"
  local config_dir="$HOME/.config/fontconfig/conf.d"
  mkdir -p "$config_dir"

  cat >"$config_dir/99-monospace.conf" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>$monospace_font</family>
    </prefer>
  </alias>
</fontconfig>
EOF

  cat >"$config_dir/99-sans-serif.conf" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>$sans_serif_font</family>
    </prefer>
  </alias>
</fontconfig>
EOF

  cat >"$config_dir/99-serif.conf" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>serif</family>
    <prefer>
      <family>$serif_font</family>
    </prefer>
  </alias>
</fontconfig>
EOF

  sudo fc-cache -fv

  echo "$prefix Set monospace to $monospace_font"
  echo "$prefix Set sans-serif to $sans_serif_font"
  echo "$prefix Set serif to $serif_font"
}

set_fonts_ibm_plex() { set_fonts ibm_plex; }

jellyfin() {
  echo "[jellyfin] Set up Jellyfin media server"

  # Create user "shows" and "films" directories in Videos, if needed
  mkdir -p "$SHOWS_DIR"
  mkdir -p "$FILMS_DIR"

  # Create directories for Jellyfin media
  sudo mkdir -p "$JELLYFIN_SHOWS_DIR"
  sudo mkdir -p "$JELLYFIN_FILMS_DIR"

  # Ensure fstab entries exist (bind mounts)
  FSTAB_LINE_SHOWS="$SHOWS_DIR $JELLYFIN_SHOWS_DIR none bind 0 0"
  FSTAB_LINE_FILMS="$FILMS_DIR $JELLYFIN_FILMS_DIR none bind 0 0"

  grep -qsF "$FSTAB_LINE_SHOWS" /etc/fstab ||
    echo "$FSTAB_LINE_SHOWS" | sudo tee -a /etc/fstab

  grep -qsF "$FSTAB_LINE_FILMS" /etc/fstab ||
    echo "$FSTAB_LINE_FILMS" | sudo tee -a /etc/fstab

  # Mount everything from fstab (applies immediately)
  sudo mount -a

  # Give jellyfin user read + traverse access via ACL (cleaner than chmod o+x)
  if id jellyfin &>/dev/null; then
    sudo setfacl -R -m u:jellyfin:rx "$SHOWS_DIR" "$FILMS_DIR"
    sudo setfacl -m u:jellyfin:x "$VIDEOS_DIR" "$HOME"
  else
    echo "[jellyfin] Warning: jellyfin user not found, skipping ACL setup"
  fi

  echo "[jellyfin] Done"
}

stow_apply() {
  local prefix="[stow_apply]"
  local -a stow_flags=(--restow --no-folding)
  local dry_run=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -n | --no | --simulate)
      dry_run=1
      stow_flags+=(--simulate --verbose)
      ;;
    --adopt)
      stow_flags+=(--adopt)
      ;;
    *)
      echo "$prefix Unknown option: $1 (supported: -n, --no, --simulate, --adopt)" >&2
      return 2
      ;;
    esac
    shift
  done

  if ((dry_run)); then
    echo "$prefix DRY RUN: no changes will be made"
  fi

  echo "$prefix Symlink stow-managed dotfiles to home directory"

  local stow_bin
  stow_bin="$(type -P stow || true)"

  if [[ -z "$stow_bin" ]]; then
    echo "$prefix GNU Stow is not installed. Install it first and re-run this step." >&2
    return 1
  fi

  if [[ ! -d "$STOW_DIR" ]]; then
    echo "$prefix Stow directory not found at $STOW_DIR" >&2
    return 1
  fi

  local -a packages=()
  local package

  while IFS= read -r package; do
    [[ -n "$package" ]] && packages+=("$package")
  done < <(find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "$prefix No stow packages found in $STOW_DIR"
    return 0
  fi

  echo "$prefix Stowing ${#packages[@]} package(s) from $STOW_DIR into $HOME"

  local failed=0

  for package in "${packages[@]}"; do
    local package_target="$HOME"

    if [[ "$package" == .* ]]; then
      package_target="$HOME/$package"
    fi

    echo "$prefix Stowing package: $package"
    "$stow_bin" "${stow_flags[@]}" --dir "$STOW_DIR" --target "$package_target" "$package" ||
      {
        echo "$prefix Failed to stow package: $package" >&2
        failed=1
      }
  done

  return "$failed"
}

usage() {
  cat <<EOF
Usage: $0 [-s "step1,step2" | -s "name1,name2"] [-- step-arguments...] [-l]

Options:
  -s, --steps   Comma-separated list of steps to run. Accepts either descriptive names or (deprecated) numbers.
                Steps run in the default order; duplicates are ignored.
                Examples: -s "dnf_up" or -s "2,3"
  --            Stop parsing installer options and pass the remaining arguments to each selected step.
                Arguments not matching an installer option are also forwarded, for convenience.
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

# Parse args
STEPS_ARG=""
LIST_ONLY=false
declare -a STEP_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  -s | --steps)
    if [[ -n "${2-}" ]]; then
      STEPS_ARG="$2"
      shift 2
      continue
    else
      echo "Error: --steps requires an argument" >&2
      usage
      exit 2
    fi
    ;;
  -l | --list)
    LIST_ONLY=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    STEP_ARGS+=("$@")
    break
    ;;
  *)
    STEP_ARGS+=("$1")
    shift
    ;;
  esac
done

if [[ "$LIST_ONLY" == true ]]; then
  usage
  exit 0
fi

# Build ordered list of steps to run (names)
declare -a RUN_STEPS=()
if [[ -z "$STEPS_ARG" ]]; then
  RUN_STEPS=("${ALL_STEPS[@]}")
else
  declare -A requested=()
  IFS=',' read -ra raw <<<"$STEPS_ARG"
  for token in "${raw[@]}"; do
    # trim whitespace
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
      # Validate name is in ALL_STEPS
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
  # Maintain default order and dedupe
  for name in "${ALL_STEPS[@]}"; do
    if [[ -n "${requested[$name]+x}" ]]; then
      RUN_STEPS+=("$name")
    fi
  done
fi

# Dispatch by name with validation
for s in "${RUN_STEPS[@]}"; do
  if declare -F "$s" >/dev/null; then
    "$s" "${STEP_ARGS[@]}"
  else
    echo "Unknown step function: $s" >&2
    exit 3
  fi
done
