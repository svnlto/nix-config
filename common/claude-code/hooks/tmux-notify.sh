#!/usr/bin/env bash
# DCS-wrapped terminal notification for tmux sessions.
# When inside tmux, wraps OSC 9 in DCS passthrough so Ghostty
# (or any terminal) can display the notification.
# Outside tmux, sends a plain OSC 9.
# Requires: tmux 3.3+ with `set -g allow-passthrough on`

set -euo pipefail

read -r input
message=$(echo "$input" | jq -r '.message // "Claude Code"')

if [ -n "${TMUX:-}" ]; then
  # DCS passthrough: \ePtmux;\e<OSC 9;message\a>\e\\
  printf '\033Ptmux;\033\033]9;%s\007\033\\' "$message" >/dev/tty
else
  printf '\033]9;%s\007' "$message" >/dev/tty
fi
