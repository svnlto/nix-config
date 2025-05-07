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
      "/Applications/Spotify.app"
      "/Applications/Visual Studio Code.app"
      "/Applications/iTerm.app"
    ];

    # Default configuration (used if no host-specific config exists)
    "default" = [ "/Applications/Arc.app" "/Applications/Spotify.app" ];

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

  # Build the dock configuration script
  dockConfigScript = apps: ''
    ${dockutil} --remove all --no-restart
    ${lib.concatStringsSep "\n" (map (app: ''
      ${dockutil} --add "${app}" --no-restart
    '') apps)}
    killall Dock
  '';
in {
  # Export the dock apps and configuration script for use in default.nix
  _module.args.selectedDockApps = selectedDockApps;
  _module.args.dockConfigScript = dockConfigScript;
}
