# Ubuntu-specific Git configuration
{ config, lib, pkgs, username, ... }:

let
  # Complete Git configuration for Ubuntu
  gitConfig = {
    enable = true;

    # User details - Using actual name that can be overridden by local config
    userName = "Sven Lito";
    userEmail = "svenlito@gmail.com";

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
      commit = {
        gpgsign = false; # Set to true if you use GPG signing
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

    # No Git aliases here - using Oh My Zsh git plugin aliases instead
    aliases = { };

    # Include local Git configuration file for private settings
    includes = [{ path = "~/.gitconfig.local"; }];
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

    # Dependency lock files
    package-lock.json
    yarn.lock
    pnpm-lock.yaml

    # Nix
    result
    result-*
  '';
in {
  # Apply the git configuration for Ubuntu (home-manager)
  programs.git = gitConfig;

  # Create .gitignore file
  home.file.".gitignore".text = sharedGitignore;
}
