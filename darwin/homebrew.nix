{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [ "FelixKratz/formulae" ];
    brews = [ "mas" "dockutil" ];
    casks = [
      "1password"
      "1password-cli"
      "setapp"
      "notion-calendar"
      "notion-mail"
      "slack"
      "spotify"
      "tailscale"
      "todoist"
      "visual-studio-code"
      "vlc"
      "whatsapp"
      "orbstack"
      "telegram"
      "raycast"
      "zoom"
      "iterm2"
      "zwift"
      "ledger-live"
      "vcv-rack"
      "ableton-live-standard"
      "transmission"
    ];
    masApps = { };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
