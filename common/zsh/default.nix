# This file is a proper NixOS module that re-exports the shared ZSH configuration
{ config, lib, pkgs, ... }:

{
  # This is an empty NixOS module
  # It doesn't set any configuration options itself
  # The shared ZSH configuration is imported directly by darwin/zsh.nix and ubuntu-orbstack/zsh.nix
  # This file exists to satisfy the directory import in common/default.nix
}
