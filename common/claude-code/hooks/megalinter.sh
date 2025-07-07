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

# Create MegaLinter configuration
MEGALINTER_CONFIG=$(cat <<'EOF'
APPLY_FIXES: none
LOG_LEVEL: WARNING
SHOW_ELAPSED_TIME: true
FILEIO_REPORTER: false
SARIF_REPORTER: false
TEXT_REPORTER: false
UPDATED_SOURCES_REPORTER: false
ENABLE:
  - BASH
  - JSON
  - MARKDOWN
  - YAML
  - TYPESCRIPT
  - TERRAFORM
  - DOCKERFILE
DISABLE:
  - COPYPASTE
  - REPOSITORY
  - ARM
  - PYTHON
  - RUST
FILTER_REGEX_EXCLUDE: "(\.git/|\.nix-store/|result/|\.direnv/)"
EOF
)

# Write config to temporary file
CONFIG_FILE="/tmp/megalinter-$$.yml"
echo "$MEGALINTER_CONFIG" > "$CONFIG_FILE"

# Run MegaLinter on modified files
echo "Running MegaLinter on: $FILES"
if docker run --rm \
    -e MEGALINTER_CONFIG_FILE="/tmp/lint/.megalinter.yml" \
    -e FILTER_REGEX_INCLUDE="$(basename "$FILES")" \
    -v "$PWD:/tmp/lint" \
    -v "$CONFIG_FILE:/tmp/lint/.megalinter.yml" \
    --platform linux/arm64 \
    oxsecurity/megalinter:latest 2>&1; then
    echo "MegaLinter completed successfully" >&2
else
    exit_code=$?
    echo "MegaLinter failed with exit code: $exit_code" >&2
    # Don't fail the hook for linting issues, just warn
    echo "Note: Linting issues found, but continuing..." >&2
fi

# Cleanup
rm -f "$CONFIG_FILE"

echo "Hook completed: $(date)" >&2
exit 0