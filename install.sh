#!/bin/sh
# 1-command install: public pass, bw login/unlock to locker, secrets pass.
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/jearle/dotfiles/main/install.sh)"
# DOTFILES_REF=<branch>    install from a branch instead of main
# DOTFILES_SKIP_SECRETS=1  stop after the public pass
set -eu

bin="$HOME/.local/bin"
export PATH="$bin:$HOME/.local/share/mise/shims:$PATH"

step() { printf '\n==> %s\n\n' "$1"; }

# Copy every existing file chezmoi would change, before it changes it.
backup_dir="$HOME/.local/state/dotfiles/backup-$(date +%Y%m%dT%H%M%S)"
backup() {
  "$bin/chezmoi" status | cut -c4- | while IFS= read -r path; do
    target="$HOME/$path"
    if [ -f "$target" ] || [ -L "$target" ]; then
      mkdir -p "$backup_dir/$(dirname "$path")"
      cp -P -p "$target" "$backup_dir/$path"
      echo "backed up ~/$path"
    fi
  done
}

# sudo once: ask now, keep the timestamp fresh until this script exits.
sudo -v
( while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 60; done ) 2>/dev/null &

step "1/3 chezmoi"
if [ ! -x "$bin/chezmoi" ]; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin"
fi

step "2/3 public pass: tools, packages, config"
# Apple's git needs the Command Line Tools; before they exist, re-clone with
# chezmoi's built-in git instead of pulling (the clone holds no local edits).
git_usable() { [ "$(uname -s)" != Darwin ] || xcode-select -p >/dev/null 2>&1; }

source_dir="$("$bin/chezmoi" source-path 2>/dev/null || true)"
if [ -n "$source_dir" ] && [ -d "$source_dir/.git" ] && ! git_usable; then
  rm -rf "$source_dir"
fi
if [ -n "$source_dir" ] && [ -d "$source_dir/.git" ]; then
  "$bin/chezmoi" git -- pull --ff-only
else
  set -- init --use-builtin-git true
  if [ -n "${DOTFILES_REF:-}" ]; then
    set -- "$@" --branch "$DOTFILES_REF"
  fi
  "$bin/chezmoi" "$@" jearle
fi
backup
"$bin/chezmoi" apply

if [ "${DOTFILES_SKIP_SECRETS:-}" = 1 ]; then
  [ -d "$backup_dir" ] && printf '\nReplaced files backed up to %s\n' "$backup_dir"
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
# The local vault copy may predate renames or new items.
mise exec -- bw sync >/dev/null
backup
"$bin/chezmoi" apply
mise exec -- bw lock

if [ -d "$backup_dir" ]; then
  printf '\nReplaced files backed up to %s\n' "$backup_dir"
fi
printf '\nDone. Open a new shell.\n'
