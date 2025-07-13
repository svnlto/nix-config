# GitHub CLI configuration
{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  # Enable GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      # Default protocol when cloning repositories
      git_protocol = "ssh";

      # Default editor
      editor = "nvim";

      # Prompt for every command
      prompt = "enabled";
    };
  };
}
