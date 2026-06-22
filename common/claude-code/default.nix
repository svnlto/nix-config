{ config, pkgs, ... }:
let
  # User-scope MCP servers — merged into the stateful ~/.claude.json on switch.
  # Claude Code reads global MCP definitions only from ~/.claude.json's top-level
  # mcpServers key; settings.json does not support server definitions.
  userMcpJson = pkgs.writeText "claude-user-mcp.json" (builtins.toJSON {
    mcpServers = {
      chrome-devtools = {
        command = "npx";
        args = [
          "-y"
          "--prefer-offline"
          "chrome-devtools-mcp@1.3.0"
          "--browser-url=http://127.0.0.1:9222"
        ];
      };
    };
  });
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
    rev = "e53cea4ed6fdd49d70caacc1eccc07225bed5dd8";
    sha256 = "1h4lxbggw3vwvpk7wjjmr4ff609qzqx9wh41jpcad5kfjafx53pk";
  };
  agno-skills-repo = pkgs.fetchFromGitHub {
    owner = "agno-agi";
    repo = "agno-skills";
    rev = "0ed7d1c92570384030184a6dfa18d275a9b5f694";
    sha256 = "1rzdzn7pj8yab68hvbjq663r5kjj9z1wqpkdbn8zbz03cx4kssfd";
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
    # agno-agi/agno-skills
    cp -r ${agno-skills-repo}/plugins/agno/skills/agno $out/
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

  # Merge user-scope MCP servers into the stateful ~/.claude.json without
  # clobbering oauth tokens, project history, or servers added via the CLI.
  # jq '*' deep-merges, so our definitions win on key collision but everything
  # else is preserved. Idempotent — safe to re-run on every switch.
  home.activation.claudeUserMcpServers =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      claudeConfig="${config.home.homeDirectory}/.claude.json"
      [ -e "$claudeConfig" ] || echo '{}' > "$claudeConfig"
      if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$claudeConfig" ${userMcpJson} \
        > "$claudeConfig.tmp"; then
        run mv $VERBOSE_ARG "$claudeConfig.tmp" "$claudeConfig"
      else
        echo "claudeUserMcpServers: jq merge failed, leaving ~/.claude.json untouched" >&2
        rm -f "$claudeConfig.tmp"
      fi
    '';
}
