final: prev: {
  browser-forward = prev.writeScriptBin "browser-forward" ''
    #!/bin/bash
    # Open URLs from SSH session in the host machine's browser via VS Code
    URL="$1"

    if [ -n "$SSH_TTY" ] && [ -n "$SSH_CLIENT" ] && command -v code >/dev/null 2>&1; then
      # Try to open via VS Code's remote SSH extension
      code --open-url "$URL" >/dev/null 2>&1 && exit 0
    elif [ -n "$DISPLAY" ] && command -v xdg-open >/dev/null 2>&1; then
      # Fall back to xdg-open if we have X11
      xdg-open "$URL" >/dev/null 2>&1 && exit 0
    fi

    echo "Unable to open browser, please visit this URL manually: $URL"
    exit 1
  '';
}
