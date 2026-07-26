{ pkgs, ... }:

let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  imports = [
    ./neovim
    ./ghostty
    ./herdr
    ./k9s
    ./gh-dash
  ];

  home.packages = packages.allCommonPackages;
}
