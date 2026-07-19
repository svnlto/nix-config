{
  config,
  pkgs,
  lib,
  self,
  username,
  hostname,
  ...
}:

let
  versions = import ../../common/versions.nix;
  constants = import ../../common/constants.nix;
in
{
  imports = [
    ./homebrew/common.nix
    ./defaults.nix
    ./dock.nix
  ];

  environment = {
    # macOS specific packages
    systemPackages =
      let
        packages = import ../../common/packages.nix { inherit pkgs; };
      in
      packages.darwinSystemPackages;

    # System-wide environment variables
    variables = {
      NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
    };

  };

  # macOS-specific Nix settings (experimental-features and trusted-users come
  # from common/default.nix; use-case-hack is a case-insensitive-APFS workaround
  # that belongs only on darwin).
  nix = {
    package = pkgs.nixVersions.nix_2_31;
    settings.use-case-hack = true;
    optimise.automatic = true;
  };

  programs.zsh.enable = true;

  system = {
    configurationRevision = self.rev or self.dirtyRev or null;
    stateVersion = versions.darwinStateVersion;
    primaryUser = username;

    activationScripts = {
      applications.text =
        let
          env = pkgs.buildEnv {
            name = "system-applications";
            paths = config.environment.systemPackages;
            # 26.05 buildEnv (strict under structuredAttrs) requires a list.
            pathsToLink = [ "/Applications" ];
          };
        in
        lib.mkForce ''
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

      # Set desktop wallpaper
      setWallpaper.text =
        let
          wallpaper = ../../common/profiles/wallpapers/bg.jpg;
        in
        ''
          echo "Setting desktop wallpaper..." >&2
          su ${username} -c 'osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"${wallpaper}\""' >&2 || true
        '';

      # Create necessary directories
      createDirectories.text = ''
        echo "Creating user directories..." >&2
        mkdir -p /Users/${username}/Desktop/screenshots
        chown ${username}:staff /Users/${username}/Desktop/screenshots
      '';

      postActivation.text = lib.mkAfter ''
        # Homebrew update/upgrade is handled by nix-darwin onActivation (common.nix homebrew.onActivation, corporate.nix override).

        # Optional cleanup - only run if CLEANUP_ON_REBUILD is set
        if [[ "$CLEANUP_ON_REBUILD" == "true" ]]; then
          echo "==== Starting system cleanup ===="
          # Clean up old generations (keep last ${toString constants.cleanup.generationRetentionDays} days)
          nix-collect-garbage --delete-older-than ${toString constants.cleanup.generationRetentionDays}d || true

          # Optimize nix store
          nix store optimise || true

          echo "==== System cleanup completed ===="
        else
          echo "ℹ️  Skipping automatic cleanup (set CLEANUP_ON_REBUILD=true to enable)"
        fi >&2
      '';

    };
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = hostname;

  ids.gids.nixbld = 350;

  users.users.${username} = {
    description = username;
    shell = pkgs.zsh;
    home = "/Users/${username}";
  };
}
