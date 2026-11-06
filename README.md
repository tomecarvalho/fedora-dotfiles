# fedora-dotfiles

Fedora Linux dotfiles and post-install scripts, to be applied following a minimal installation via the [Fedora Everything](https://fedoraproject.org/misc/#everything) installer.

- Window manager: [Niri](https://github.com/niri-wm/niri)
- Shell: [Dux Modular Shell](https://duxlabs.dev/)

Initial Fedora version: 45.

## Aliases

Public aliases reside in [aliases/.aliases](aliases/.aliases) and are meant to be sourced from shell configs. The comments in the file explain the purpose of each alias.

## Packages

Package lists contain system packages (DNF), Flatpaks and Snaps.

| Package List                           | Description                                        |
| -------------------------------------- | -------------------------------------------------- |
| [packages/general/](packages/general/) | Packages installed on the minimal Niri/DMS system. |
| [packages/work/](packages/work/)       | Packages that are only necessary for work.         |
| [packages/remove/](packages/remove/)   | Unnecessary packages to remove if present.         |

## Scripts

| Script                                                       | Description                                                                                    |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| [install](scripts/install.sh)                                | General installation script. Supports step parameter to run specific steps in isolation.       |
| [install-work](scripts/install-work.sh)                      | Work-specific installation script. Supports step parameter to run specific steps in isolation. |
| [update](scripts/update.sh)                                  | Creates a Snapper Btrfs snapshot, then updates DNF packages, Flatpaks, and Snaps.              |
| [backup-home](scripts/backup/backup-home.sh)                 | Backup select directories and files from the home directory.                                   |
| [backup-projects](scripts/backup/backup-projects.sh)         | Backup a project directory, excluding package manager caches and dependencies.                 |
| [sync-local](scripts/backup/sync-local.sh)                   | Sync the same home/project paths to another local-network machine over SSH (sender wins).      |
| [default-boot-windows](scripts/grub/default-boot-windows.sh) | Sets Windows Boot Manager as the default GRUB entry when detected.                             |
| [nvidia-drivers](scripts/nvidia-drivers.sh)                  | Helps set up NVIDIA GPU drivers.                                                               |
| [secure-boot-key](scripts/secure-boot-key.sh)                | Helps with Secure Boot key setup.                                                              |
| [files-copy](scripts/files/copy.sh)                          | Copies files to the Wayland clipboard.                                                         |
| [files-cut](scripts/files/cut.sh)                            | Cuts files to the Wayland clipboard.                                                           |
| [files-paste](scripts/files/paste.sh)                        | Pastes files from the Wayland clipboard into a directory.                                      |
| [core](scripts/utils/core.sh)                                | Core utility helpers shared by shell scripts.                                                  |
| [git](scripts/utils/git.sh)                                  | Git-specific utility helpers shared by shell scripts.                                          |
| [packages](scripts/utils/packages.sh)                        | Package list utility helpers.                                                                  |
