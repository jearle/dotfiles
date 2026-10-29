#!/bin/sh
# 1-command install: public pass, bw login/unlock to locker, secrets pass.
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/jearle/dotfiles/main/install.sh)"
# DOTFILES_REF=<branch>    install from a branch instead of main
# DOTFILES_SKIP_SECRETS=1  stop after the public pass
set -eu

bin="$HOME/.local/bin"
export PATH="$bin:$HOME/.local/share/mise/shims:$PATH"

# Public pass: packages, config, tools. Prompts (sudo, CLT) read the terminal.
if [ ! -x "$bin/chezmoi" ]; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin"
fi
set -- init --apply --use-builtin-git true
if [ -n "${DOTFILES_REF:-}" ]; then
  set -- "$@" --branch "$DOTFILES_REF"
fi
"$bin/chezmoi" "$@" jearle </dev/tty

if [ "${DOTFILES_SKIP_SECRETS:-}" = 1 ]; then
  echo "Public pass done; secrets skipped (DOTFILES_SKIP_SECRETS=1)."
  exit 0
fi

# Secrets pass: needs locker.jesseearle.com (home LAN or WireGuard).
if ! curl -fsS --max-time 10 -o /dev/null https://locker.jesseearle.com/alive; then
  echo "locker.jesseearle.com unreachable: run this at home." >&2
  exit 1
fi

if mise exec -- bw status | grep -q '"status":"unauthenticated"'; then
  echo "Log in to locker (Bitwarden):"
  BW_SESSION="$(mise exec -- bw login --raw </dev/tty)"
else
  echo "Unlock locker (Bitwarden):"
  BW_SESSION="$(mise exec -- bw unlock --raw </dev/tty)"
fi
export BW_SESSION

"$bin/chezmoi" apply </dev/tty
mise exec -- bw lock >/dev/null
echo "Done. Open a new shell."
