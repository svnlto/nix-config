{
  pkgs,
  lib,
  hostname ? "",
  ...
}:

let
  packages = import ./packages.nix { inherit pkgs; };
  # morty (Zscaler appliance VM): corePackages only, no workstation modules.
  isAppliance = hostname == "morty";
in
{
  imports = lib.optionals (!isAppliance) [
    ./neovim
    ./ghostty
    ./herdr
    ./k9s
    ./gh-dash
  ];

  home.packages = if isAppliance then packages.corePackages else packages.allCommonPackages;
}
