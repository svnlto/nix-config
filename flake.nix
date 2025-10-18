{
  description = "Cross-platform Nix configuration";

  # Build performance optimizations
  nixConfig = {
    extra-substituters =
      [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
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
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager, }:
    let
      # Default username across all configurations
      defaultUsername = "svenlito";

      # Utility function to create nixpkgs for different systems
      mkNixpkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # Enhanced validation helper with helpful error messages
      validateUsername = name: config:
        let
          username = config.username;
          isPlaceholder = username == "user" || username == "your_username";
          errorMsg = ''
            ❌ Configuration Error in ${name}:
              • Invalid username: '${username}'
              💡 Solution: Edit flake.nix and change username to your actual username

            Example:
              "${name}" = mkDarwinSystem {
                hostname = "${name}";
                username = "your-actual-username";  # ← Change this
              };
          '';
        in if isPlaceholder then throw errorMsg else config;

      # Abstracted macOS configuration function
      mkDarwinSystem =
        { hostname, username, system ? "aarch64-darwin", extraModules ? [ ] }:
        let config = { inherit hostname username system extraModules; };
        in nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./common
            ./systems/${system}
            {
              networking.hostName = hostname;
            }

            # Home Manager integration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages =
                  false; # Must be false on macOS to create user profiles
                extraSpecialArgs = { inherit username; };
                backupFileExtension = "backup";
                users.${username} = import ./systems/${system}/home.nix;
              };
            }
          ] ++ extraModules;
          specialArgs = { inherit inputs self hostname username; };
        };

      # Abstracted Home Manager configuration function for Linux
      mkHomeManagerConfig =
        { username, homeDirectory ? "/home/${username}", extraModules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkNixpkgs "aarch64-linux";
          modules = [
            ./systems/aarch64-linux/home-linux.nix
            {
              home = {
                inherit username homeDirectory;
                stateVersion = "24.05"; # Manage this manually for now
              };
            }
          ] ++ extraModules;
          extraSpecialArgs = { inherit username; };
        };
    in {
      # macOS configurations
      darwinConfigurations = {
        "rick" = mkDarwinSystem (validateUsername "rick" {
          hostname = "rick";
          username = defaultUsername;
        });
      };

      # Linux Home Manager configurations
      homeConfigurations = {
        # Generic Linux configuration - can be used for VMs, containers, cloud instances
        linux = mkHomeManagerConfig {
          username =
            "user"; # Override this when using: home-manager switch --flake .#linux --extra-experimental-features "nix-command flakes"
        };

        ubuntu = mkHomeManagerConfig { username = "ubuntu"; };

        # Desktop configuration with Hyprland compositor and full dev environment
        desktop = mkHomeManagerConfig {
          username = defaultUsername;
          extraModules = [ ./common/profiles/hyprland.nix ];
        };
      };

      # Development shell for working on this configuration
      devShells.aarch64-darwin.default = let pkgs = mkNixpkgs "aarch64-darwin";
      in pkgs.mkShell {
        buildInputs = with pkgs; [ nixfmt-classic statix deadnix nil zsh git ];
        shellHook = ''
          echo "🛠️  Nix configuration development environment"
          echo "Available tools: nixfmt-classic, statix, deadnix, nil, git, zsh"
          echo ""
          echo "Quick commands:"
          echo "  nixswitch                              # Rebuild Darwin system"
          echo "  home-manager switch --flake .#linux   # Rebuild Linux home"
          echo ""
          # Auto-start zsh if available
          if command -v zsh >/dev/null 2>&1; then
            echo "Starting ZSH shell..."
            exec zsh
          fi
        '';
      };

      devShells.aarch64-linux.default = let pkgs = mkNixpkgs "aarch64-linux";
      in pkgs.mkShell {
        buildInputs = with pkgs; [ nixfmt-classic statix deadnix nil zsh git ];
        shellHook = ''
          echo "🛠️  Nix configuration development environment (Linux)"
          echo "Available tools: nixfmt-classic, statix, deadnix, nil, git, zsh"
          echo ""
          echo "Quick commands:"
          echo "  hmswitch                               # Rebuild Home Manager"
          echo "  home-manager switch --flake .#linux   # Manual rebuild"
          echo ""
          # Auto-start zsh if available
          if command -v zsh >/dev/null 2>&1; then
            echo "Starting ZSH shell..."
            exec zsh
          fi
        '';
      };
    };
}
