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
      mkHomeManagerConfig = { username, homeDirectory ? "/home/${username}"
        , system ? "aarch64-linux", extraModules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkNixpkgs system;
          modules = [
            ./systems/aarch64-linux/home-linux.nix
            {
              home = {
                inherit username homeDirectory;
                stateVersion = "24.05";
              };
            }
          ] ++ extraModules;
          extraSpecialArgs = { inherit username; };
        };
    in {
      # macOS configurations
      darwinConfigurations = {
        "rick" = mkDarwinSystem {
          hostname = "rick";
          username = defaultUsername;
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

        # Desktop configs with Hyprland
        desktop-x86 = mkHomeManagerConfig {
          username = defaultUsername;
          system = "x86_64-linux";
          extraModules = [ ./common/profiles/hyprland.nix ];
        };
        desktop-arm = mkHomeManagerConfig {
          username = defaultUsername;
          system = "aarch64-linux";
          extraModules = [ ./common/profiles/hyprland.nix ];
        };
      };

      # Development shells
      devShells = let
        mkDevShell = system:
          let pkgs = mkNixpkgs system;
          in pkgs.mkShell {
            buildInputs = with pkgs; [
              nixfmt-classic
              statix
              deadnix
              nil
              zsh
              git
            ];
            shellHook = ''
              echo "🛠️  Nix config dev (${system})"
              if command -v zsh >/dev/null 2>&1; then exec zsh; fi
            '';
          };
      in nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ] (system: { default = mkDevShell system; });
    };
}
