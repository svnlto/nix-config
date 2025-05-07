#!/bin/bash
# Script to install Linuxbrew on Ubuntu and packages from linuxbrew.nix

set -e

# Check if Linuxbrew is already installed
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  echo "Linuxbrew is already installed."
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  echo "Installing Linuxbrew..."

  # Install dependencies
  sudo apt-get update
  sudo apt-get install -y build-essential curl file git

  # Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Set up environment for current session
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Extract package lists from linuxbrew.nix
echo "Reading package lists from linuxbrew.nix..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use nix-instantiate to extract brews from linuxbrew.nix
BREWS=$(nix-instantiate --eval -E "let pkgs = import <nixpkgs> {}; linuxbrewConfig = import $SCRIPT_DIR/linuxbrew.nix { inherit pkgs; config = {}; }; in builtins.concatStringsSep \" \" linuxbrewConfig.linuxbrew.brews" | tr -d '"')

# Use nix-instantiate to extract taps from linuxbrew.nix (if any)
TAPS=$(nix-instantiate --eval -E "let pkgs = import <nixpkgs> {}; linuxbrewConfig = import $SCRIPT_DIR/linuxbrew.nix { inherit pkgs; config = {}; }; in builtins.concatStringsSep \" \" (if builtins.hasAttr \"taps\" linuxbrewConfig.linuxbrew then linuxbrewConfig.linuxbrew.taps else [])" 2>/dev/null | tr -d '"' || echo "")

# Install taps if any are defined
if [ ! -z "$TAPS" ]; then
  echo "Installing taps: $TAPS"
  for tap in $TAPS; do
    brew tap "$tap"
  done
fi

# Install brew packages
echo "Installing brew packages: $BREWS"
for brew in $BREWS; do
  brew install "$brew" || echo "Failed to install $brew, continuing..."
done

echo ""
echo "Linuxbrew has been installed and configured."
echo "Packages from linuxbrew.nix have been installed."
echo "Note: When using both Nix and Linuxbrew, be aware of potential PATH conflicts."
echo "Your zshrc has been configured to work with both package managers."
echo ""
echo "To apply the Home Manager configuration, run:"
echo "nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu"
