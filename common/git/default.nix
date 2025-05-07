# This git module is the entry point for common git functionality
{ config, lib, pkgs, username, ... }:

{
  # Simply import the git config directly as a module
  imports = [ ./config.nix ];
}
