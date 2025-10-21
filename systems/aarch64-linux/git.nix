# Ubuntu-specific Git configuration
{ config, lib, pkgs, username, ... }:

let
  # Complete Git configuration for Ubuntu
  gitConfig = {
    enable = true;

    userName = "Sven Lito";
    userEmail = "me@svenlito.com";

    # Git configuration
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
      merge = {
        tool = "vscode";
        conflictstyle = "diff3";
      };
      mergetool.vscode = { cmd = "code --wait $MERGED"; };
      diff = {
        tool = "vscode";
        colorMoved = "default";
      };
      difftool.vscode = { cmd = "code --wait --diff $LOCAL $REMOTE"; };
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYK1c6kxYT6FzMEqckP04e2unQgTvFPyNEFzT/q/eXR";
      gpg = {
        format = "ssh";
        ssh = {
          program = "/opt/1Password/op-ssh-sign";
          allowedSignersFile = "~/.ssh/allowed_signers";
        };
      };
      commit = {
        gpgsign = true;
      };
      rerere = { enabled = true; };
      help = { autocorrect = 10; };
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
    };

    aliases = { };
  };

  # Common .gitignore content
  sharedGitignore = ''
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
in {
  # Apply the git configuration for Ubuntu (home-manager)
  programs.git = gitConfig;

  # Create .gitignore file
  home.file.".gitignore".text = sharedGitignore;

  # Create allowed_signers file for SSH commit verification
  home.file.".ssh/allowed_signers".text = ''
    me@svenlito.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYK1c6kxYT6FzMEqckP04e2unQgTvFPyNEFzT/q/eXR
  '';

  home.activation.linkGitConfig =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      ln -sf ${config.home.homeDirectory}/.config/git/config /home/${username}/.gitconfig
    '';
}
