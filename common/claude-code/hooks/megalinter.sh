#!/bin/bash
# MegaLinter hook for Claude Code
# Automatically runs MegaLinter on files modified by Claude Code
# ARM64 compatible alternative to Super Linter

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
    FILES=$(echo "$INPUT" | jq -r '.tool_input.file_path')
else
    FILES=$(echo "$INPUT" | jq -r '.tool_input.file_path')
fi

echo "Files to lint: $FILES" >&2

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo "Docker not found - skipping MegaLinter" >&2
    exit 0
fi

# Check if file exists
if [[ ! -f "$FILES" ]]; then
    echo "File does not exist: $FILES" >&2
    exit 0
fi

# Run MegaLinter on modified files
echo "Running MegaLinter on: $FILES"
docker run --rm \
    -e APPLY_FIXES=none \
    -e LOG_LEVEL=WARNING \
    -e SHOW_ELAPSED_TIME=true \
    -e FILEIO_REPORTER=false \
    -e SARIF_REPORTER=false \
    -e TEXT_REPORTER=false \
    -e UPDATED_SOURCES_REPORTER=false \
    -e ENABLE="BASH,JSON,MARKDOWN,YAML,TYPESCRIPT,TERRAFORM,DOCKERFILE" \
    -e DISABLE="COPYPASTE,REPOSITORY,ARM,PYTHON,RUST" \
    -e FILTER_REGEX_INCLUDE="$(basename "$FILES")" \
    -e FILTER_REGEX_EXCLUDE="(\.git/|\.nix-store/|result/|\.direnv/)" \
    -v "$PWD:/tmp/lint" \
    oxsecurity/megalinter:latest 2>&1 || echo "MegaLinter failed" >&2

echo "Hook completed: $(date)" >&2
exit 0