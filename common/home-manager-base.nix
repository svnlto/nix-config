# Shared Home Manager base configuration
# Contains common settings used by both macOS and Linux configurations
{ username, ... }:

let sharedZsh = import ./zsh/shared.nix;
in {
  # Common imports for all Home Manager configurations
  imports = [
    ./home-packages.nix
    ./claude-code/default.nix
    ./programs/default.nix
    ./scripts/default.nix
  ];

  # Base home configuration (homeDirectory set per platform)
  home = {
    username = username;
    stateVersion = "24.05"; # Manage this manually for now
  };

  # Import shared session variables and paths
  home.sessionVariables = sharedZsh.sessionVariables;
  home.sessionPath = sharedZsh.sessionPath;

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source =
    ./zsh/default.omp.json;
}
