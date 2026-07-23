{
  description = "Cross-platform Nix configuration";

  # Build performance optimizations
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    max-jobs = "auto";
    cores = 0; # Use all available cores
    builders-use-substitutes = true;
    fallback = true;
    keep-going = true;
    log-lines = 25;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Separately-pinned channel for hand-picked fresh tools (see
    # common/overlays/fresh-tools.nix). Advance independently of the
    # stable base with `nix flake update nixpkgs-unstable`.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code skill sources. flake=false: consumed as plain source
    # trees by common/claude-code. Locked in flake.lock (rev + hash) and
    # bumped via `nix flake update` / Renovate lock maintenance, so they
    # can't drift silently the way inline fetchFromGitHub pins do.
    cc-skills-generator = {
      url = "github:martinholovsky/claude-skills-generator";
      flake = false;
    };
    cc-terraform-skill = {
      url = "github:antonbabenko/terraform-skill";
      flake = false;
    };
    cc-herdr = {
      url = "github:ogulcancelik/herdr";
      flake = false;
    };
    cc-agno-skills = {
      url = "github:agno-agi/agno-skills";
      flake = false;
    };
    cc-hashicorp-skills = {
      url = "github:hashicorp/agent-skills";
      flake = false;
    };
    cc-devops-skills = {
      url = "github:akin-ozer/cc-devops-skills";
      flake = false;
    };
    cc-elements-of-style = {
      url = "github:obra/the-elements-of-style";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      # Centralized version management
      versions = import ./common/versions.nix;

      # Default username across all configurations
      defaultUsername = "svenlito";

      # Username validation - ensures valid UNIX username format
      validateUsername =
        username:
        assert username != null && username != "" || throw "Username cannot be null or empty";
        assert
          builtins.match "^[a-z_][a-z0-9_-]*[$]?$" username != null
          || throw "Username '${username}' is not a valid UNIX username (must start with lowercase letter or underscore, contain only lowercase letters, digits, underscores, and hyphens)";
        username;

      # Overlay pulling hand-picked tools from the separately-pinned
      # nixpkgs-unstable input. Maintained in common/overlays/fresh-tools.nix.
      freshToolsOverlay = import ./common/overlays/fresh-tools.nix { inherit inputs; };

      # Utility function to create nixpkgs for different systems
      mkNixpkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ freshToolsOverlay ];
        };

      # Abstracted macOS configuration function
      mkDarwinSystem =
        {
          hostname,
          username,
          system ? "aarch64-darwin",
          extraModules ? [ ],
        }:
        let
          validUsername = validateUsername username;
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./common
            ./systems/${system}
            {
              networking.hostName = hostname;
              # nix-darwin builds its own pkgs, so apply the overlay here too.
              nixpkgs.overlays = [ freshToolsOverlay ];
            }

            # Home Manager integration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = false; # Must be false on macOS to create user profiles
                extraSpecialArgs = {
                  inherit inputs;
                  username = validUsername;
                };
                backupFileExtension = "backup";
                users.${validUsername} = import ./systems/${system}/home.nix;
              };
            }
          ]
          ++ extraModules;
          specialArgs = {
            inherit inputs self hostname;
            username = validUsername;
          };
        };

      # Abstracted Home Manager configuration function for Linux
      mkHomeManagerConfig =
        {
          username,
          homeDirectory ? "/home/${username}",
          system ? "aarch64-linux",
          extraModules ? [ ],
        }:
        let
          validUsername = validateUsername username;
          validSystems = [
            "x86_64-linux"
            "aarch64-linux"
          ];
        in
        assert nixpkgs.lib.assertMsg (builtins.elem system validSystems)
          "Invalid system '${system}'. Must be one of: ${nixpkgs.lib.concatStringsSep ", " validSystems}";
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkNixpkgs system;
          modules = [
            ./systems/aarch64-linux
            {
              home = {
                username = validUsername;
                inherit homeDirectory;
                stateVersion = versions.homeManagerStateVersion;
              };
            }
          ]
          ++ extraModules;
          extraSpecialArgs = {
            inherit inputs;
            username = validUsername;
          };
        };
    in
    {
      # macOS configurations
      darwinConfigurations = {
        "rick" = mkDarwinSystem {
          hostname = "rick";
          username = defaultUsername;
          extraModules = [ ./systems/aarch64-darwin/homebrew/personal.nix ];
        };
        "MSGMAC-MV69Q140FD" = mkDarwinSystem {
          hostname = "MSGMAC-MV69Q140FD";
          username = "hummes1";
          extraModules = [
            ./systems/aarch64-darwin/homebrew/work.nix
            ./systems/aarch64-darwin/corporate.nix
          ];
        };
      };

      # Linux Home Manager configurations
      homeConfigurations = {
        # Minimal server/container configs
        minimal-x86 = mkHomeManagerConfig {
          username = defaultUsername;
          system = "x86_64-linux";
        };
        minimal-arm = mkHomeManagerConfig {
          username = defaultUsername;
          system = "aarch64-linux";
        };
      };

      # Development shells
      devShells =
        let
          mkDevShell =
            system:
            let
              pkgs = mkNixpkgs system;
            in
            pkgs.mkShell {
              buildInputs = with pkgs; [
                nixfmt
                statix
                deadnix
                nil
                zsh
                git
                pre-commit
                markdownlint-cli
                nodejs
                just
              ];
              shellHook = ''
                echo "🛠️ Nix config dev (${system})"
                # Only exec zsh if running interactively (not with --command)
                if [ -z "$*" ] && [ -t 0 ] && command -v zsh >/dev/null 2>&1; then
                  exec zsh
                fi
              '';
            };
        in
        nixpkgs.lib.genAttrs
          [
            "aarch64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ]
          (system: {
            default = mkDevShell system;
          });
    };
}
