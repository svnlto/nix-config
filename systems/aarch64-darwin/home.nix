{ config, pkgs, username, lib, ... }:

{
  imports =
    [ ../../common/home-manager-base.nix ../../common/lazygit/default.nix ];

  # macOS-specific home directory
  home.homeDirectory = "/Users/${username}";
}
