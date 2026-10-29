#!/bin/sh
# 1-command install: public pass, bw login/unlock to locker, secrets pass.
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/jearle/dotfiles/main/install.sh)"
# DOTFILES_REF=<branch>    install from a branch instead of main
# DOTFILES_SKIP_SECRETS=1  stop after the public pass
set -eu

bin="$HOME/.local/bin"
export PATH="$bin:$HOME/.local/share/mise/shims:$PATH"

step() { printf '\n==> %s\n\n' "$1"; }

step "1/3 chezmoi"
if [ ! -x "$bin/chezmoi" ]; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin"
fi

step "2/3 public pass: tools, packages, config"
source_dir="$("$bin/chezmoi" source-path 2>/dev/null || true)"
if [ -n "$source_dir" ] && [ -d "$source_dir/.git" ]; then
  "$bin/chezmoi" git -- pull --ff-only
  "$bin/chezmoi" apply
else
  set -- init --apply --use-builtin-git true
  if [ -n "${DOTFILES_REF:-}" ]; then
    set -- "$@" --branch "$DOTFILES_REF"
  fi
  "$bin/chezmoi" "$@" jearle
fi

if [ "${DOTFILES_SKIP_SECRETS:-}" = 1 ]; then
  printf '\nDone (secrets skipped).\n'
  exit 0
fi

step "3/3 secrets pass: ssh config, ssh keys, shell secrets, WireGuard"
if ! curl -fsS --max-time 10 -o /dev/null https://locker.jesseearle.com/alive; then
  echo "locker.jesseearle.com unreachable: run this at home." >&2
  exit 1
fi
# bw prompts on the terminal; only the session key is captured.
if mise exec -- bw status | grep -q '"status":"unauthenticated"'; then
  BW_SESSION="$(mise exec -- bw login --raw)"
else
  BW_SESSION="$(mise exec -- bw unlock --raw)"
fi
export BW_SESSION
"$bin/chezmoi" apply
mise exec -- bw lock

printf '\nDone. Open a new shell.\n'
