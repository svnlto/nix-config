# macOS Dock configuration
{ lib, username, hostname, ... }:

let
  # Use the actual path to dockutil instead of pkgs.homebrew
  dockutil = "/opt/homebrew/bin/dockutil";

  # Define host-specific dock apps
  dockAppsByHost = {
    # Default configuration (used if no host-specific config exists)
    "default" = [
      "/Applications/Ghostty.app"
      "/Applications/Arc.app"
      "/Applications/Claude.app"
    ];
  };

  # Select the dock apps for the current hostname or fall back to default
  selectedDockApps = if builtins.hasAttr hostname dockAppsByHost then
    dockAppsByHost.${hostname}
  else
    dockAppsByHost.default;

  # Build the dock configuration script (defined once, reused below)
  dockConfigScript = apps: ''
    ${dockutil} --remove all --no-restart
    ${lib.concatStringsSep "\n" (map (app: ''
      ${dockutil} --add "${app}" --no-restart
    '') apps)}
    killall Dock
  '';
in {
  # Export the configuration through options instead of _module.args
  options = { };

  # Create a proper module configuration
  config = {
    system.activationScripts = {
      # Dock configuration via postActivation
      postActivation.text = lib.mkAfter ''
        echo "==== Configuring Dock ====" >&2
        # Use su for dockutil commands
        su ${username} -c '${dockConfigScript selectedDockApps}' >&2
      '';
    };
  };
}
