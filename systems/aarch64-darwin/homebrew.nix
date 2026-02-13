_:

{
  homebrew = {
    enable = true;
    taps = [ ];
    brews = [ "mas" "dockutil" "pre-commit" ];
    casks = [
      # Fonts
      "font-sf-pro"

      # Security & Password Management
      "1password"
      "1password-cli"
      "proton-pass"
      "ledger-wallet"

      # Productivity Tools
      "raycast"
      "setapp"
      "superwhisper"
      "obsidian"
      "brainfm"

      # Communication & Collaboration
      "linear-linear"
      "slack"
      "discord"
      "whatsapp"
      "telegram"
      "signal"
      "claude" # desktop
      "proton-drive"

      # Development & Terminal
      "orbstack"
      "ghostty"
      "claude-code"
      "utm"
      "vagrant-vmware-utility"
      "winbox"

      # Networking & VPN
      "arc"
      "google-chrome"
      "tailscale-app"
      "mullvad-vpn@beta"

      # Media & Entertainment
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
