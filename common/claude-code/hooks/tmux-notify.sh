#!/usr/bin/env bash
# Native macOS notification for Claude Code hooks.
# Uses terminal-notifier for persistent alerts with sound.
# Falls back to osascript if terminal-notifier is unavailable.

set -euo pipefail

read -r input
message=$(echo "$input" | jq -r '.message // "Claude Code"')

if command -v terminal-notifier &>/dev/null; then
  terminal-notifier -title "Claude Code" -message "$message" -sound default
else
  osascript -e "display notification \"$message\" with title \"Claude Code\""
fi
