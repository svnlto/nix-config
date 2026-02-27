{ config, ... }: {
  home.file = {
    # Create writable settings.json using out-of-store symlink
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/settings.json";

    ".claude/output-styles".source = ./output-styles;

    ".claude/hooks.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/hooks.json";

    ".claude/commands".source = ./commands;

    # Global CLAUDE.md with user preferences (writable via out-of-store symlink)
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/CLAUDE.md";

    # Status line script (read-only, no need for out-of-store symlink)
    ".claude/statusline-command.sh".source = ./statusline-command.sh;

    # Create necessary directories
    ".claude/.keep".text = "";
  };
}
