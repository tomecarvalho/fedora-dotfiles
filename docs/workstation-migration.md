# Migrate from Fedora Workstation

## Command

Run this command to move an existing installation in `fedora-workstation` to
`fedora-dotfiles`:

```bash
set -euo pipefail

OLD="$HOME/fedora-workstation"
NEW="$HOME/fedora-dotfiles"
REPOSITORY_URL="https://github.com/tomecarvalho/fedora-dotfiles.git"

if [[ -d "$OLD" && -e "$NEW" ]]; then
  echo "Error: both $OLD and $NEW exist. Remove or rename one before continuing." >&2
  exit 1
fi

if [[ -d "$OLD" ]]; then
  if ! command -v stow >/dev/null 2>&1; then
    echo "Error: GNU Stow is required to remove the OLD stow links." >&2
    exit 1
  fi

  while IFS= read -r package; do
    target="$HOME"
    [[ "$package" == .* ]] && target="$HOME/$package"
    stow -D --dir "$OLD/stow" --target "$target" "$package"
  done < <(find "$OLD/stow" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

  mv "$OLD" "$NEW"
elif [[ ! -d "$NEW" ]]; then
  echo "Error: neither $OLD nor $NEW exists." >&2
  exit 1
fi

git -C "$NEW" remote set-url origin "$REPOSITORY_URL"
git -C "$NEW" fetch origin
git -C "$NEW" reset --hard origin/main
git -C "$NEW" switch -C main origin/main

# Repair this before re-stowing if a previous run was interrupted.
rm -f "$HOME/.aliases"
ln -s "$NEW/aliases/.aliases" "$HOME/.aliases"

"$NEW/scripts/install/general.sh" -s stow_apply

echo "Migration complete: $NEW"
```

The command removes old Stow links, renames `~/fedora-workstation` to
`~/fedora-dotfiles` (if needed), updates the remote, and resets the checkout to
`origin/main`. It also switches to `main`, repairs `.aliases`, and re-stows the
configuration.

Local tracked changes are discarded.

## Validate Migration

Run these checks:

```bash
test ! -e "$HOME/fedora-workstation" && echo "Old directory removed"
test -d "$HOME/fedora-dotfiles" && echo "New directory exists"
git -C "$HOME/fedora-dotfiles" remote get-url origin
git -C "$HOME/fedora-dotfiles" branch --show-current
git -C "$HOME/fedora-dotfiles" status --short
git -C "$HOME/fedora-dotfiles" rev-parse HEAD origin/main
readlink "$HOME/.aliases"
```

- Remote should be the `fedora-dotfiles` URL
- Current branch should be `main`
- `git status --short` should print nothing
- Commit hashes should match
- `.aliases` link should point inside `~/fedora-dotfiles`
