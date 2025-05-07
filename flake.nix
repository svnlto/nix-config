{
  description = "Cross-platform Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Linux-specific inputs
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Installation notes for Ubuntu OrbStack:
  # Install Nix with:
  # curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --extra-conf "sandbox = false" --extra-conf='filter-syscalls = false' --init none --no-confirm

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
    let
      # Default macOS configuration
      darwinSystem = { hostname ? "macbook", # Generic default hostname
        username ? "user", # Generic default username
        system ? "aarch64-darwin", # Default to Apple Silicon
        dockApps ? [ # Default dock applications
          "/Applications/Arc.app"
          "/Applications/Spotify.app"
        ], extraModules ? [ ] # Allow additional modules
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./common
            ./darwin
            # Pass hostname and dock apps to configuration
            {
              networking.hostName = hostname;

              # Pass the dock applications to the module
              _module.args.dockApps = dockApps;
            }
          ] ++ extraModules;
          specialArgs = {
            inherit inputs self hostname;
            username = username;
          };
        };
    in {
      # Generic macOS configuration - can be customized with hostname and user
      darwinConfigurations = {
        # Default configuration
        "macbook" = darwinSystem {};
        
        # Your current machine
        "Sauron" = darwinSystem {
          hostname = "Sauron";
          username = "svenlito";
          dockApps = [
            "/Applications/Arc.app"
            "/Applications/Spotify.app"
            "/Applications/Visual Studio Code.app"
            "/Applications/iTerm.app"
          ];
        };
        
        # Example for another Mac (commented out as reference)
        # "work-mac" = darwinSystem {
        #   hostname = "work-mac";
        #   username = "workuser"; 
        # };
      };

      # Build Ubuntu OrbStack configuration using:
      # $ nixos-rebuild switch --flake ~/.config/nix#ubuntu-orbstack
      nixosConfigurations."ubuntu-orbstack" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [ ./common ./ubuntu-orbstack home-manager.nixosModules.home-manager ];
        specialArgs = {
          inherit inputs self;
          username = "sven";
        };
      };

      # Standalone home-manager configuration for Ubuntu OrbStack
      # Install with:
      # $ nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu-orbstack
      homeConfigurations."ubuntu-orbstack" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./ubuntu-orbstack/home.nix
            {
              home = {
                username = "sven";
                homeDirectory = "/home/sven";
                stateVersion = "23.11";
              };
            }
          ];
          extraSpecialArgs = { username = "sven"; };
        };
    };
}
