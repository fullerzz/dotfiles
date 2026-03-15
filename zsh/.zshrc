# bootstrap homebrew if not installed
if ! command -v brew &>/dev/null; then
  echo ">>> Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon path; Intel would be /usr/local
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
BREW_PREFIX=$(brew --prefix)

# If you come from bash you might have to change your $PATH.
export PATH="$BREW_PREFIX/opt/openssh/bin:$PATH"
export PATH=$HOME/bin:$HOME/.bin:/usr/local/bin:$HOME/.local/bin:$PATH
export PATH="$HOME/.bun/bin:$PATH"
export EDITOR="code --wait"
export XDG_CONFIG_HOME=$HOME/.config

# load secrets from OSX keychain
export GITHUB_MCP_TOKEN=$(security find-generic-password -s "Github-PAC-OpenCode" -w 2>/dev/null)
export GITHUB_TOKEN=$(security find-generic-password -s "GITHUB_TOKEN_CLASSIC" -w 2>/dev/null)

# homebrew completions
if type brew &>/dev/null; then
  FPATH=$BREW_PREFIX/share/zsh/site-functions:$FPATH
fi

# nvm
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript pnpm bun npx ng
# antidote
zstyle ':antidote:bundle' use-friendly-names 'yes'
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh
# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

fpath+=~/.zfunc

export ZSH=$(antidote path ohmyzsh/ohmyzsh)

# zsh-autosuggestions
export ZSH_AUTOSUGGEST_COMPLETION_IGNORE="pnpm *"
export ZSH_AUTOSUGGEST_STRATEGY=(atuin history completion)
bindkey '^ ' autosuggest-accept
source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-autocomplete
source $HOME/.bin/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# Don't show suggesstions for git commands
zstyle ':autocomplete:*' ignored-input 'git *'
zstyle ':autocomplete:*' delay 0.2  # seconds (float)
zstyle ':autocomplete:*' min-input 2
zstyle -e ':autocomplete:*:*' list-lines 'reply=( $(( LINES / 3 )) )'
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
zstyle ':autocomplete:*history*:*' insert-unambiguous yes
zstyle ':autocomplete:menu-search:*' insert-unambiguous yes

# PATH fix from SO https://stackoverflow.com/questions/39311147/cannot-run-npm-commands
export PATH=$(echo "$PATH" | sed -e 's/:\/mnt[^:]*//g')
alias python=python3

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
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
export PATH="$HOME/bin:$HOME/Go/bin:$PATH"

# AWS
export AWS_DEFAULT_REGION="us-west-1"

# starship
eval "$(starship init zsh)"

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules'
export FZF_DEFAULT_OPTS="--height ~90% --layout=reverse --inline-info --border"
# export FZF_DEFAULT_OPTS=" \
# --tmux 90% --layout=reverse --inline-info --border \
# --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
# --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
# --color=marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
# --color=selected-bg:#494d64 \
# --multi"
export FZF_CTRL_T_OPTS="
  --height ~90%
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
source <(fzf --zsh)


# direnv
eval "$(direnv hook zsh)"

# zellij
export ZELLIJ_CONFIG_DIR=$XDG_CONFIG_HOME/zellij

# java
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# borgboi completion
#eval "$(_BB_COMPLETE=zsh_source bb)"
#eval "$(_BORGBOI_COMPLETE=zsh_source borgboi)"

# atuin
eval "$(atuin init zsh)"

# mise
eval "$(mise activate zsh)"

# fnox
export FNOX_AGE_KEY_FILE="$HOME/.ssh/id_ed25519"
eval "$(fnox activate zsh)"

# docker
export COMPOSE_BAKE=true

#iterm2 shell integration
# test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# carapace
export LS_COLORS=$(vivid generate dracula)
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# Use Homebrew SSH with proper agent setup
# if ! pgrep -f "ssh-agent" > /dev/null; then
#     eval "$("$BREW_PREFIX"/bin/ssh-agent -s)" > /dev/null
# fi

# Auto-load YubiKey on shell start
# if [ -n "$SSH_AGENT_PID" ] && [ -f ~/.ssh/id_ed25519_sk ]; then
#     ssh-add -l | grep -q "ED25519-SK" || ssh-add ~/.ssh/id_ed25519_sk 2>/dev/null
# fi


eval $(thefuck --alias)
alias cd="z"
alias clear="clear -x"
alias grep="rg"
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

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section


# Amp CLI
export PATH="$HOME/.amp/bin:$PATH"
