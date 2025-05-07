#!/usr/bin/env bash
# setup-local-config.sh - Setup script for creating a local Git configuration file
# This file helps users create their .gitconfig.local file without exposing private info in the repo

# Set text color variables
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${BLUE}Creating local Git configuration for private settings...${RESET}"

# Check if file already exists
if [ -f ~/.gitconfig.local ]; then
  echo -e "${RED}A ~/.gitconfig.local file already exists.${RESET}"
  read -p "Do you want to overwrite it? (y/N) " OVERWRITE
  if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Keeping existing ~/.gitconfig.local file.${RESET}"
    echo "You can edit it manually with: nano ~/.gitconfig.local"
    exit 0
  fi
fi

# Get user input
echo -e "${BLUE}Please provide your Git user information:${RESET}"
read -p "Name: " GIT_NAME
read -p "Email: " GIT_EMAIL

# Create the file
cat >~/.gitconfig.local <<EOF
# Local Git configuration - NOT tracked in Git
# This file contains your personal Git configuration, including email

[user]
    name = $GIT_NAME
    email = $GIT_EMAIL

# You can add other private Git configurations here
# [github]
#     user = yourusername
EOF

echo -e "${GREEN}Successfully created ~/.gitconfig.local with your information.${RESET}"
echo "You can edit it anytime with: nano ~/.gitconfig.local"
echo -e "${BLUE}This file is local and will not be tracked in your Git repository.${RESET}"
