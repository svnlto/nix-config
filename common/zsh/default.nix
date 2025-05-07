# ZSH common configuration module
{ config, lib, pkgs, ... }:

# This is a proper NixOS module that both nix-darwin and home-manager can import
{
  # Empty module that doesn't set any configuration
  # The actual ZSH configuration is imported directly by darwin/zsh.nix and ubuntu-orbstack/zsh.nix
  # This file exists just to make importing ./common/zsh as a module work without errors
}
