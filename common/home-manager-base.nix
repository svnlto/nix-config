{
  username,
  lib,
  hostname ? "",
  ...
}:

let
  sharedZsh = import ./zsh/shared.nix;
  versions = import ./versions.nix;
  # morty is a Zscaler appliance VM — skip the workstation modules.
  isAppliance = hostname == "morty";
in
{
  imports = [
    ./home-packages.nix
    ./programs/default.nix
  ]
  ++ lib.optionals (!isAppliance) [
    ./claude-code/default.nix
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
