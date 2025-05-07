{ config, pkgs, username, ... }:

{
  # Common packages for all platforms
  environment.systemPackages = with pkgs; [
    ack
    neovim
    zoxide
    bat
    gh
    nixfmt-classic
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
    # auto-optimise-store = true; # Removed: Known to corrupt the Nix Store
    connect-timeout = 10; # Shorter connection timeout
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
  '';

  # Allow unfree software across platforms
  nixpkgs.config.allowUnfree = true;
}
