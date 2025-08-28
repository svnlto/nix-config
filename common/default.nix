{ config, pkgs, username, ... }:

{
  imports = [ ./zsh ];

  # Common Nix settings - platform-specific settings should be in respective files
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" username ];

      # Performance optimizations
      max-jobs = "auto";
      cores = 0; # Use all available cores
      build-cores = 0;

      # Settings to improve lock handling and build performance
      use-case-hack = true;
      fallback = true;
      keep-going = true;
      log-lines = 25;
      download-buffer-size =
        268435456; # 256MB download buffer (optimized for 16GB RAM)

      # Substituter optimizations for 16GB RAM system
      builders-use-substitutes = true;
      http-connections = 50; # Increased for faster parallel downloads
      max-substitution-jobs = 32; # Increased for better parallelization
      stalled-download-timeout = 300; # 5 minutes timeout
      connect-timeout = 30; # Optimized connection timeout
    };

    # Set up automatic store optimization
    optimise.automatic = true;
    settings.auto-optimise-store = false; # Disable the deprecated option

    # Shared extra options
    extraOptions = ''
      stalled-download-timeout = 90
      narinfo-cache-negative-ttl = 0
    '';
  };

  # Allow unfree software across platforms
  nixpkgs.config.allowUnfree = true;
}
