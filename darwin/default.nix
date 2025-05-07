{ config, pkgs, lib, username, hostname, ... }:

{
  imports = [ ./homebrew.nix ./defaults.nix ./zsh.nix ./dock.nix ];

  # macOS specific packages
  environment.systemPackages = with pkgs; [
    oh-my-posh
    eza
    hstr
    git # Added Git as a system package
    diff-so-fancy # Added diff-so-fancy for Git
  ];

  # Enable alternative shell support
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version
  system.configurationRevision = lib.mkIf (builtins ? currentSystem) null;

  # Used for backwards compatibility
  system.stateVersion = 5;

  ids.gids.nixbld = 30000;

  # System activation scripts
  system.activationScripts = {
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

    # Dock configuration is now handled in dock.nix

    postActivation.text = lib.mkAfter ''
      echo "==== Starting Homebrew Updates ====" >&2

      # Run Homebrew commands as the user with proper environment setup and send output to stderr
      echo "Running brew update..." >&2
      su ${username} -c '/opt/homebrew/bin/brew update' >&2

      echo "Running brew upgrade --cask --greedy..." >&2
      su ${username} -c '/opt/homebrew/bin/brew upgrade --cask --greedy' >&2

      # Dock configuration is now handled in dock.nix

      echo "==== Homebrew update completed ====" >&2
    '';
  };

  # SSH configuration
  environment.etc."user-ssh-config".source = pkgs.writeText "ssh-config" ''
    Include ~/.orbstack/ssh/config

    Host *
      AddKeysToAgent yes
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      Protocol 2
      Compression yes
      ServerAliveInterval 20
      ServerAliveCountMax 10
      TCPKeepAlive yes
  '';

  system.activationScripts.userSshConfig.text = ''
    mkdir -p /Users/${username}/.ssh
    cp ${
      config.environment.etc."user-ssh-config".source
    } /Users/${username}/.ssh/config
    chown ${username}:staff /Users/${username}/.ssh/config
    chmod 600 /Users/${username}/.ssh/config
  '';

  security.pam.services.sudo_local.touchIdAuth = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Use hostname from flake parameters
  networking.hostName = hostname;

  users.users.${username} = {
    description = "${username}";
    shell = pkgs.zsh;
    home = "/Users/${username}";
  };
}
