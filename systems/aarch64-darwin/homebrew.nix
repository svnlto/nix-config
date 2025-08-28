{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [ "FelixKratz/formulae" ];
    brews = [ "mas" "dockutil" "pre-commit" "rclone" ];
    casks = [
      # Security & Password Management
      "1password"
      "1password-cli"
      "ledger-live"

      # Productivity Tools
      "raycast"
      "setapp"
      "notion-calendar"
      "notion-mail"

      # Communication & Collaboration
      "linear-linear"
      "slack"
      "zoom"
      "whatsapp"
      "telegram"
      "claude" # desktop

      # Development & Terminal
      "orbstack"
      "zed"
      "ghostty"

      # Media & Entertainment
      "spotify"
      "vlc"
      "zwift"
      "figma"
    ];
    masApps = { };
    onActivation = {
      cleanup = "uninstall"; # Less aggressive than "zap"
      upgrade = true;
      autoUpdate = true;
    };
  };
}
