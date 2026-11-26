#!/usr/bin/env bash

# Yazi shell wrapper for bash and zsh.
# Provides the ability to change the current working directory when exiting Yazi.
# https://yazi-rs.github.io/docs/quick-start/#shell-wrapper
function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}