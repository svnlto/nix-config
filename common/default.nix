{ config, pkgs, username, ... }:

{
  imports = [ ./zsh ];

  # Common packages for all platforms
  environment.systemPackages = with pkgs; [
    # CLI utilities
    oh-my-posh
    hstr
    eza
    ack
    zoxide
    bat

    # Development tools
    gh
    nixfmt-classic
    diff-so-fancy
  ];

  # Common settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" username ];

    # Settings to improve lock handling
    use-case-hack = true; # Better handle edge cases in containers
    fallback = true; # Allow fallback to build if binary substitute fails
    keep-going = true; # Continue building derivations if one fails
    log-lines = 50; # Show more log lines for better debugging
    max-jobs = "auto"; # Set to optimal number for the system
    connect-timeout = 10; # Shorter connection timeout

    # Increase download buffer size (fix for download buffer warning)
    download-buffer-size = 32768; # 32MB buffer (default is 16MB)
  };

  # Set up automatic store optimization (replacing auto-optimise-store)
  nix.optimise.automatic = true;
  nix.settings.auto-optimise-store = false; # Disable the deprecated option

  # Additional Nix daemon options for containerized environments
  nix.extraOptions = ''
    # Increase timeout for lock contention
    stalled-download-timeout = 90
    builders-use-substitutes = true
    # Retry locking store if contention occurs
    narinfo-cache-negative-ttl = 0

    # Alternative location for download buffer size if the setting above doesn't work
    download-buffer-size = 32768
  '';

  # Allow unfree software across platforms
  nixpkgs.config.allowUnfree = true;
}
