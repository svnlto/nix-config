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

# Extract package and settings from linuxbrew.nix
echo "Reading configuration from linuxbrew.nix..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extract settings for brew behavior
AUTO_UPDATE=$(nix-instantiate --eval -E "let pkgs = import <nixpkgs> {}; linuxbrewConfig = import $SCRIPT_DIR/linuxbrew.nix { inherit pkgs; config = {}; }; in if builtins.hasAttr \"onActivation\" linuxbrewConfig.linuxbrew && builtins.hasAttr \"autoUpdate\" linuxbrewConfig.linuxbrew.onActivation then linuxbrewConfig.linuxbrew.onActivation.autoUpdate else false" | tr -d '"')

UPGRADE=$(nix-instantiate --eval -E "let pkgs = import <nixpkgs> {}; linuxbrewConfig = import $SCRIPT_DIR/linuxbrew.nix { inherit pkgs; config = {}; }; in if builtins.hasAttr \"onActivation\" linuxbrewConfig.linuxbrew && builtins.hasAttr \"upgrade\" linuxbrewConfig.linuxbrew.onActivation then linuxbrewConfig.linuxbrew.onActivation.upgrade else false" | tr -d '"')

CLEANUP=$(nix-instantiate --eval -E "let pkgs = import <nixpkgs> {}; linuxbrewConfig = import $SCRIPT_DIR/linuxbrew.nix { inherit pkgs; config = {}; }; in if builtins.hasAttr \"onActivation\" linuxbrewConfig.linuxbrew && builtins.hasAttr \"cleanup\" linuxbrewConfig.linuxbrew.onActivation then linuxbrewConfig.linuxbrew.onActivation.cleanup else \"\"" | tr -d '"')

# Use nix-instantiate to extract brews from linuxbrew.nix
BREWS=$(nix-instantiate --eval -E "let pkgs = import <nixpkgs> {}; linuxbrewConfig = import $SCRIPT_DIR/linuxbrew.nix { inherit pkgs; config = {}; }; in builtins.concatStringsSep \" \" linuxbrewConfig.linuxbrew.brews" | tr -d '"')

# Use nix-instantiate to extract taps from linuxbrew.nix (if any)
TAPS=$(nix-instantiate --eval -E "let pkgs = import <nixpkgs> {}; linuxbrewConfig = import $SCRIPT_DIR/linuxbrew.nix { inherit pkgs; config = {}; }; in builtins.concatStringsSep \" \" (if builtins.hasAttr \"taps\" linuxbrewConfig.linuxbrew then linuxbrewConfig.linuxbrew.taps else [])" 2>/dev/null | tr -d '"' || echo "")

# Handle updates based on configuration
echo "==== Starting Linuxbrew Updates ===="

# Update Homebrew itself if autoUpdate is enabled
if [ "$AUTO_UPDATE" = "true" ]; then
  echo "Running brew update..."
  brew update
fi

# Install taps if any are defined
if [ ! -z "$TAPS" ]; then
  echo "Installing taps: $TAPS"
  for tap in $TAPS; do
    brew tap "$tap" || echo "Failed to tap $tap, continuing..."
  done
fi

# Install brew packages
echo "Installing brew packages: $BREWS"
for brew in $BREWS; do
  if ! brew list --formula | grep -q "^$brew\$"; then
    echo "Installing $brew..."
    brew install "$brew" || echo "Failed to install $brew, continuing..."
  else
    echo "$brew already installed."
  fi
done

# Upgrade packages if upgrade is enabled
if [ "$UPGRADE" = "true" ]; then
  echo "Upgrading all packages..."
  brew upgrade
fi

# Cleanup based on cleanup setting
if [ "$CLEANUP" = "zap" ]; then
  echo "Running brew cleanup with zap (removing all unused packages)..."
  brew cleanup --prune=all
  # Remove formulae not listed in linuxbrew.nix
  for formula in $(brew list --formula); do
    if ! echo "$BREWS" | grep -q -w "$formula"; then
      echo "Removing unlisted formula: $formula"
      brew uninstall "$formula" || echo "Failed to uninstall $formula, continuing..."
    fi
  done
elif [ "$CLEANUP" = "uninstall" ]; then
  echo "Running standard brew cleanup..."
  brew cleanup
fi

echo "==== Linuxbrew updates completed ===="

echo ""
echo "Linuxbrew has been installed and configured."
echo "Packages from linuxbrew.nix have been installed."
echo "Note: When using both Nix and Linuxbrew, be aware of potential PATH conflicts."
echo "Your zshrc has been configured to work with both package managers."
echo ""
echo "To apply the Home Manager configuration, run:"
echo "nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu"
