# This file defines a proper NixOS module for ZSH configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Import the shared configuration, but don't return it directly
  sharedZsh = import ./shared.nix;
in
{
  # Export the shared config for use by other modules
  _module.args.zshShared = sharedZsh;

  # No direct configuration is set here to avoid conflicts
  # Each platform will use the shared config in its own way
}
