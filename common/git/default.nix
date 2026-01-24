# Unified cross-platform Git configuration
{ pkgs, lib, ... }:

let
  inherit (pkgs.stdenv) isLinux isDarwin;
  signingKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYK1c6kxYT6FzMEqckP04e2unQgTvFPyNEFzT/q/eXR";
in {
  programs.git = {
    enable = true;

    userName = "Sven Lito";
    userEmail = "me@svenlito.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;

      core = {
        editor = "nvim";
        excludesfile = "~/.gitignore";
        autocrlf = "input";
        quotepath = false;
        compression = 9;
        preloadindex = true;
        pager = "diff-so-fancy | less --tabs=2 -RFX";
      };

      merge = { conflictstyle = "diff3"; };

      diff = { colorMoved = "default"; };

      rerere.enabled = true;
      help.autocorrect = 10;

      color = {
        ui = "always";
        diff = {
          meta = "yellow";
          frag = "magenta bold";
          commit = "yellow bold";
          old = "red bold";
          new = "green bold";
          whitespace = "red reverse";
        };
        "diff-highlight" = {
          oldNormal = "red bold";
          oldHighlight = "red bold 52";
          newNormal = "green bold";
          newHighlight = "green bold 22";
        };
      };
      # SSH signing with 1Password (cross-platform)
      user.signingkey = signingKey;
      gpg.format = "ssh";
      commit.gpgsign = true;
    } // lib.optionalAttrs isLinux {
      # Linux-specific: 1Password SSH signing
      # NOTE: Assumes 1Password installed in standard location (/opt/1Password)
      # If using custom install path, override this in your platform-specific config
      gpg.ssh = {
        program = "/opt/1Password/op-ssh-sign";
        allowedSignersFile = "~/.ssh/allowed_signers";
      };
    } // lib.optionalAttrs isDarwin {
      # macOS-specific: 1Password agent uses SSH_AUTH_SOCK environment variable
      # No program path needed - handled by 1Password.app integration
      gpg.ssh = { allowedSignersFile = "~/.ssh/allowed_signers"; };
    };
  };

  # Common .gitignore
  home.file.".gitignore".text = ''
    # OS files
    .DS_Store
    .DS_Store?
    ._*
    .Spotlight-V100
    .Trashes
    ehthumbs.db
    Thumbs.db

    # Editor files
    .vscode/
    .idea/
    *.swp
    *.swo
    *~

    # Environment files
    .env
    .env.local

    # Build artifacts
    node_modules/
    dist/
    build/
    target/

    # Logs
    *.log
    npm-debug.log*

    # Nix
    result
    result-*
  '';

  # SSH allowed_signers file (both platforms)
  home.file.".ssh/allowed_signers".text = "me@svenlito.com ${signingKey}";
}
