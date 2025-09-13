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

# Secrets from macOS Keychain
# Load GitHub MCP token from Keychain if present
set -l __gh_token (security find-generic-password -s "Github-PAC-OpenCode" -w 2>/dev/null)
if test -n "$__gh_token"
	set -gx GITHUB_MCP_TOKEN "$__gh_token"
else
	# Show a warning in interactive shells if the token is missing
	if status --is-interactive
		set_color red
		echo "Warning: GITHUB_MCP_TOKEN not found in Keychain (service 'Github-PAC-OpenCode')"
		set_color normal
	end
end

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

function fish_greeting
    fastfetch -c examples/10.jsonc
end

