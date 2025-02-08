# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.bin:/usr/local/bin:$HOME/.local/bin:$PATH

export XDG_CONFIG_HOME=$HOME/.config

# homebrew
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

# nvm
zstyle ':omz:plugins:nvm' lazy yes
# antidote
zstyle ':antidote:bundle' use-friendly-names 'yes'
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh
# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

fpath+=~/.zfunc

export ZSH=$(antidote path ohmyzsh/ohmyzsh)

# zsh-autosuggestions
bindkey '^ ' autosuggest-accept
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-autocomplete
source $HOME/.bin/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# Don't show suggesstions for git commands
zstyle ':autocomplete:*' ignored-input 'git *'
zstyle -e ':autocomplete:*:*' list-lines 'reply=( $(( LINES / 3 )) )'
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
zstyle ':autocomplete:*history*:*' insert-unambiguous yes
zstyle ':autocomplete:menu-search:*' insert-unambiguous yes

# PATH fix from SO https://stackoverflow.com/questions/39311147/cannot-run-npm-commands
export PATH=$(echo "$PATH" | sed -e 's/:\/mnt[^:]*//g')
alias python=python3
alias fd=fdfind

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# pnpm
export PNPM_HOME="/Users/zachfuller/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Load Angular CLI autocompletion.
# source <(ng completion script)

# zoxide
eval "$(zoxide init zsh)"

# add ~/bin to PATH
export PATH="~/bin:$PATH"

# AWS
export AWS_DEFAULT_REGION="us-west-1"

# starship
eval "$(starship init zsh)"

# fzf
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--layout=reverse --inline-info"

# neovim
export PATH=/opt/nvim-linux64/bin:$PATH

# direnv
eval "$(direnv hook zsh)"

# zellij
export ZELLIJ_CONFIG_DIR=$XDG_CONFIG_HOME/zellij

# java
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

#iterm2 shell integration
# test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

alias cd="z"
alias clear="clear -x"
# eza aliases
alias ls='eza --color=always --group-directories-first --icons'
alias ll='eza -la --icons --octal-permissions --group-directories-first'
alias l='eza -bGF --header --git --color=always --group-directories-first --icons'
alias llm='eza -lbGd --header --git --sort=modified --color=always --group-directories-first --icons' 
alias la='eza --long --all --group --group-directories-first'
alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons'

alias lS='eza -1 --color=always --group-directories-first --icons'
alias lt='eza --tree --level=2 --color=always --group-directories-first --icons'
alias l.="eza -a | grep -E '^\.'"

# fastfetch
fastfetch -c examples/10.jsonc
