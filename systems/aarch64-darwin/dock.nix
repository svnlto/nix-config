# macOS Dock configuration
{ config, lib, pkgs, username, hostname, ... }:

let
  # Use the actual path to dockutil instead of pkgs.homebrew
  dockutil = "/opt/homebrew/bin/dockutil";

  # Define host-specific dock apps
  dockAppsByHost = {
    # Configuration for Rick (your current Mac)
    "Rick" = [
      "/Applications/Arc.app"
      "/Applications/Zed.app"
      "/Applications/Linear.app"
      "/applications/Slack.app"
      "/applications/Claude.app"
      "/applications/Pieces.app"
    ];

    # Default configuration (used if no host-specific config exists)
    "default" = [ ];

    # Example for another Mac (uncomment and customize as needed)
    # "work-mac" = [
    #   "/Applications/Safari.app"
    #   "/Applications/Mail.app"
    #   "/Applications/Calendar.app"
    #   "/Applications/Slack.app"
    #   "/Applications/Visual Studio Code.app"
    #   "/Applications/Terminal.app"
    # ];
  };

  # Select the dock apps for the current hostname or fall back to default
  selectedDockApps = if builtins.hasAttr hostname dockAppsByHost then
    dockAppsByHost.${hostname}
  else
    dockAppsByHost.default;
in {
  # Export the configuration through options instead of _module.args
  options = { };

  # Create a proper module configuration
  config = {
    system.activationScripts = {
      dock.text = let
        # Build the dock configuration script
        dockConfigScript = apps: ''
          ${dockutil} --remove all --no-restart
          ${lib.concatStringsSep "\n" (map (app: ''
            ${dockutil} --add "${app}" --no-restart
          '') apps)}
          killall Dock
        '';
      in dockConfigScript selectedDockApps;

      # Update the postActivation script to use our dock config
      postActivation.text = lib.mkAfter ''
        echo "==== Configuring Dock ====" >&2
        # Use su for dockutil commands
        su ${username} -c '${
          let
            dockConfigScript = apps: ''
              ${dockutil} --remove all --no-restart
              ${lib.concatStringsSep "\n" (map (app: ''
                ${dockutil} --add "${app}" --no-restart
              '') apps)}
              killall Dock
            '';
          in dockConfigScript selectedDockApps
        }' >&2
      '';
    };
  };
}
