{
  config,
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  # Claude Code reads global MCP definitions only from ~/.claude.json's top-level mcpServers key, not settings.json — so merge them there on switch.
  userMcpJson = pkgs.writeText "claude-user-mcp.json" (
    builtins.toJSON {
      mcpServers = {
        # Atlassian Rovo (Jira/Confluence): replaces the confluence-sync skill.
        # OAuth 2.1 runs interactively via /mcp on first use; tokens are stored by
        # Claude Code and survive the deep-merge, so no secret lives in nix.
        atlassian = {
          type = "http";
          url = "https://mcp.atlassian.com/v2/mcp";
        };
      };
    }
  );
  # Skill sources are flake inputs (flake=false) so rev + hash live in flake.lock.
  terraform-skill-repo = inputs.cc-terraform-skill;
  herdr-repo = inputs.cc-herdr;
  elements-of-style-repo = inputs.cc-elements-of-style;
  selectedSkills = pkgs.runCommand "claude-skills" { } ''
    mkdir -p $out
    cp -r ${terraform-skill-repo}/skills/terraform-skill $out/
    mkdir -p $out/herdr
    cp ${herdr-repo}/SKILL.md $out/herdr/
    cp -r ${elements-of-style-repo}/skills/writing-clearly-and-concisely $out/
    cp -r ${./skills}/* $out/
  '';
in
{
  home.file = {
    # Out-of-store symlinks keep these writable at runtime and editable without a switch.
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/settings.json";

    ".claude/hooks/herdr-agent-state.sh".source = ./hooks/herdr-agent-state.sh;

    ".claude/hooks/block-destructive.sh".source = ./hooks/block-destructive.sh;

    ".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/CLAUDE.md";

    ".claude/statusline-command.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/statusline-command.sh";

    ".claude/skills".source = selectedSkills;

    ".claude/agents".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/agents";

    ".claude/commands".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/commands";

    ".claude/.keep".text = "";
  };

  home.activation = {
    # Deep-merge so our definitions win while oauth tokens, project history, and CLI-added servers survive.
    claudeUserMcpServers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
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

    # Granted via settings.local.json so the committed settings.json stays host-agnostic.
    claudeVaultDir = lib.mkIf (pkgs.stdenv.isDarwin && username == "svenlito") (
      config.lib.dag.entryAfter [ "writeBoundary" ] ''
        settingsLocal="${config.home.homeDirectory}/.claude/settings.local.json"
        vault="${config.home.homeDirectory}/Documents/obsidian-vault"
        [ -e "$settingsLocal" ] || echo '{}' > "$settingsLocal"
        if ${pkgs.jq}/bin/jq --arg d "$vault" \
          '.permissions.additionalDirectories = ((.permissions.additionalDirectories // []) + [$d] | unique)' \
          "$settingsLocal" > "$settingsLocal.tmp"; then
          run mv $VERBOSE_ARG "$settingsLocal.tmp" "$settingsLocal"
        else
          echo "claudeVaultDir: jq merge failed, leaving settings.local.json untouched" >&2
          rm -f "$settingsLocal.tmp"
        fi
      ''
    );
  };
}
