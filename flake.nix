{
  description = "Cross-platform Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Linux-specific inputs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
    let
      # Overlays
      overlays = [
        (import ./overlays/tfenv.nix)
      ];

      # Create a version of nixpkgs with our overlays for Linux
      nixpkgsWithOverlays = system: import nixpkgs { inherit system overlays; };

      # Default macOS configuration
      darwinSystem = { hostname ? "macbook", # Generic default hostname
        username ? "user", # Generic default username
        system ? "aarch64-darwin", # Default to Apple Silicon
        extraModules ? [ ] # Allow additional modules
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./common
            ./systems/${system}
            # Pass hostname to configuration
            {
              networking.hostName = hostname;
            }

            # Add Home Manager to Darwin
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit username; };
                backupFileExtension = "backup";

                # Inline Home Manager configuration
                users.${username} = { config, lib, pkgs, ... }:
                  let sharedZsh = import ./common/zsh/shared.nix;
                  in {
                    # Claude Code configuration (inlined)
                    home.packages = with pkgs; [
                      nodejs_22
                      yq
                      ripgrep
                    ];

                    home.sessionPath = [ 
                      "$HOME/.npm-global/bin" 
                    ];
                    
                    home.sessionVariables = {
                      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
                    };

                    home.file.".claude/settings.json".text = ''{
  "model": "sonnet"
}'';
                    home.file.".claude/CLAUDE.md".text = ''# Development Partnership

We're building production-quality code together. Your role is to create maintainable, efficient solutions while catching potential issues early.

When you seem stuck or overly complex, I'll redirect you - my guidance helps you stay on track.

## 🚨 AUTOMATED CHECKS ARE MANDATORY

**ALL hook issues are BLOCKING - EVERYTHING must be ✅ GREEN!**  
No errors. No formatting issues. No linting problems. Zero tolerance.  
These are not suggestions. Fix ALL issues before continuing.

## CRITICAL WORKFLOW - ALWAYS FOLLOW THIS!

### Research → Plan → Implement

**NEVER JUMP STRAIGHT TO CODING!** Always follow this sequence:

1. **Research**: Explore the codebase, understand existing patterns
2. **Plan**: Create a detailed implementation plan and verify it with me
3. **Implement**: Execute the plan with validation checkpoints

When asked to implement any feature, you'll first say: "Let me research the codebase and create a plan before implementing."

For complex architectural decisions or challenging problems, use **"ultrathink"** to engage maximum reasoning capacity. Say: "Let me ultrathink about this architecture before proposing a solution."

### USE MULTIPLE AGENTS!

_Leverage subagents aggressively_ for better results:

- Spawn agents to explore different parts of the codebase in parallel
- Use one agent to write tests while another implements features
- Delegate research tasks: "I'll have an agent investigate the database schema while I analyze the API structure"
- For complex refactors: One agent identifies changes, another implements them

Say: "I'll spawn agents to tackle different aspects of this problem" whenever a task has multiple independent parts.

### Reality Checkpoints

**Stop and validate** at these moments:

- After implementing a complete feature
- Before starting a new major component
- When something feels wrong
- Before declaring "done"

> Why: You can lose track of what's actually working. These checkpoints prevent cascading failures.

Your code must be 100% clean. No exceptions.

## Working Memory Management

### When context gets long:

- Re-read this CLAUDE.md file
- Document current state before major changes

## Implementation Standards

### Our code is complete when:

- ✓ All linters pass with zero issues
- ✓ All tests pass
- ✓ Feature works end-to-end
- ✓ Old code is deleted

### Testing Strategy

- Complex business logic → Write tests first
- Simple CRUD → Write tests after

## Problem-Solving Together

When you're stuck or confused:

1. **Stop** - Don't spiral into complex solutions
2. **Delegate** - Consider spawning agents for parallel investigation
3. **Ultrathink** - For complex problems, say "I need to ultrathink through this challenge" to engage deeper reasoning
4. **Step back** - Re-read the requirements
5. **Simplify** - The simple solution is usually correct
6. **Ask** - "I see two approaches: [A] vs [B]. Which do you prefer?"

My insights on better approaches are valued - please ask for them!

### **Security Always**:

- Validate all inputs
- Use crypto/rand for randomness

## Communication Protocol

### Progress Updates:

```
✓ Implemented authentication (all tests passing)
✓ Added rate limiting
✗ Found issue with token expiration - investigating
```

### Suggesting Improvements:

"The current approach works, but I notice [observation].
Would you like me to [specific improvement]?"

## Working Together

- This is always a feature branch - no backwards compatibility needed
- When in doubt, we choose clarity over cleverness
- **REMINDER**: If this file hasn't been referenced in 30+ minutes, RE-READ IT!

Avoid complex abstractions or "clever" code. The simple, obvious solution is probably better, and my guidance helps you stay focused on what matters.
'';
                    home.file.".claude/.keep".text = "";

                    home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
                      PATH="${pkgs.nodejs_22}/bin:$PATH"
                      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
                      
                      if ! command -v claude >/dev/null 2>&1; then
                        echo "Installing Claude Code..."
                        npm install -g @anthropic-ai/claude-code
                      else
                        echo "Claude Code is already installed at $(which claude)"
                      fi
                    '';
                    home = {
                      username = username;
                      homeDirectory = "/Users/${username}";
                      stateVersion = "23.11";
                    };

                    programs.zsh = {
                      enable = true;

                      oh-my-zsh = {
                        enable = true;
                        plugins = [ "git" ];
                        theme = "";
                      };

                      shellAliases = sharedZsh.aliases // {
                        nixswitch =
                          "darwin-rebuild switch --flake ~/.config/nix#${hostname}";
                      };

                      initContent = ''
                        # Source common settings
                        ${sharedZsh.options}
                        ${sharedZsh.keybindings}
                        ${sharedZsh.tools}

                        # Add npm global bin to PATH
                        export PATH="$HOME/.npm-global/bin:$PATH"
                        export NPM_CONFIG_PREFIX="$HOME/.npm-global"

                        # Ensure Oh My Posh is properly initialized
                        if command -v oh-my-posh &> /dev/null; then
                          eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/default.omp.json)"
                        fi
                      '';
                    };

                    home.file.".config/oh-my-posh/default.omp.json".source =
                      ./common/zsh/default.omp.json;
                  };
              };
            }
          ] ++ extraModules;

          specialArgs = { inherit inputs self hostname username; };
        };
    in {
      # macOS configurations
      darwinConfigurations = {
        "macbook" = darwinSystem {
          hostname = "macbook";
          username = "your_username"; # Replace with your macOS username
        };

        "Rick" = darwinSystem {
          hostname = "Rick";
          username = "svenlito";
        };
      };

      # Standalone home-manager configuration for Vagrant VM
      homeConfigurations.vagrant = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgsWithOverlays "aarch64-linux";
        modules = [
          ./systems/aarch64-linux/vagrant.nix
          {
            home = {
              username = "vagrant";
              homeDirectory = "/home/vagrant";
              stateVersion = "23.11";
            };

            nixpkgs.config.allowUnfree = true;

            # Explicitly specify nix.package for home-manager
            nix = {
              package = nixpkgs.legacyPackages.aarch64-linux.nix;
              settings.experimental-features = [ "nix-command" "flakes" ];
            };

            programs.fish.enable = false;

            nixpkgs.overlays = [
              (final: prev: {
                # Override fish package properly inside the module
                fish = prev.fish.overrideAttrs (oldAttrs: {
                  doCheck = false;
                  doInstallCheck = false;
                });
              })
            ];
          }
        ];
        extraSpecialArgs = { username = "vagrant"; };
      };

      # Standalone home-manager configuration for EC2
      homeConfigurations.ec2 = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgsWithOverlays "aarch64-linux";
        modules = [
          ./systems/aarch64-linux/ec2.nix
          {
            home = {
              username = "ubuntu";
              homeDirectory = "/home/ubuntu";
              stateVersion = "23.11";
            };

            nixpkgs.config.allowUnfree = true;

            # Explicitly specify nix.package for home-manager
            nix = {
              package = nixpkgs.legacyPackages.aarch64-linux.nix;
              settings.experimental-features = [ "nix-command" "flakes" ];
            };
          }
        ];
        extraSpecialArgs = { username = "ubuntu"; };
      };
    };
}
