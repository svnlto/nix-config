# macOS-specific Git configuration
{ config, lib, pkgs, username, ... }:

{
  # Add Git to system packages
  environment.systemPackages = with pkgs; [ git diff-so-fancy ];

  # This creates a global Git configuration
  environment.etc."gitconfig".text = ''
    [user]
      name = Sven Lito
      email = me@svenlito.com
    [init]
      defaultBranch = main
    [pull]
      rebase = true
    [push]
      autoSetupRemote = true
    [core]
      editor = nvim
      excludesfile = ~/.gitignore
      autocrlf = input
      quotePath = false
      compression = 9
      preloadindex = true
      pager = diff-so-fancy | less --tabs=2 -RFX
    [merge]
      tool = vscode
      conflictstyle = diff3
    [mergetool "vscode"]
      cmd = code --wait $MERGED
    [diff]
      tool = vscode
      colorMoved = default
    [difftool "vscode"]
      cmd = code --wait --diff $LOCAL $REMOTE
    [commit]
      gpgsign = false
    [rerere]
      enabled = true
    [help]
      autocorrect = 10
    [color]
      ui = always
    [color "diff"]
      meta = yellow
      frag = magenta bold
      commit = yellow bold
      old = red bold
      new = green bold
      whitespace = red reverse
    [color "diff-highlight"]
      oldNormal = red bold
      oldHighlight = red bold 52
      newNormal = green bold
      newHighlight = green bold 22
  '';

  # Create common .gitignore file
  environment.etc."gitignore".text = ''
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

  # System activation script to copy gitconfig and gitignore to user's home directory
  system.activationScripts.gitConfig = ''
    echo "Setting up Git configuration..." >&2
    cp ${
      config.environment.etc."gitconfig".source
    } /Users/${username}/.gitconfig
    chown ${username}:staff /Users/${username}/.gitconfig

    cp ${
      config.environment.etc."gitignore".source
    } /Users/${username}/.gitignore
    chown ${username}:staff /Users/${username}/.gitignore
  '';
}
