# Generic aarch64-linux Home Manager configuration
# This configuration can be used for any Linux ARM64 environment (VMs, containers, cloud instances)
{ config, pkgs, username ? "user", worktreeManager, ... }:

{
  imports = [ ../../common/home-manager-base.nix ../../common/default.nix ];

  # Linux-specific home directory
  home.homeDirectory = "/home/${username}";

  # Linux-specific nix settings
  nix = {
    package = pkgs.nix;
    settings.auto-optimise-store =
      true; # Linux can handle this better than macOS
  };

  # Linux-specific session variables
  home.sessionVariables = { EDITOR = "nvim"; };

  # Linux-specific ZSH initialization
  programs.zsh.initContent = ''
    # Load worktree manager
    ${worktreeManager}
  '';

  # Additional Linux packages for development environments
  home.packages = with pkgs; [
    # System monitoring and utilities
    htop
    neofetch
    curl
    wget

    # Development tools
    docker-compose
  ];

  # Disable fish if it causes issues (like in the original vagrant config)
  programs.fish.enable = false;
}
