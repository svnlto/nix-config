{ config, pkgs, lib, username, ... }:

{
  imports = [ ./home.nix ];

  # VM-specific packages
  environment.systemPackages = with pkgs; [ docker curl wget htop ];

  # Basic system settings
  networking.hostName = "nix-dev";
  time.timeZone = "Asia/Bangkok";

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
