{ pkgs, ... }:

let packages = import ./packages.nix { inherit pkgs; };
in {
  imports = [ ./neovim ./ghostty ];

  # Common packages for all platforms (user-level)
  home.packages = packages.allCommonPackages;
}
