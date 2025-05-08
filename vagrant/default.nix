{ config, pkgs, lib, username, ... }:

{
  imports = [ ./home.nix ];

  # VM-specific packages
  environment.systemPackages = with pkgs; [ docker curl wget htop ];

  # Basic system settings
  networking.hostName = "nix-dev";
  time.timeZone = "Asia/Bangkok";

  # Nix configuration
  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [ "root" username ];
      download-buffer-size = 65536; # 64MB buffer
      max-jobs = 3;
      cores = 1;
      trusted-substituters = true;
      builders-use-substitutes = true;
      http-connections = 25;

      # Binary caches
      substituters =
        [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # User configuration
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    shell = pkgs.zsh;
  };

  # Configure passwordless sudo access
  security.sudo = { enable = true; };

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    startAgent = true;
  };

  # Docker support
  virtualisation.docker.enable = true;

  # Configure home-manager for the user
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = import ./home.nix;
    extraSpecialArgs = { inherit username; };
  };

  # System configuration
  system.stateVersion = "23.11";
}
