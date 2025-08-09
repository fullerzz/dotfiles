starship init fish | source
zoxide init fish | source

# Set up fzf key bindings
fzf --fish | source

direnv hook fish | source
pyenv init - fish | source

uv generate-shell-completion fish | source

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/zachfuller/.lmstudio/bin
# End of LM Studio CLI section

