#!/usr/bin/env bash
# PreToolUse(Bash) guard — blocks a small set of irreversible commands.
# Exit 2 tells Claude Code to deny the tool call and feeds stderr back so the
# model can self-correct. Layered defence on top of settings.json permissions
# (which only prefix-match the start of a command).

set -eu

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
[ -n "$cmd" ] || exit 0

block() {
  printf 'BLOCKED by block-destructive guard: %s\n' "$1" >&2
  exit 2
}

# Recursive force-delete of root or home
printf '%s' "$cmd" | grep -Eq 'rm +-[a-z]*r[a-z]* +(-{2}no-preserve-root +)?(/|~|\$HOME)( |$)' \
  && block "recursive force delete of / or \$HOME"

# sudo rm — almost never what an agent should do unattended
printf '%s' "$cmd" | grep -Eq '\bsudo +rm\b' && block "sudo rm"

# Force push without lease
if printf '%s' "$cmd" | grep -Eq '\bgit +push\b.*(--force\b|-f\b)'; then
  printf '%s' "$cmd" | grep -q 'force-with-lease' || block "git push --force (use --force-with-lease)"
fi

# Disk / filesystem destroyers
printf '%s' "$cmd" | grep -Eq '\b(mkfs|dd)\b.*of=/dev/' && block "raw write to a block device"
printf '%s' "$cmd" | grep -Eq '\bmkfs(\.[a-z0-9]+)? +/dev/' && block "mkfs on a device"

exit 0
