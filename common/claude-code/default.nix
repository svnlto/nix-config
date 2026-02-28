{ config, pkgs, ... }:
let
  skills-repo = pkgs.fetchFromGitHub {
    owner = "martinholovsky";
    repo = "claude-skills-generator";
    rev = "1086ef25672acba2916220c6ce032a612cd9dc98";
    sha256 = "1shvigcnm63a62w0nynqcnly292dz4zchybzjg90nwv0vz38c1a3";
  };
  selectedSkills = pkgs.runCommand "claude-skills" { } ''
    mkdir -p $out
    for skill in ci-cd devsecops-expert rest-api-design security-auditing \
                 argo-expert cilium-expert cloud-api-integration \
                 database-design talos-os-expert; do
      cp -r ${skills-repo}/skills/$skill $out/
    done
  '';
in {
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

    # External skills from claude-skills-generator (auto-invoked by description match)
    ".claude/skills".source = selectedSkills;

    # Create necessary directories
    ".claude/.keep".text = "";
  };
}
