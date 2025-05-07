{ config, pkgs, ... }:

{
  # Define packages to be installed via Linuxbrew
  # This is used by the setup-linuxbrew.sh script
  linuxbrew = {
    # Basic tools and dependencies
    brews = [
      "gcc"
      "jq"
      "nvm"
      "tfenv"
      "pre-commit"
      # Add more command-line packages as needed
    ];

    # Third-party repositories
    taps = [
      # Add any taps you need, for example:
      # "homebrew/core"
    ];
  };
}
