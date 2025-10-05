{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [ "FelixKratz/formulae" ];
    brews = [ "mas" "dockutil" "pre-commit" ];
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
      "superwhisper"

      # Communication & Collaboration
      "linear-linear"
      "slack"
      "whatsapp"
      "telegram"
      "signal"
      "claude" # desktop

      # Development & Terminal
      "orbstack"
      "ghostty"

      # Networking & VPN
      "tailscale-app"

      # Media & Entertainment
      "spotify"
      "vlc"
      "zwift"
    ];
    masApps = { };
    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
