# Managed by setup_antidote_and_zsh.py
export PATH="$HOME/bin:$HOME/.bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

eval "$(mise activate zsh)"

# antidote
zstyle ':antidote:bundle' use-friendly-names 'yes'
source "$HOME/.antidote/antidote.zsh"

# Look for a file telling us it's been over a week since we last updated.
# If found, delete it so we know to run antidote update.
find "$(antidote home)" -maxdepth 1 -name '.up2date' -type f -mtime +7 -delete
if [[ ! -r $(antidote home)/.up2date ]]; then
  antidote update
  touch $(antidote home)/.up2date
fi

antidote load "$HOME/.zsh_plugins.txt"

fpath+=~/.zfunc
export ZSH="$(antidote path ohmyzsh/ohmyzsh)"

# zsh-autosuggestions
export ZSH_AUTOSUGGEST_COMPLETION_IGNORE="pnpm *"
#export ZSH_AUTOSUGGEST_STRATEGY=(atuin history completion)
bindkey '^ ' autosuggest-accept

# zsh-autocomplete
zstyle ':autocomplete:*' ignored-input 'git *'
zstyle ':autocomplete:*' delay 0.2  # seconds (float)
zstyle ':autocomplete:*' min-input 2
zstyle -e ':autocomplete:*:*' list-lines 'reply=( $(( LINES / 3 )) )'
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
zstyle ':autocomplete:*history*:*' insert-unambiguous yes
zstyle ':autocomplete:menu-search:*' insert-unambiguous yes

# starship
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh)"

# pnpm
export PNPM_HOME="/home/zach/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  if ! command -v gtimeout >/dev/null 2>&1; then
    eval "$(pyenv init -)"
  elif pyenv_init="$(gtimeout 5s pyenv init - 2>/dev/null)"; then
    eval "$pyenv_init"
  elif [[ $? -eq 124 ]]; then
    printf 'pyenv init timed out after 5 seconds; skipping shell integration\n' >&2
  fi
  unset pyenv_init
fi

export UV_MALWARE_CHECK=1
export OBSCURA_ALLOW_PRIVATE_NETWORK=1

# carapace
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
source <(carapace _carapace)

# atuin
eval "$(atuin init zsh)"

eval $(thefuck --alias)

alias cd="z"
alias clear="clear -x"
alias cat="bat -pp"
alias glow="glow -p"
#alias grep="rg"
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

fastfetch
