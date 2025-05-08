{ config, lib, pkgs, username, ... }:

{
  # macOS-specific ZSH configuration for nix-darwin
  # This is now a minimal configuration since Home Manager handles most of the ZSH setup

  # Enable ZSH 
  programs.zsh.enable = true;

  # Keep shell aliases - Home Manager will handle the rest
  environment.shellAliases = {
    nixswitch =
      "darwin-rebuild switch --flake ~/.config/nix#${config.networking.hostName}";
  };
}
