{ config, pkgs, username, ... }:

{
  imports = [ ./zsh ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" username ];

      # Performance optimizations
      max-jobs = "auto";
      cores = 0;
      build-cores = 0;

      # Settings to improve lock handling and build performance
      use-case-hack = true;
      fallback = true;
      keep-going = true;
      log-lines = 25;
      download-buffer-size = 268435456;
      builders-use-substitutes = true;
      http-connections = 50;
      max-substitution-jobs = 32;
      stalled-download-timeout = 90;
      connect-timeout = 30;
    };

    # Shared extra options
    extraOptions = ''
      narinfo-cache-negative-ttl = 0
    '';
  };

  # Allow unfree software across platforms
  nixpkgs.config.allowUnfree = true;
}
