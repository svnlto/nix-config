{ config, pkgs, lib, ... }:

{
  # Install rclone package
  home.packages = with pkgs; [
    rclone
    fuse # For mounting support
  ];

  # Create rclone mount script with optimized settings
  home.file.".bin/mount-gdrive" = {
    executable = true;
    text = ''
      #!/bin/bash
      
      # Stop any existing rclone processes
      pkill -f "rclone mount gdrive:" 2>/dev/null || true
      
      # Create mount directory if it doesn't exist
      mkdir -p /vagrant/google-drive
      
      # Create a local cache directory for better performance
      mkdir -p $HOME/.cache/rclone
      
      # Mount with highly optimized settings for better performance
      rclone mount gdrive: /vagrant/google-drive \
        --daemon \
        --vfs-cache-mode full \
        --vfs-cache-max-size 10G \
        --vfs-cache-max-age 72h \
        --vfs-read-ahead 256M \
        --buffer-size 128M \
        --transfers 32 \
        --checkers 32 \
        --dir-cache-time 72h \
        --poll-interval 10s \
        --attr-timeout 10s \
        --vfs-fast-fingerprint \
        --vfs-read-chunk-size 32M \
        --vfs-read-chunk-size-limit 1G \
        --cache-dir=$HOME/.cache/rclone \
        --drive-chunk-size 32M \
        --drive-acknowledge-abuse \
        --drive-pacer-min-sleep 10ms \
        --drive-pacer-burst 200 \
        --use-mmap \
        --no-modtime \
        --stats 0 \
        --log-level INFO \
        --log-file /tmp/rclone-gdrive.log
      
      echo "Google Drive mounted at /vagrant/google-drive with optimized settings"
    '';
  };

  # Add systemd user service to auto-mount Google Drive
  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "Mount Google Drive with rclone";
      After = "network-online.target";
      Wants = "network-online.target";
    };

    Service = {
      Type = "forking";
      ExecStart = "${config.home.homeDirectory}/.bin/mount-gdrive";
      ExecStop = "${config.home.homeDirectory}/.bin/unmount-gdrive";
      Restart = "on-failure";
      RestartSec = "30s";
      Environment = [
        "PATH=${lib.makeBinPath [pkgs.rclone pkgs.fuse pkgs.coreutils]}"
      ];
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Create unmount script
  home.file.".bin/unmount-gdrive" = {
    executable = true;
    text = ''
      #!/bin/bash
      
      # Unmount Google Drive
      fusermount -u /vagrant/google-drive
      
      echo "Google Drive unmounted"
    '';
  };

  # Create status check script
  home.file.".bin/gdrive-status" = {
    executable = true;
    text = ''
      #!/bin/bash
      
      if pgrep -f "rclone mount gdrive:" > /dev/null; then
        echo "✅ Google Drive is mounted at /vagrant/google-drive"
        echo "Cache directory: $HOME/.cache/rclone"
        echo "Log file: /tmp/rclone-gdrive.log"
        
        # Check disk usage of cache
        echo -e "\nCache usage:"
        du -sh $HOME/.cache/rclone 2>/dev/null || echo "Cache not yet created"
        
        # Show recent log entries
        echo -e "\nRecent log entries:"
        tail -n 5 /tmp/rclone-gdrive.log 2>/dev/null || echo "No log entries yet"
      else
        echo "❌ Google Drive is not mounted"
      fi
    '';
  };

  # Add zsh aliases for easy mounting/unmounting
  programs.zsh.shellAliases = {
    "mount-gdrive" = "$HOME/.bin/mount-gdrive";
    "unmount-gdrive" = "$HOME/.bin/unmount-gdrive";
    "gdrive-status" = "$HOME/.bin/gdrive-status";
  };
}
