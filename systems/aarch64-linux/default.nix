# Generic aarch64-linux Home Manager configuration
# This configuration can be used for any Linux ARM64 environment (VMs, containers, cloud instances)
{ pkgs, username ? "user", ... }:

let sharedZsh = import ../../common/zsh/shared.nix;
in {
  imports = [
    ../../common/home-manager-base.nix
    ../../common/default.nix
    ../../common/git
  ];

  # Linux-specific home directory
  home.homeDirectory = "/home/${username}";

  # Linux-specific nix settings
  nix = {
    package = pkgs.nix;
    settings.auto-optimise-store =
      true; # Linux can handle this better than macOS
  };

  # Linux-specific session variables (merged with shared config)
  home.sessionVariables = sharedZsh.sessionVariables // {
    EDITOR = "nvim";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
  };

  # Linux-specific ZSH initialization
  programs.zsh.initContent = ''

    # nixswitch function - auto-detects architecture
    nixswitch() {
      ARCH=$(uname -m)

      case $ARCH in
        x86_64)
          home-manager switch --flake ~/.config/nix#minimal-x86
          ;;
        aarch64|arm64)
          home-manager switch --flake ~/.config/nix#minimal-arm
          ;;
        *)
          echo "❌ Unsupported architecture: $ARCH"
          return 1
          ;;
      esac
    }
  '';

  # SSH configuration for 1Password
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = { identityAgent = "~/.1password/agent.sock"; };
  };
}
