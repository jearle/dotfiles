# OS detection
case "$(uname -s)" in
  Darwin)
    OS_TYPE="macos"
    ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      OS_TYPE="wsl"
    else
      OS_TYPE="linux"
    fi
    ;;
  CYGWIN*|MINGW*|MSYS*)
    OS_TYPE="windows"
    ;;
  *)
    OS_TYPE="unknown"
    ;;
esac

# Ensure AI agent binaries, bun, and standard directories are in PATH
export PATH="$HOME/.local/bin:$HOME/.grok/bin:$HOME/.codex/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$PATH"

# Bootstrap & activate mise (cross-platform runtime and CLI tool manager)
if ! command -v mise >/dev/null 2>&1; then
  if [ -x "$HOME/.local/bin/mise" ]; then
    export PATH="$HOME/.local/bin:$PATH"
  else
    echo "mise not installed, installing..."
    curl -fsSL https://mise.run | sh
  fi
fi

if command -v mise >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(mise activate zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(mise activate bash)"
  fi
fi

# Grok completion support
if [ -d "$HOME/.grok/completions/zsh" ]; then
  fpath=("$HOME/.grok/completions/zsh" $fpath)
fi

# Bun-powered packages sync function
profile_sync() {
  local profile_dir="${PROFILE:-$HOME/.config/profile}"
  if command -v bun >/dev/null 2>&1; then
    bun "$profile_dir/packages.ts" "$@"
  elif command -v mise >/dev/null 2>&1; then
    mise exec -- bun "$profile_dir/packages.ts" "$@"
  else
    echo "Neither bun nor mise found to run packages sync." >&2
    return 1
  fi
}
pkg-sync() { profile_sync "$@"; }
packages-sync() { profile_sync "$@"; }
profile-sync() { profile_sync "$@"; }
alias profile-sync="profile_sync"
alias pkg-sync="profile_sync"
alias packages-sync="profile_sync"

# Unified sync alias
profile_packages_sync() {
  profile_sync "$@"
}

# Run startup sync (mise tools + OS packages)
profile_sync

# Backward compatibility aliases
profile_brew_sync() { profile_sync "$@"; }
profile_brew_install() { profile_sync "$@"; }
