{ username, ... }:

let
  sharedZsh = import ./zsh/shared.nix;
  versions = import ./versions.nix;
in
{
  imports = [
    ./home-packages.nix
    ./claude-code/default.nix
    ./programs/default.nix
  ];

  # homeDirectory is set per platform
  home = {
    inherit username;
    stateVersion = versions.homeManagerStateVersion;
  };

  home.sessionVariables = sharedZsh.sessionVariables;
  home.sessionPath = sharedZsh.sessionPath;

  home.file.".config/oh-my-posh/default.omp.json".source = ./zsh/default.omp.json;
}
