{ pkgs, ... }:

let packages = import ./packages.nix { inherit pkgs; };
in {
  imports = [ ./neovim ./ghostty ./tmux ./tmuxinator ./k9s ./gh-dash ];

  # Common packages for all platforms (user-level)
  home.packages = packages.allCommonPackages;
}
