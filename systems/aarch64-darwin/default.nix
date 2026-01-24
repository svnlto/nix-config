{ config, pkgs, lib, username, hostname, ... }:

let
  versions = import ../../common/versions.nix;
  constants = import ../../common/constants.nix;
in {
  imports = [ ./homebrew.nix ./defaults.nix ./dock.nix ];

  environment = {
    # macOS specific packages
    systemPackages =
      let packages = import ../../common/packages.nix { inherit pkgs; };
      in packages.darwinSystemPackages;

    # System-wide environment variables
    variables = {
      NIX_SSL_CERT_FILE =
        "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
    };

    # SSH configuration
    etc."user-ssh-config".source = pkgs.writeText "ssh-config" ''
      Host *
        AddKeysToAgent yes
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        Protocol 2
        Compression yes
        ServerAliveInterval 20
        ServerAliveCountMax 10
        TCPKeepAlive yes
    '';
  };

  # macOS-specific Nix settings
  nix = {
    package = pkgs.nixVersions.nix_2_29;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" username ];
    };
    optimise.automatic = true;
  };

  programs.zsh.enable = true;

  ids.gids.nixbld = 350;

  system = {
    configurationRevision = lib.mkIf (builtins ? currentSystem) null;
    stateVersion = versions.darwinStateVersion;
    primaryUser = username;

    activationScripts = {
      applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

      # Create necessary directories
      createDirectories.text = ''
        echo "Creating user directories..." >&2
        mkdir -p /Users/${username}/Desktop/screenshots
        chown ${username}:staff /Users/${username}/Desktop/screenshots
      '';

      postActivation.text = lib.mkAfter ''
        echo "==== Starting Homebrew Updates ====" >&2

        # Run Homebrew commands as the user with proper environment setup and send output to stderr
        echo "Running brew update..." >&2
        if ! su ${username} -c '/opt/homebrew/bin/brew update' >&2; then
          echo "⚠️  Homebrew update failed, continuing..." >&2
        fi

        echo "Running brew upgrade --cask --greedy..." >&2
        if ! su ${username} -c '/opt/homebrew/bin/brew upgrade --cask --greedy' >&2; then
          echo "⚠️  Homebrew cask upgrade failed, continuing..." >&2
        fi

        # Dock configuration is now handled in dock.nix

        echo "==== Homebrew update completed ===="

        # Optional cleanup - only run if CLEANUP_ON_REBUILD is set
        if [[ "$CLEANUP_ON_REBUILD" == "true" ]]; then
          echo "==== Starting system cleanup ===="
          # Clean up old generations (keep last ${
            toString constants.cleanup.generationRetentionDays
          } days)
          nix-collect-garbage --delete-older-than ${
            toString constants.cleanup.generationRetentionDays
          }d || true

          # Optimize nix store
          nix store optimise || true

          echo "==== System cleanup completed ===="
        else
          echo "ℹ️  Skipping automatic cleanup (set CLEANUP_ON_REBUILD=true to enable)"
        fi >&2
      '';

      userSshConfig.text = ''
        mkdir -p /Users/${username}/.ssh
        cp ${
          config.environment.etc."user-ssh-config".source
        } /Users/${username}/.ssh/config
        chown ${username}:staff /Users/${username}/.ssh/config
        chmod 600 /Users/${username}/.ssh/config
      '';
    };
  };

  # Enable Touch ID for sudo (including in tmux)
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = hostname;

  users.users.${username} = {
    description = "${username}";
    shell = pkgs.zsh;
    home = "/Users/${username}";
  };
}
