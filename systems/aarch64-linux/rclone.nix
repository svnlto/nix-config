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

      # Backup existing config if present
      if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
        cp "$HOME/.config/rclone/rclone.conf" "$HOME/.config/rclone/rclone.conf.backup-$(date +%Y%m%d%H%M%S)"
      fi

      # Check if rclone configuration exists
      if [ ! -f "$HOME/.config/rclone/rclone.conf" ]; then
        echo "Error: No rclone configuration found at $HOME/.config/rclone/rclone.conf"
        echo "Please run 'rclone config' to set up your Google Drive remote before mounting."
        exit 1
      fi

      # Check if gdrive remote exists
      if ! rclone listremotes | grep -q "^gdrive:$"; then
        echo "Error: No 'gdrive:' remote found in rclone configuration."
        echo "Please run 'rclone config' to set up your Google Drive remote before mounting."
        exit 1
      fi

      # Stop any existing rclone processes
      pkill -f "rclone mount gdrive:" 2>/dev/null || true

      # Create mount directory in /vagrant
      mkdir -p $HOME/google-drive

      # Create a local cache directory for better performance
      mkdir -p $HOME/.cache/rclone

      # Mount with highly optimized settings for better performance
      rclone mount gdrive: $HOME/google-drive \
        --daemon \
        --allow-non-empty \
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
        --log-file=$HOME/rclone-gdrive.log

      echo "Google Drive mounted at $HOME/google-drive with optimized settings"
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
      Environment =
        [ "PATH=${lib.makeBinPath [ pkgs.rclone pkgs.fuse pkgs.coreutils ]}" ];
    };

    Install = { WantedBy = [ "default.target" ]; };
  };

  # Create unmount script
  home.file.".bin/unmount-gdrive" = {
    executable = true;
    text = ''
      #!/bin/bash

      # Unmount Google Drive (from home directory)
      fusermount -u $HOME/google-drive

      echo "Google Drive unmounted"
    '';
  };

  # Create status check script
  home.file.".bin/gdrive-status" = {
    executable = true;
    text = ''
      #!/bin/bash

      # First check the mount point directly - most reliable method
      if mountpoint -q "$HOME/google-drive" 2>/dev/null; then
        echo "✅ Google Drive is mounted at $HOME/google-drive"
        echo "Cache directory: $HOME/.cache/rclone"
        echo "Log file: $HOME/rclone-gdrive.log"
        
        # Check disk usage of cache
        echo -e "\nCache usage:"
        du -sh $HOME/.cache/rclone 2>/dev/null || echo "Cache not yet created"
        
        # Show recent log entries
        echo -e "\nRecent log entries:"
        tail -n 5 $HOME/rclone-gdrive.log 2>/dev/null || echo "No log entries yet"
      else
        # Try several methods to detect the rclone process
        if ps aux | grep -v grep | grep -q "[r]clone.*gdrive:"; then
          echo "⚠️ Rclone process found but mount point is not active"
        else
          echo "❌ Google Drive is not mounted"
          echo "No rclone process for gdrive found"
        fi
        
        # Check if mount directory exists
        if [ ! -d "$HOME/google-drive" ]; then
          echo "Mount directory does not exist. Run mount-gdrive to create and mount it."
        fi
      fi
    '';
  };

  # Add zsh aliases for easy mounting/unmounting
  programs.zsh.shellAliases = {
    "gdrive-mount" = "$HOME/.bin/mount-gdrive";
    "gdrive-unmount" = "$HOME/.bin/unmount-gdrive";
    "gdrive-status" = "$HOME/.bin/gdrive-status";
  };
}
