{ config, pkgs, ... }:

{
  # Define packages to be installed via Linuxbrew
  # This is used by the setup-linuxbrew.sh script
  linuxbrew = {
    # Basic tools and dependencies
    brews = [
      "gcc"
      "pyenv"
      "node"
      "tree"
      "wget"
      "jq"
      # Add more command-line packages as needed
    ];

    # Third-party repositories
    taps = [
      # Add any taps you need, for example:
      # "homebrew/core"
    ];

    # Settings for update behavior (similar to macOS)
    onActivation = {
      autoUpdate = true; # Update homebrew itself
      upgrade = true; # Upgrade all packages
      cleanup =
        "zap"; # Remove unused packages (options: "none", "uninstall", "zap")
    };
  };
}
