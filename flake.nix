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
            {
              networking.hostName = hostname;
            }

            # Add Home Manager to Darwin
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit username; };
              # Add backup file extension to avoid conflicts
              home-manager.backupFileExtension = "backup";

              # Inline Home Manager configuration
              home-manager.users.${username} = { config, lib, pkgs, ... }:
                let
                  # Import shared ZSH configuration
                  sharedZsh = import ./common/zsh/shared.nix;
                in {
                  # Home Manager configuration for macOS
                  home.username = username;
                  home.homeDirectory = "/Users/${username}";
                  home.stateVersion = "23.11";

                  # Enable Oh My Zsh with Git plugin
                  programs.zsh = {
                    enable = true;

                    # Enable Oh My Zsh with Git plugin
                    oh-my-zsh = {
                      enable = true;
                      plugins = [ "git" ];
                      theme = ""; # Use empty theme since we're using Oh My Posh
                    };

                    # Common aliases from shared config plus macOS-specific ones
                    shellAliases = sharedZsh.aliases // {
                      nixswitch =
                        "darwin-rebuild switch --flake ~/.config/nix#${hostname}";
                    };

                    # Additional ZSH initialization
                    initContent = ''
                      # Source common settings
                      ${sharedZsh.options}
                      ${sharedZsh.keybindings}
                      ${sharedZsh.tools}

                      # Ensure Oh My Posh is properly initialized
                      if command -v oh-my-posh &> /dev/null; then
                        eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/default.omp.json)"
                      fi
                    '';
                  };

                  # Install Oh My Posh theme
                  home.file.".config/oh-my-posh/default.omp.json".source =
                    ./common/zsh/default.omp.json;
                };
            }
          ] ++ extraModules;
          specialArgs = {
            inherit inputs self hostname;
            username = username;
          };
        };

      # Overlays
      overlays = [
        (import ./overlays/tfenv.nix)
        (import ./overlays/nvm.nix)
        (import ./overlays/browser-forward.nix)
      ];

      # Create a version of nixpkgs with our overlays for Linux
      nixpkgsWithOverlays = system:
        import nixpkgs {
          inherit system;
          inherit overlays;
        };
    in {
      # Generic macOS configuration - can be customized with hostname and user
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
      # Install with:
      # $ nix run home-manager/master -- switch --flake ~/.config/nix#vagrant
      homeConfigurations = {
        "vagrant" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgsWithOverlays "aarch64-linux";
          modules = [
            ./vagrant/home.nix
            {
              home = {
                username = "vagrant";
                homeDirectory = "/home/vagrant";
                stateVersion = "23.11";
              };
              nixpkgs.config.allowUnfree = true;
            }
          ];
          extraSpecialArgs = { username = "vagrant"; };
        };
      };
    };
}
