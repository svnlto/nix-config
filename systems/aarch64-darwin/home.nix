{ config, pkgs, username, lib, ... }:

{
  imports =
    [ ../../common/home-manager-base.nix ../../common/lazygit/default.nix ];

  # macOS-specific home directory
  home.homeDirectory = "/Users/${username}";

  # macOS-specific packages
  home.packages =
    let packages = import ../../common/packages.nix { inherit pkgs; };
    in packages.darwinPackages;

  # macOS-specific shell aliases
  programs.zsh.shellAliases = {
    nixswitch =
      "sudo darwin-rebuild switch --flake ~/.config/nix#$(scutil --get LocalHostName)";
    darwin-rebuild =
      "sudo darwin-rebuild switch --flake ~/.config/nix#$(scutil --get LocalHostName)";
  };
}
