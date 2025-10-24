{ ... }:

{
  homebrew = {
    enable = true;
    taps = [ "FelixKratz/formulae" "nikitabobko/tap" ];
    brews = [ "mas" "dockutil" "pre-commit" "borders" "sketchybar" ];
    casks = [
      # Security & Password Management
      "1password"
      "1password-cli"
      "ledger-live"

      # Productivity Tools
      "raycast"
      "nikitabobko/tap/aerospace"
      "setapp"
      "notion-calendar"
      "notion-mail"
      "superwhisper"
      "obsidian"
      "brainfm"

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
      "utm"

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
