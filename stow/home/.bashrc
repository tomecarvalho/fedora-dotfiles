# .bashrc
# shellcheck disable=SC1090,SC1091

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Shared environment, PATH and aliases (also used by .zshrc)
[ -f ~/.shellrc ] && . ~/.shellrc

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# NVM (zsh gets it lazily through the zsh-nvm plugin; bash needs it sourced)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
