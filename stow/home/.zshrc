# Oh My ZSH
export ZSH="$HOME/.oh-my-zsh"

# Uncomment this so "omz update" doesn't fail
# Make sure it points to the correct location based on your cloned dotfiles' location
# oh-my-zsh-update.sh handles this automatically
# ZSH_CUSTOM="$HOME/dotfiles/stow/oh-my-zsh/.oh-my-zsh/custom/"

export NVM_LAZY_LOAD=true
plugins=(git zsh-nvm zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

# Shared environment, PATH and aliases (also used by .bashrc)
[ -f ~/.shellrc ] && . ~/.shellrc
typeset -U path

# Zoxide
eval "$(zoxide init zsh)"

# ZSH Syntax Highlighting
ZSH_SYNTAX_HIGHLIGHTING="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "$ZSH_SYNTAX_HIGHLIGHTING" ] && . "$ZSH_SYNTAX_HIGHLIGHTING"

# Starship prompt
eval "$(starship init zsh)"
