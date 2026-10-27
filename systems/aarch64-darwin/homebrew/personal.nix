_:

# rick (personal host) Homebrew. No shared-real-mac layer by design.
{
  homebrew = {
    brews = [
      "mas"
      "pre-commit"
      "herdr"
    ];

    casks = [
      # Security & Password Management
      "1password"
      "1password-cli"
      "proton-pass"
      "proton-drive"
      "ledger-wallet"

      # Productivity
      "raycast"
      "setapp"
      "obsidian"
      "marked-app"
      "caskhub"
      "granola"
      "drawio"

      # Communication & Collaboration
      "microsoft-teams"
      "microsoft-outlook"
      "whatsapp"
      "telegram"
      "signal"

      # Development & Terminal
      "orbstack"
      "ghostty"
      "claude" # desktop
      "claude-code"
      "claude-devtools"
      "antigravity-cli"

      # Browsers
      "google-chrome"
      "thebrowsercompany-dia"

      # Media & Entertainment
      "vlc"
      "betterdisplay"
      "spotify"
      "zwift"

      # Networking & Virtualization
      "tailscale-app"
      "winbox"
    ];
  };
}
