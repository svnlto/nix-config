#!/usr/bin/env bash
# Script user scripts from a private GitHub Gist
# This allows storing sensitive users scripts separately from the code repo

set -e

# Your private Gist ID - Replace this with your actual Gist ID
GIST_ID="943d51348f165d47fd0c8bd00cf694f2"

# Standard user script location
USER_SCRIPT_DIR="$HOME/.bin"

echo "Fetching user scripts from GitHub Gist..."
mkdir -p "$USER_SCRIPT_DIR"
chmod 700 "$USER_SCRIPT_DIR"

# Check if gh is authenticated
if ! gh auth status &>/dev/null; then
  echo "GitHub CLI not authenticated. Running 'gh auth login' first..."
  gh auth login
fi

# get names of all files in the gist and then write them to the user script directory
gh gist view $GIST_ID --raw | grep -oP '(?<=filename: ).*' | while read -r file; do
  # Fetch the gist content directly to our config file
  gh gist view $GIST_ID --raw --filename "$file" >"$USER_SCRIPT_DIR/$file"
  chmod +x "$USER_SCRIPT_DIR/$file"
done

echo "✅ User scripts successfully updated from Gist!"
