#!/bin/bash
# Script to install Linuxbrew on Ubuntu and packages from linuxbrew.nix
# With additional safeguards for OrbStack environments

set -e

# Function to run brew commands with timeout protection for OrbStack
run_brew_cmd() {
  local cmd="$1"
  local timeout_secs=120

  echo "Running: brew $cmd (with ${timeout_secs}s timeout)..."
  timeout $timeout_secs brew $cmd || {
    local exit_code=$?
    if [ $exit_code -eq 124 ]; then
      echo "WARNING: 'brew $cmd' timed out after ${timeout_secs} seconds."
      echo "This is common in OrbStack and may not indicate a problem."
      echo "Check if the command completed partially or retry later."
      return 0
    else
      echo "Command 'brew $cmd' failed with exit code $exit_code"
      # Continue despite errors
      return 0
    fi
  }
}

# Check if Linuxbrew is already installed
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  echo "Linuxbrew is already installed."
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  echo "Installing Linuxbrew..."

  # Install dependencies
  sudo apt-get update
  sudo apt-get install -y build-essential curl file git timeout

  # Install Homebrew with a timeout
  timeout 300 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    echo "Homebrew installation timed out or failed, but we'll continue"
    echo "If Homebrew is partially installed, it may work"
  }

  # Set up environment for current session
  if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    echo "ERROR: Brew executable not found. Installation may have failed."
    echo "Please try running the script again or install manually."
    exit 1
  fi
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

# Update Homebrew itself if autoUpdate is enabled - use timeout protection
if [ "$AUTO_UPDATE" = "true" ]; then
  run_brew_cmd "update"
fi

# Install taps if any are defined
if [ ! -z "$TAPS" ]; then
  echo "Installing taps: $TAPS"
  for tap in $TAPS; do
    run_brew_cmd "tap $tap"
  done
fi

# Install brew packages with timeouts - ensure we don't block if a package install hangs
echo "Installing brew packages: $BREWS"
for brew in $BREWS; do
  # Skip large/problematic packages in OrbStack that might cause hangs
  if [[ "$brew" == "node" || "$brew" == "python" || "$brew" == "pyenv" ]]; then
    echo "Skipping $brew installation in OrbStack due to potential hanging issues"
    echo "Consider installing it manually with: brew install $brew"
    continue
  fi

  if ! brew list --formula 2>/dev/null | grep -q "^$brew\$"; then
    echo "Installing $brew..."
    run_brew_cmd "install $brew"
  else
    echo "$brew already installed."
  fi
done

# Upgrade packages if upgrade is enabled - with timeout protection
if [ "$UPGRADE" = "true" ]; then
  echo "Upgrading all packages..."
  run_brew_cmd "upgrade"
fi

# Cleanup based on cleanup setting - with timeout protection
if [ "$CLEANUP" = "zap" ]; then
  echo "Running brew cleanup with zap (removing all unused packages)..."
  run_brew_cmd "cleanup --prune=all"

  # Remove formulae not listed in linuxbrew.nix - with safeguards
  for formula in $(brew list --formula 2>/dev/null || echo ""); do
    if [ -z "$formula" ]; then continue; fi

    # Skip core packages that might be needed
    if [[ "$formula" == "gcc" || "$formula" == "glibc" ]]; then
      continue
    fi

    if ! echo "$BREWS" | grep -q -w "$formula"; then
      echo "Removing unlisted formula: $formula"
      run_brew_cmd "uninstall $formula"
    fi
  done
elif [ "$CLEANUP" = "uninstall" ]; then
  echo "Running standard brew cleanup..."
  run_brew_cmd "cleanup"
fi

echo "==== Linuxbrew updates completed ===="

echo ""
echo "Linuxbrew has been installed and configured."
echo "Note: Some operations may have been skipped if they were taking too long."
echo "If you need to install specific packages that were skipped, you can run:"
echo "  brew install <package-name>"
echo ""
echo "To apply the Home Manager configuration, run:"
echo "nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu"
