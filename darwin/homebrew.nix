{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [
      "FelixKratz/formulae"
      "hashicorp/tap" # For Hashicorp's Vagrant
    ];
    brews = [ "mas" "dockutil" ];
    casks = [
      # customize this list to your needs
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

      # Virtualization tools
      "virtualbox"
      "utm" # Free and open-source virtualization
      "hashicorp/tap/hashicorp-vagrant"
      "vagrant"
    ];
    masApps = { };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
