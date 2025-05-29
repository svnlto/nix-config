{ config, lib, pkgs, username, ... }:

{
  # Make Zed settings available to home-manager
  home-manager.users.${username} = { config, lib, pkgs, ... }: {
    # Set the path where Zed stores its configuration
    home.file.".config/zed/settings.json".source = ./settings.json;
    
    # Ensure Zed configuration directory exists
    home.activation.createZedConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/.config/zed"
    '';
  };

  # Add a separate system activation script to handle permissions
  system.activationScripts.zedConfig = lib.mkIf (username != null) ''
    echo "Setting up Zed configuration directory..."
    mkdir -p /Users/${username}/.config/zed
    echo "Setting Zed configuration permissions..."
    if [ -f /Users/${username}/.config/zed/settings.json ]; then
      chown ${username}:staff /Users/${username}/.config/zed/settings.json
    fi
  '';
}