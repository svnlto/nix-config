#!/usr/bin/env bash
# PreToolUse(Write) guard: markdownlint the proposed content before it lands.
# Exit 2 blocks the write and feeds the lint output back for a fix.
set -euo pipefail

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[[ -n "$file" ]] || exit 0
[[ "$file" == *.md ]] || exit 0

# Mirror the pre-commit markdownlint exclude: machine-consumed markdown that
# intentionally leads with prose instead of an H1 (MD041).
rel=${file#"$CLAUDE_PROJECT_DIR"/}
case "$rel" in
  common/claude-code/agents/* | common/claude-code/skills/jira/references/templates/*)
    exit 0
    ;;
esac

# devShell not loaded (markdownlint off PATH) — don't block the write.
command -v markdownlint >/dev/null 2>&1 || exit 0

tmpdir=$(mktemp -d)
tmp="$tmpdir/$(basename "$file")"
# -rj writes the content byte-exact (no stripped/added trailing newline) so the
# lint matches what Write will put on disk (MD047 is newline-sensitive).
printf '%s' "$input" | jq -rj '.tool_input.content // empty' >"$tmp"
[[ -s "$tmp" ]] || { rm -rf "$tmpdir"; exit 0; }

config="$CLAUDE_PROJECT_DIR/.markdownlint.jsonc"
if [[ -f "$config" ]]; then
  out=$(markdownlint --config "$config" "$tmp" 2>&1) && rc=0 || rc=$?
else
  out=$(markdownlint "$tmp" 2>&1) && rc=0 || rc=$?
fi
rm -rf "$tmpdir"

[[ "$rc" -eq 0 ]] && exit 0

echo "markdownlint blocked the write to $file:" >&2
printf '%s\n' "$out" | sed "s|$tmp|$file|g" >&2
exit 2
