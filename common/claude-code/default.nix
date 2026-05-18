{ config, pkgs, ... }:
let
  skills-repo = pkgs.fetchFromGitHub {
    owner = "martinholovsky";
    repo = "claude-skills-generator";
    rev = "1086ef25672acba2916220c6ce032a612cd9dc98";
    sha256 = "1shvigcnm63a62w0nynqcnly292dz4zchybzjg90nwv0vz38c1a3";
  };
  terraform-skill-repo = pkgs.fetchFromGitHub {
    owner = "antonbabenko";
    repo = "terraform-skill";
    rev = "9c188f5ee15606d85871e0b012f4b00df6cf10fa";
    sha256 = "14nmmxhfr1p2hzkxr11425vhrq712mk3krc6hkaslrqavk3bpy0f";
  };
  herdr-repo = pkgs.fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    rev = "3189ede2b9225b1b930cc43368248c6b4f3a4daf";
    sha256 = "18v2x16l69p7c1vlfrc8k4yx33gr13ki91wxsya9wm2dla1iybss";
  };
  selectedSkills = pkgs.runCommand "claude-skills" { } ''
    mkdir -p $out
    for skill in ci-cd devsecops-expert rest-api-design security-auditing \
                 cloud-api-integration database-design talos-os-expert; do
      cp -r ${skills-repo}/skills/$skill $out/
    done
    # antonbabenko/terraform-skill
    cp -r ${terraform-skill-repo}/skills/terraform-skill $out/
    # ogulcancelik/herdr agent skill
    mkdir -p $out/herdr
    cp ${herdr-repo}/SKILL.md $out/herdr/
    # Local skills (not from upstream repo)
    cp -r ${./skills}/* $out/
  '';
in {
  home.file = {
    # Create writable settings.json using out-of-store symlink
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/settings.json";

    ".claude/hooks.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/hooks.json";

    ".claude/commands".source = ./commands;

    ".claude/hooks".source = ./hooks;

    # Global CLAUDE.md with user preferences (writable via out-of-store symlink)
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/CLAUDE.md";

    # Status line script (out-of-store symlink for immediate iteration)
    ".claude/statusline-command.sh".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix/common/claude-code/statusline-command.sh";

    # External skills from claude-skills-generator (auto-invoked by description match)
    ".claude/skills".source = selectedSkills;

    # Create necessary directories
    ".claude/.keep".text = "";
  };
}
