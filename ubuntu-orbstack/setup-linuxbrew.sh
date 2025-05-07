#!/bin/bash
# Script to install Linuxbrew on Ubuntu

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

# Install some basic Linuxbrew packages
brew install gcc

echo ""
echo "Linuxbrew has been installed and configured."
echo "You can now use 'brew' commands to install packages."
echo ""
echo "Note: When using both Nix and Linuxbrew, be aware of potential PATH conflicts."
echo "Your zshrc has been configured to work with both package managers."
echo ""
echo "To apply the configuration, run:"
echo "nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu-orbstack"
