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

  # Common Nix settings - platform-specific settings should be in respective files
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" username ];

      # Settings to improve lock handling
      use-case-hack = true;
      fallback = true;
      keep-going = true;
      log-lines = 50;
      connect-timeout = 10;
      download-buffer-size = 65536; # 64MB download buffer
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
