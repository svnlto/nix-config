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

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      home-manager,
    }:
    let
      # Overlays (removed - use flakes for project-specific tools)
      overlays = [ ];

      # Create a version of nixpkgs with our overlays for Linux
      nixpkgsWithOverlays = system: import nixpkgs { inherit system overlays; };

      # Default macOS configuration
      darwinSystem =
        {
          hostname ? "macbook", # Generic default hostname
          username ? "user", # Generic default username
          system ? "aarch64-darwin", # Default to Apple Silicon
          extraModules ? [ ], # Allow additional modules
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

                # Import Home Manager configuration from separate file
                users.${username} = import ./systems/${system}/home.nix;
              };
            }
          ] ++ extraModules;

          specialArgs = {
            inherit
              inputs
              self
              hostname
              username
              ;
          };
        };
    in
    {
      # macOS configurations
      darwinConfigurations = {
        "macbook" = darwinSystem {
          hostname = "macbook";
          username = "your_username"; # Replace with your macOS username
        };

        "rick" = darwinSystem {
          hostname = "rick";
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
              settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
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
        extraSpecialArgs = {
          username = "vagrant";
        };
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
              settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
            };
          }
        ];
        extraSpecialArgs = {
          username = "ubuntu";
        };
      };
    };
}
