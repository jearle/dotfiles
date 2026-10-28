# zoxide: shell-agnostic init, safe for interactive and non-interactive shells
command -v zoxide >/dev/null 2>&1 || return 0
if [ -n "$ZSH_VERSION" ]; then
  eval "$(zoxide init zsh)"
elif [ -n "$BASH_VERSION" ]; then
  eval "$(zoxide init bash)"
fi
