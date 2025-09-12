starship init fish | source
zoxide init fish | source
atuin init fish | source

# Set up fzf key bindings
fzf --fish | source

direnv hook fish | source
pyenv init - fish | source

uv generate-shell-completion fish | source

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/zachfuller/.lmstudio/bin
# End of LM Studio CLI section

# mise
mise activate fish | source

# AWS
set -x AWS_DEFAULT_REGION "us-west-1"

# eza aliases (parity with zsh)
function ls
	eza --color=always --group-directories-first --icons=always $argv
end

function ll
	eza -la --icons=always --octal-permissions --group-directories-first $argv
end

function l
	eza -bGF --header --git --color=always --group-directories-first --icons=always $argv
end

function llm
	eza -lbGd --header --git --sort=modified --color=always --group-directories-first --icons=always $argv
end

function la
	eza --long --all --group --group-directories-first $argv
end

function lx
	eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons=always $argv
end

function lS
	eza -1 --color=always --group-directories-first --icons=always $argv
end

function lt
	eza --tree --level=2 --color=always --group-directories-first --icons=always $argv
end

function l.
	eza -a | grep -E '^\.'
end
