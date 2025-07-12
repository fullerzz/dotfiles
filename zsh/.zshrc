# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.bin:/usr/local/bin:$HOME/.local/bin:/usr/local/go/bin:$PATH

export XDG_CONFIG_HOME=$HOME/.config

# nvm
zstyle ':omz:plugins:nvm' lazy yes
# antidote
zstyle ':antidote:bundle' use-friendly-names 'yes'
source $HOME/.antidote/antidote.zsh
# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

fpath+=~/.zfunc

export ZSH=$(antidote path ohmyzsh/ohmyzsh)

# zsh-autosuggestions
bindkey '^ ' autosuggest-accept
#source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-autocomplete
#source $HOME/.bin/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# Don't show suggesstions for git commands
zstyle ':autocomplete:*' ignored-input 'git *'
zstyle ':autocomplete:*' delay 0.2  # seconds (float)
zstyle ':autocomplete:*' min-input 3
zstyle -e ':autocomplete:*:*' list-lines 'reply=( $(( LINES / 3 )) )'
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
zstyle ':autocomplete:*history*:*' insert-unambiguous yes
zstyle ':autocomplete:menu-search:*' insert-unambiguous yes

# PATH fix from SO https://stackoverflow.com/questions/39311147/cannot-run-npm-commands
export PATH=$(echo "$PATH" | sed -e 's/:\/mnt[^:]*//g')
alias python=python3

#export PYENV_ROOT="$HOME/.pyenv"
#[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init -)"

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
export PATH="$HOME/go/bin:$PATH"

# AWS
export AWS_DEFAULT_REGION="us-west-1"

# starship
eval "$(starship init zsh)"

# fzf
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_DEFAULT_OPTS=" \
--tmux 90% --layout=reverse --inline-info --border \
--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
--color=selected-bg:#494d64 \
--multi"
export FZF_CTRL_T_OPTS="
  --style full
  --walker-skip .git,node_modules,target,.venv
  --preview 'bat -n --color=always {}'
  --border --padding 1,1
  --border-label ' fzf ' --input-label ' Input ' --header-label ' File Type ' \
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --bind 'result:transform-list-label:
      if [[ -z $FZF_QUERY ]]; then
        echo \" $FZF_MATCH_COUNT items \"
      else
        echo \" $FZF_MATCH_COUNT matches for [$FZF_QUERY] \"
      fi
      ' \
  --bind 'focus:transform-preview-label:[[ -n {} ]] && printf \" Previewing [%s] \" {}' \
  --bind 'focus:+transform-header:file --brief {} || echo \"No file selected\"' \
  "
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --group-directories-first --icons {} | head -200'"
export FZF_COMPLETION_OPTS='--border --info=inline'
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# direnv
eval "$(direnv hook zsh)"

# docker
export COMPOSE_BAKE=true
export UID=$(id -u)
export GID=$(id -g)

# borgboi
source $HOME/.borgboi-env

# zellij
#export ZELLIJ_CONFIG_DIR=$XDG_CONFIG_HOME/zellij

alias cd="z"
alias clear="clear -x"
# eza aliases
alias ls='eza --color=always --group-directories-first --icons=always $@'
alias ll='eza -la --icons=always --octal-permissions --group-directories-first'
alias l='eza -bGF --header --git --color=always --group-directories-first --icons=always'
alias llm='eza -lbGd --header --git --sort=modified --color=always --group-directories-first --icons=always' 
alias la='eza --long --all --group --group-directories-first'
alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons=always'

alias lS='eza -1 --color=always --group-directories-first --icons=always'
alias lt='eza --tree --level=2 --color=always --group-directories-first --icons=always'
alias l.="eza -a | grep -E '^\.'"

# fastfetch
fastfetch -c examples/10.jsonc

# nvm
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# atuin
export ATUIN_SYNC_ADDRESS="http://0.0.0.0:8888"
. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"


eval "$(/usr/bin/mise activate zsh)"
