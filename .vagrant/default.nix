{ config, pkgs, lib, username, ... }:

{
  imports = [ ./home.nix ];

  # Ubuntu/Linux specific packages
  environment.systemPackages = with pkgs; [ docker curl wget htop ];

  # Basic system settings
  networking.hostName = "ubuntu";
  time.timeZone = "Asia/Bangkok";

  # User configuration
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    # Ensure sudo access
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here for remote access
    ];
  };

  # Configure passwordless sudo access
  security.sudo = {
    enable = true;
    wheelNeedsPassword =
      false; # Allow members of group wheel to execute sudo without a password
  };

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
