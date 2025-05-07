# This file serves as a proper NixOS module for ZSH configuration
{ config, lib, pkgs, ... }:

# A simple and empty module that doesn't cause errors
# The actual shared ZSH configuration is imported directly by 
# darwin/zsh.nix and ubuntu-orbstack/zsh.nix
{
  # No configuration is set here to avoid conflicts between nix-darwin and home-manager
}
