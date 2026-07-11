{ pkgs, username, ... }:

{
  imports = [
    ../../common/home-manager-base.nix
    ../../common/lazygit/default.nix
    ../../common/git
    ../../common/ssh
  ];

  # macOS-specific home directory
  home.homeDirectory = "/Users/${username}";

  # macOS-specific packages
  home.packages =
    let
      packages = import ../../common/packages.nix { inherit pkgs; };
    in
    packages.darwinPackages;

  # macOS-specific shell aliases
  programs.zsh.shellAliases = {
    nixswitch = "sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/.config/nix#$(scutil --get LocalHostName)";
    darwin-rebuild = "sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/.config/nix#$(scutil --get LocalHostName)";
    brewup = "brew update && brew upgrade && brew upgrade --cask --greedy";
  };

  # CRITICAL: Source nix-darwin's system zshrc BEFORE any other zsh init so /run/current-system/sw/bin lands in PATH.
  programs.zsh.envExtra = ''
    # Source nix-darwin system configuration
    if [ -e /etc/zsh/zshrc ]; then
      source /etc/zsh/zshrc
    fi
  '';
}
