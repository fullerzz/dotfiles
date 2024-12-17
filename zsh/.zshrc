# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# zsh-autocomplete
source $HOME/.bin/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# Don't show suggesstions for git commands
zstyle ':autocomplete:*' ignored-input 'git *'
zstyle -e ':autocomplete:*:*' list-lines 'reply=( $(( LINES / 4 )) )'

# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(git zsh-autosuggestions)

bindkey '^ ' autosuggest-accept
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH/oh-my-zsh.sh

# User configuration
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=/usr/local/go/bin:$GOPATH/bin:/home/zach/.local/bin:$PATH
# PATH fix from SO https://stackoverflow.com/questions/39311147/cannot-run-npm-commands
export PATH=$(echo "$PATH" | sed -e 's/:\/mnt[^:]*//g')
alias python=python3

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

#autoload -U +X bashcompinit && bashcompinit
#complete -o nospace -C /usr/bin/terraform terraform

# bun completions
[ -s "/home/zach/.bun/_bun" ] && source "/home/zach/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# zoxide
eval "$(zoxide init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# pnpm
export PNPM_HOME="/home/zach/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# add ~/bin to PATH
export PATH="~/bin:$PATH"

# alias for tofu tflocal
export TF_CMD=tofu

# AWS
export AWS_DEFAULT_REGION="us-west-1"

# starship
function set_win_title(){
    echo -ne "\033]0; $(basename "$PWD") \007"
}
precmd_functions+=(set_win_title)
eval "$(starship init zsh)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# neovim
export PATH=/opt/nvim-linux64/bin:$PATH

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
fastfetch
