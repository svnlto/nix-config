#!/bin/bash
# Super Linter hook for Claude Code
# Automatically runs Super Linter on files modified by Claude Code
# Outputs which files are being linted for visibility

set -euo pipefail

echo "Hook started: $(date)" >&2

# Read input from Claude Code
INPUT=$(cat)
echo "Input received: $INPUT" >&2
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
echo "Tool name: $TOOL_NAME" >&2

# Only run for file modification tools
if [[ ! "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
    echo "Skipping - not a file modification tool" >&2
    exit 0
fi

# Extract file paths based on tool type
if [[ "$TOOL_NAME" == "MultiEdit" ]]; then
    FILES=$(echo "$INPUT" | jq -r '.tool_input.edits[].path' | paste -sd '|' -)
else
    FILES=$(echo "$INPUT" | jq -r '.tool_input.path')
fi

echo "Files to lint: $FILES" >&2

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo "Docker not found - skipping Super Linter" >&2
    exit 0
fi

# Run Super Linter on modified files
echo "Running Super Linter on: $FILES"
docker run --rm \
    -e RUN_LOCAL=true \
    -e USE_FIND_ALGORITHM=true \
    -e FILTER_REGEX_INCLUDE="$FILES" \
    -e CREATE_LOG_FILE=false \
    -e DISABLE_ERRORS=true \
    -e LOG_LEVEL=WARN \
    -v "$PWD:/tmp/lint" \
    ghcr.io/super-linter/super-linter:slim-latest 2>&1 || echo "Super Linter failed" >&2

echo "Hook completed: $(date)" >&2
exit 0