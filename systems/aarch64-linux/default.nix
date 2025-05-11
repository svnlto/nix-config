{ config, pkgs, lib, username, ... }:

{
  imports = [ ./home.nix ];

  # VM-specific packages
  environment.systemPackages = with pkgs; [ 
    curl 
    wget
    fuse
    fuse3
  ];

  # Environment variables
  environment.variables = {
    # Rust compilation optimizations
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache"; # Use compilation cache
    CARGO_INCREMENTAL = "1"; # Enable incremental builds
    RUST_BACKTRACE = "1"; # Better error reporting
    RUSTFLAGS = "-C target-cpu=native"; # Optimize for your CPU
  };

  # Basic system settings
  networking.hostName = "nix-dev";
  time.timeZone = "Asia/Bangkok";

  # Nix configuration
  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [ "root" username ];
      download-buffer-size = 65536;
      max-jobs = 3;
      cores = 1;
      trusted-substituters = true;
      builders-use-substitutes = true;
      fallback = true;
      http-connections = 25;

      # Binary caches
      substituters =
        [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    preferBinaryCaches = true;
  };

  # User configuration
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "docker" "fuse" ];
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

  # VM Performance Optimizations
  # Set swappiness for better VM performance
  boot.kernel.sysctl = { "vm.swappiness" = 10; };

  # Optimize disk I/O scheduler using systemd service
  systemd.services.optimize-io-scheduler = {
    description = "Optimize disk I/O scheduler for virtual machines";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      #!/bin/bash
      for DISK in vda sda; do
        if [ -d "/sys/block/$DISK" ]; then
          echo "none" > /sys/block/$DISK/queue/scheduler
        fi
      done
    '';
  };

  # RAM Disk for temp files and build artifacts
  fileSystems."/ramdisk" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=2G" "mode=1777" ];
  };

  # System configuration
  system.stateVersion = "23.11";
}
