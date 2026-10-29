#!/bin/sh
# 1-command install: public pass, bw login/unlock to locker, secrets pass.
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/jearle/dotfiles/main/install.sh)"
# DOTFILES_REF=<branch>    install from a branch instead of main
# DOTFILES_SKIP_SECRETS=1  stop after the public pass
# Output: step lines, prompts, and a summary; details go to the log file.
set -eu

bin="$HOME/.local/bin"
export PATH="$bin:$HOME/.local/share/mise/shims:$PATH"
log_dir="$HOME/.local/state/dotfiles"
mkdir -p "$log_dir"
log="$log_dir/install-$(date +%Y%m%dT%H%M%S).log"

step() { printf '\n==> %s\n' "$1"; }

# Run quietly into the log; on failure show the log tail and stop.
quiet() {
  if ! "$@" >>"$log" 2>&1 </dev/tty; then
    printf '✗ failed: %s\n  last lines of %s:\n' "$*" "$log"
    tail -n 20 "$log" | sed 's/^/  /'
    exit 1
  fi
}

step "1/4 chezmoi"
if [ ! -x "$bin/chezmoi" ]; then
  quiet sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin"
fi
echo "ok"

step "2/4 public pass: tools, packages, config (first run ~20 min; sudo may ask for your password)"
source_dir="$("$bin/chezmoi" source-path 2>/dev/null || true)"
if [ -n "$source_dir" ] && [ -d "$source_dir/.git" ]; then
  quiet "$bin/chezmoi" git -- pull --ff-only --quiet
  quiet "$bin/chezmoi" apply
else
  set -- init --apply --use-builtin-git true
  if [ -n "${DOTFILES_REF:-}" ]; then
    set -- "$@" --branch "$DOTFILES_REF"
  fi
  quiet "$bin/chezmoi" "$@" jearle
fi
echo "ok"

if [ "${DOTFILES_SKIP_SECRETS:-}" = 1 ]; then
  grep -E '^Failed:' "$log" | sed 's/^/  ✗ /' || true
  printf '\nDone (secrets skipped). Log: %s\n' "$log"
  exit 0
fi

step "3/4 locker login"
if ! curl -fsS --max-time 10 -o /dev/null https://locker.jesseearle.com/alive 2>>"$log"; then
  echo "✗ locker.jesseearle.com unreachable: run this at home."
  exit 1
fi
# bw prompts on the terminal; only the session key is captured.
if mise exec -- bw status 2>>"$log" | grep -q '"status":"unauthenticated"'; then
  BW_SESSION="$(mise exec -- bw login --raw </dev/tty 2>/dev/tty)"
else
  BW_SESSION="$(mise exec -- bw unlock --raw </dev/tty 2>/dev/tty)"
fi
export BW_SESSION
echo "ok"

step "4/4 secrets pass: ssh config, ssh keys, shell secrets, WireGuard"
quiet "$bin/chezmoi" apply
quiet mise exec -- bw lock
grep -E '^(ssh keys|wireguard):' "$log" | sed 's/^/  /' || true
echo "ok"

grep -E '^Failed:' "$log" | sed 's/^/  ✗ /' || true
printf '\nDone. Open a new shell. Log: %s\n' "$log"
