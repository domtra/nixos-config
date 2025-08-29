# Zsh configuration for dom user
# Main shell configuration - managed via Stow

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt incappendhistory

# Basic zsh options
setopt autocd
setopt nomatch
setopt notify
setopt correct
setopt completealiases

# Key bindings
bindkey -e  # Emacs mode

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Modern CLI replacements
alias cat='bat'
alias ls='exa --icons'
alias find='fd'
alias grep='rg'
alias top='htop'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# System aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'

# Docker/Podman aliases
alias docker='podman'  # Use podman instead of docker locally

# Environment variables
export EDITOR='nvim'
export BROWSER='firefox'
export TERMINAL='alacritty'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Completion
autoload -Uz compinit
compinit

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Note: Starship prompt is configured via Home Manager
# Additional prompt customization can be done in ~/.config/starship.toml