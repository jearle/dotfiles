BIN_BREW=/opt/homebrew/bin
BIN_BREW_CASK=/opt/homebrew/Cellar

# install brew if it doesn't exit
if [ ! -f "$BIN_BREW/brew" ]; then
  echo "brew not installed, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

export PATH="$PATH"\
":$BIN_BREW"\
""

eval "$(brew shellenv)"

# install brew packages if they don't exist
PACKAGES=(
  "neovim"
  "git"
  "bat"
  "lsd"
  "zoxide"
  "fzf"
  "fd"
  "ripgrep"
  "nvm"
  "go"
  "zig"
  "rbenv"
  "python@3.13"
  "rust"
  "bun"
  "deno"
  "llvm"
  "cmake"
  "tree"
)
for package in "${PACKAGES[@]}"; do
  if brew list --formula | grep -q "^$package$"; then
  else
    prefix=$([[ "$package" == "bun" ]] && echo "oven-sh/bun/" || echo "")
    echo "$prefix$package is not installed. Installing..."
    brew install "$prefix$package"
  fi
done

# install brew casks if they don't exist
PACKAGE_CASKS=(
  "visual-studio-code"
  "ghostty"
  "rectangle"
  "karabiner-elements"
  "caffeine"
  "jiggler"
)
for package_cask in "${PACKAGE_CASKS[@]}"; do
  if brew list --cask | grep -q "^$package_cask$"; then
  else
    echo "$package_cask is not installed. Installing..."
    brew install --cask "$package_cask"
  fi
done

LLVM="$BIN_BREW_CASK/llvm/19.1.7/bin"

export PATH=""\
"$LLVM"\
":$PATH"\
""

