#!/bin/bash
# Bootstrap a fresh Tart VM from this repo and check the result.
# Usage: scripts/test-vm.sh [macos|linux] [git-ref]
# One VM at a time; the VM is deleted on exit.
set -euo pipefail

os="${1:-macos}"
ref="${2:-main}"
name="dotfiles-test-${os}"
case "$os" in
  macos) image="ghcr.io/cirruslabs/macos-sequoia-vanilla:latest" ;;
  linux) image="ghcr.io/cirruslabs/ubuntu:latest" ;;
  *) echo "unknown os: $os (macos|linux)" >&2; exit 2 ;;
esac

if tart list --format json | grep -q '"Running" *: *true'; then
  echo "a Tart VM is already running; 1 VM at a time" >&2
  exit 1
fi

askpass="$(mktemp)"
printf '#!/bin/sh\necho admin\n' > "$askpass"
chmod +x "$askpass"

cleanup() {
  tart stop "$name" >/dev/null 2>&1 || true
  tart delete "$name" >/dev/null 2>&1 || true
  rm -f "$askpass"
}
trap cleanup EXIT

tart clone "$image" "$name"
tart run "$name" >/dev/null 2>&1 &
ip="$(tart ip --wait 300 "$name")"
echo "VM $name at $ip"

vm() {
  SSH_ASKPASS="$askpass" SSH_ASKPASS_REQUIRE=force \
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR "admin@$ip" "$@"
}

until vm true 2>/dev/null; do sleep 5; done

# Bootstrap: the README one-liner, pinned to a ref.
vm "sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \$HOME/.local/bin init --apply --use-builtin-git true --branch '$ref' jearle"

# Checks.
status=0
check() {
  local label="$1"; shift
  if vm "zsh -lic '$*'" >/dev/null 2>&1; then echo "✓ $label"; else echo "✗ $label"; status=1; fi
}
check "zsh starts clean" 'true'
check "mise doctor" 'mise doctor'
check "nvim opens" 'nvim --headless +qa'
check "ssh config resolves" 'ssh -G github.com'
check "podman installed" 'podman --version'
exit "$status"
