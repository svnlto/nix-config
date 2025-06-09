{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [ "FelixKratz/formulae" "hashicorp/tap" ];
    brews = [ "mas" "dockutil" "pre-commit" "rclone" "qemu"];
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

      # Development & Terminal
      "hashicorp/tap/hashicorp-vagrant"
      "vagrant"
      "zed"
      "pieces"
      "claude"

      # Networking & Utilities
      "tailscale"

      # Media & Entertainment
      "spotify"
      "vlc"
      "zwift"
      "vcv-rack"
      "ableton-live-standard"
      "figma"
    ];
    masApps = { };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
