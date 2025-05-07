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

  # Installation notes for containerized Ubuntu environments (like OrbStack):
  # Install Nix with:
  # curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --extra-conf "sandbox = false" --extra-conf='filter-syscalls = false' --init none --no-confirm

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
    let
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
            ./darwin
            # Pass hostname to configuration
            { networking.hostName = hostname; }
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
        "macbook" = darwinSystem { };

        # Your current machine
        "Rick" = darwinSystem {
          hostname = "Rick";
          username = "svenlito";
        };

        # Example for another Mac (commented out as reference)
        # "work-mac" = darwinSystem {
        #   hostname = "work-mac";
        #   username = "workuser"; 
        # };
      };

      # Standalone home-manager configuration for Ubuntu OrbStack
      # Install with:
      # $ nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu-orbstack
      homeConfigurations = {
        "ubuntu-orbstack" = home-manager.lib.homeManagerConfiguration {
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

        # Example for a work Ubuntu machine
        # "work-ubuntu" = home-manager.lib.homeManagerConfiguration {
        #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
        #   modules = [
        #     ./ubuntu-orbstack/home.nix
        #     {
        #       home = {
        #         username = "workuser";
        #         homeDirectory = "/home/workuser";
        #         stateVersion = "23.11";
        #       };
        #       # Customize packages for work environment
        #       home.packages = with pkgs; [
        #         postgresql
        #         redis
        #         docker-compose
        #       ];
        #     }
        #   ];
        #   extraSpecialArgs = { username = "workuser"; };
        # };
      };
    };
}
