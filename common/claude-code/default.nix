{ inputs, lib, config, pkgs, ... }: 
{
  # Install Node.js to enable npm
  home.packages = with pkgs; [
    nodejs_22
    # Dependencies for hooks
    yq
    ripgrep
  ];

  # Add npm global bin to PATH for user-installed packages
  home.sessionPath = [ 
    "$HOME/.npm-global/bin" 
  ];
  
  # Set npm prefix to user directory
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  # Create and manage ~/.claude directory
  home.file.".claude/settings.json".source = ./settings.json;
  home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;
  home.file.".claude/commands".source = ./commands;

  # Create necessary directories
  home.file.".claude/.keep".text = "";

  # Install Claude Code and sync linear commands on activation
  home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PATH="${pkgs.nodejs_22}/bin:$PATH"
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    
    if ! command -v claude >/dev/null 2>&1; then
      echo "Installing Claude Code..."
      npm install -g @anthropic-ai/claude-code
    else
      echo "Claude Code is already installed at $(which claude)"
    fi
    
    # Clone and sync linear commands
    echo "Syncing Claude Code Linear commands..."
    TEMP_DIR=$(mktemp -d)
    if ${pkgs.git}/bin/git clone https://github.com/svnlto/claude-code-linear-commands.git "$TEMP_DIR" >/dev/null 2>&1; then
      mkdir -p "$HOME/.claude/commands/linear"
      cp "$TEMP_DIR/commands/"* "$HOME/.claude/commands/linear/" 2>/dev/null || true
      rm -rf "$TEMP_DIR"
      echo "Linear commands synced to ~/.claude/commands/linear/"
    else
      echo "Warning: Failed to sync linear commands"
      rm -rf "$TEMP_DIR"
    fi
  '';

}