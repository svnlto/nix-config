{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # Install Node.js to enable npm
  home.packages = with pkgs; [ nodejs_22 ];

  # Add npm global bin to PATH for user-installed packages
  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  # Set npm prefix to user directory
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  # Create and manage ~/.claude directory
  home.file.".claude/settings.json".source = ./settings.json;
  home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;

  # Combine local commands with linear commands
  home.file.".claude/commands".source = pkgs.symlinkJoin {
    name = "claude-commands";
    paths = [
      ./commands
      (pkgs.runCommand "linear-commands" { } ''
        mkdir -p $out/linear
        cp -r ${
          pkgs.fetchFromGitHub {
            owner = "svnlto";
            repo = "claude-code-linear-commands";
            rev = "main";
            sha256 = "07zl1yfb1pvkyk0kqhdw7z5dpi8078jdybnm0gzwjb13hxk17s21";
          }
        }/commands/* $out/linear/
      '')
    ];
  };

  # Create necessary directories
  home.file.".claude/.keep".text = "";

  # Install Claude Code on activation
  home.activation.installClaudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH="${pkgs.nodejs_22}/bin:$PATH"
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"

    if ! command -v claude >/dev/null 2>&1; then
      echo "Installing Claude Code..."
      npm install -g @anthropic-ai/claude-code
    else
      echo "Claude Code is already installed at $(which claude)"
    fi
  '';
}
