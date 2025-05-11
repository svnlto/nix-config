# GitHub CLI configuration
{ config, lib, pkgs, username, ... }:

{
  # Enable GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      # Default browser for GitHub CLI
      # This will use the browser-forward provider that routes to the host
      browser = "browser-forward";

      # Default protocol when cloning repositories
      git_protocol = "ssh";

      # Default editor
      editor = "nvim";

      # Prompt for every command
      prompt = "enabled";
    };
  };
}
