# Migrate from Fedora Workstation

Run these commands to move an existing installation in `fedora-workstation` to `fedora-dotfiles`:

```bash
old="$HOME/fedora-workstation"
new="$HOME/fedora-dotfiles"

# Remove symlinks managed by the old checkout.
while IFS= read -r package; do
  target="$HOME"
  [[ "$package" == .* ]] && target="$HOME/$package"
  stow -D --dir "$old/stow" --target "$target" "$package"
done < <(find "$old/stow" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

# Rename the repo's dir and update the origin
mv "$old" "$new"
git -C "$new" remote set-url origin https://github.com/tomecarvalho/fedora-dotfiles.git
git -C "$new" fetch origin
git -C "$new" switch --force-create main origin/main

# Re-create links from the new checkout.
"$new/scripts/install/general.sh" -s stow_apply
```

If `~/.aliases` still points to the old checkout, recreate it:

```bash
rm -f "$HOME/.aliases"
"$new/scripts/install/general.sh" -s aliases
```
