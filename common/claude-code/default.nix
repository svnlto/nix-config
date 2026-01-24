{ config, pkgs, ... }: {
  # Create writable settings.json using out-of-store symlink
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.config/nix/common/claude-code/settings.json";
  home.file.".claude/output-styles".source = ./output-styles;

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
}
