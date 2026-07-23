{
  config,
  pkgs,
  inputs,
  ...
}:
let
  # Claude Code reads global MCP definitions only from ~/.claude.json's top-level mcpServers key, not settings.json — so merge them there on switch.
  userMcpJson = pkgs.writeText "claude-user-mcp.json" (
    builtins.toJSON {
      mcpServers = {
        chrome-devtools = {
          command = "${chrome-devtools-mcp}/bin/chrome-devtools-mcp";
          args = [ "--browser-url=http://127.0.0.1:9222" ];
          # Update checks and telemetry both stall under corporate VPN SSL inspection.
          env = {
            CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS = "1";
            CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = "1";
          };
        };
      };
    }
  );
  # Skill sources come from flake inputs (flake=false) so rev + hash stay
  # in flake.lock and ride along with `nix flake update`. See flake.nix.
  skills-repo = inputs.cc-skills-generator;
  terraform-skill-repo = inputs.cc-terraform-skill;
  herdr-repo = inputs.cc-herdr;
  agno-skills-repo = inputs.cc-agno-skills;
  hashicorp-skills-repo = inputs.cc-hashicorp-skills;
  cc-devops-skills-repo = inputs.cc-devops-skills;
  elements-of-style-repo = inputs.cc-elements-of-style;
  # Tag-pinned + version-coupled to the npm tarball below, so kept as an
  # explicit fetch rather than a flake input.
  chrome-devtools-mcp-repo = pkgs.fetchFromGitHub {
    owner = "ChromeDevTools";
    repo = "chrome-devtools-mcp";
    rev = "chrome-devtools-mcp-v1.6.0";
    sha256 = "0vi24yml8017i400fp5p96dmv6hry532c7qm2miy35nvrync2xk8";
  };
  # Built from the bundled npm tarball to avoid npx registry resolution, which intermittently failed on the pinned version via stale metadata (ETARGET), leaving the server and its tools absent for the whole session.
  chrome-devtools-mcp = pkgs.stdenv.mkDerivation {
    pname = "chrome-devtools-mcp";
    version = "1.6.0";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-1.6.0.tgz";
      hash = "sha256-HmMsLZcUtPgrTPq077nOV1CFx1/+XpdyODEprwEsnIQ=";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/chrome-devtools-mcp
      cp -r . $out/lib/chrome-devtools-mcp/
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/chrome-devtools-mcp \
        --add-flags $out/lib/chrome-devtools-mcp/build/src/bin/chrome-devtools-mcp.js
      runHook postInstall
    '';
  };
  selectedSkills = pkgs.runCommand "claude-skills" { } ''
    mkdir -p $out
    for skill in devsecops-expert rest-api-design security-auditing \
                 cloud-api-integration database-design talos-os-expert; do
      cp -r ${skills-repo}/skills/$skill $out/
    done
    # These two ship with malformed frontmatter (H1/code-fence, no description)
    # so they never auto-invoke — rewrite the header. Guards no-op if upstream
    # fixes it. chmod: cp from the store leaves dirs read-only, sed -i needs +w.
    chmod -R u+w "$out/security-auditing" "$out/rest-api-design"
    sec=$out/security-auditing/SKILL.md
    if [ "$(head -1 "$sec")" = "# Security Auditing Skill" ]; then
      sed -i '/^---$/,$!d' "$sec"
      sed -i '0,/^---$/s//---\ndescription: Security auditing and compliance logging — GDPR, HIPAA, PCI-DSS, SOC2, ISO27001. Use for audit trails, tamper-evident logs, and compliance controls./' "$sec"
    fi
    rest=$out/rest-api-design/SKILL.md
    if [ "$(head -1 "$rest")" = "# REST API Design Skill" ]; then
      sed -i '/^```yaml$/,$!d' "$rest"
      sed -i '0,/^```yaml$/s//---/' "$rest"
      sed -i '0,/^```$/s//---/' "$rest"
    fi
    # antonbabenko/terraform-skill
    cp -r ${terraform-skill-repo}/skills/terraform-skill $out/
    # ogulcancelik/herdr agent skill
    mkdir -p $out/herdr
    cp ${herdr-repo}/SKILL.md $out/herdr/
    # agno-agi/agno-skills
    cp -r ${agno-skills-repo}/plugins/agno/skills/agno $out/
    # ChromeDevTools/chrome-devtools-mcp companion skills
    cp -r ${chrome-devtools-mcp-repo}/skills/* $out/
    # hashicorp/agent-skills
    for skill in azure-verified-modules terraform-search-import \
                 terraform-test terraform-style-guide; do
      cp -r ${hashicorp-skills-repo}/terraform/code-generation/skills/$skill $out/
    done
    for skill in terraform-stacks refactor-module; do
      cp -r ${hashicorp-skills-repo}/terraform/module-generation/skills/$skill $out/
    done
    # akin-ozer/cc-devops-skills
    for skill in ansible azure-pipelines dockerfile bash-script \
                 k8s-yaml helm terragrunt; do
      cp -r ${cc-devops-skills-repo}/devops-skills-plugin/skills/$skill-generator $out/
      cp -r ${cc-devops-skills-repo}/devops-skills-plugin/skills/$skill-validator $out/
    done
    # obra/the-elements-of-style — sentence-level prose mechanics
    cp -r ${elements-of-style-repo}/skills/writing-clearly-and-concisely $out/
    # Local skills (not from upstream repo)
    cp -r ${./skills}/* $out/
  '';
in
{
  home.file = {
    # Create writable settings.json using out-of-store symlink
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/settings.json";

    # SessionStart hook script referenced from settings.json hooks
    ".claude/hooks/herdr-agent-state.sh".source = ./hooks/herdr-agent-state.sh;

    # PreToolUse(Bash) guard blocking irreversible commands
    ".claude/hooks/block-destructive.sh".source = ./hooks/block-destructive.sh;

    # Global CLAUDE.md with user preferences (writable via out-of-store symlink)
    ".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/CLAUDE.md";

    # Status line script (out-of-store symlink for immediate iteration)
    ".claude/statusline-command.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/statusline-command.sh";

    # Skills from pinned upstream repos and local ./skills, auto-invoked by description match
    ".claude/skills".source = selectedSkills;

    # Skill-bound subagents (out-of-store symlink for immediate iteration) — each preloads a skill via its `skills:` frontmatter so dispatched agents inherit the skill's methodology instead of running general-purpose
    ".claude/agents".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/agents";

    # Custom slash commands (out-of-store symlink for immediate iteration)
    ".claude/commands".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/common/claude-code/commands";

    # Create necessary directories
    ".claude/.keep".text = "";
  };

  # jq deep-merge so our definitions win on collision while oauth tokens, project history, and CLI-added servers survive — idempotent, safe to re-run every switch.
  home.activation.claudeUserMcpServers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
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
