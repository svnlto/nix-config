# Generic aarch64-linux Home Manager configuration
# This configuration can be used for any Linux ARM64 environment (VMs, containers, cloud instances)
{ config, pkgs, username ? "user", worktreeManager, ... }:

{
  imports = [
    ../../common/home-manager-base.nix
    ../../common/default.nix
    ./git.nix
  ];

  # Linux-specific home directory
  home.homeDirectory = "/home/${username}";

  # Linux-specific nix settings
  nix = {
    package = pkgs.nix;
    settings.auto-optimise-store =
      true; # Linux can handle this better than macOS
  };

  # Linux-specific session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    # Set NIX_SSL_CERT_FILE to use system certificates
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    # SSH askpass for 1Password GUI prompts
    SSH_ASKPASS = "${pkgs.x11-ssh-askpass}/libexec/x11-ssh-askpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  # Linux-specific shell aliases
  programs.zsh.shellAliases = { };

  # Linux-specific ZSH initialization
  programs.zsh.initContent = ''
    # Load worktree manager
    ${worktreeManager}

    # nixswitch function - auto-detects architecture and config type
    nixswitch() {
      ARCH=$(uname -m)
      # Detect if desktop (check for Hyprland) or minimal
      if command -v hyprctl &>/dev/null; then
        CONFIG="desktop"
      else
        CONFIG="minimal"
      fi

      case $ARCH in
        x86_64)
          home-manager switch --flake ~/.config/nix#''${CONFIG}-x86
          ;;
        aarch64|arm64)
          home-manager switch --flake ~/.config/nix#''${CONFIG}-arm
          ;;
        *)
          echo "❌ Unsupported architecture: $ARCH"
          return 1
          ;;
      esac
    }
  '';

  # Additional Linux packages for development environments
  home.packages = with pkgs; [
    # System monitoring and utilities
    htop
    neofetch
    curl
    wget

    # Development tools
    docker-compose
  ];

  # Disable fish if it causes issues (like in the original vagrant config)
  programs.fish.enable = false;

  # SSH configuration for 1Password
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      identityAgent = "~/.1password/agent.sock";
    };
  };
}
