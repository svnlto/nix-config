{ config, pkgs, ... }: {
  home.file = {
    # Create writable settings.json using out-of-store symlink
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/settings.json";

    ".claude/output-styles".source = ./output-styles;

    ".claude/hooks.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/hooks.json";

    # Combine local commands with linear commands
    ".claude/commands".source = pkgs.symlinkJoin {
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
    ".claude/.keep".text = "";
  };
}
