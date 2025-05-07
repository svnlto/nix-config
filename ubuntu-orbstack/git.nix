# Ubuntu-specific Git configuration
{ config, lib, pkgs, username, gitShared ? { }, ... }:

let
  # Template for local Git configuration with private information
  localGitConfigTemplate = ''
    # Local Git configuration - NOT tracked in Git
    # This file contains your personal Git configuration, including email

    [user]
        name = Your Name
        email = your.email@example.com
  '';

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
  # Apply the shared git configuration for Ubuntu (home-manager)
  programs.git = gitShared.gitConfig or { };

  # Create .gitignore file
  home.file.".gitignore".text = sharedGitignore;

  # Create template for local Git configuration (but don't overwrite if exists)
  home.activation.createGitLocalConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ ! -f ~/.gitconfig.local ]; then
              echo "Creating template for local git configuration..."
              cat > ~/.gitconfig.local << EOF
      ${localGitConfigTemplate}
      EOF
              echo "⚠️  IMPORTANT: Please edit ~/.gitconfig.local to set your email address ⚠️"
            fi
    '';

  # Make sure diff-so-fancy is installed
  home.packages = with pkgs; [ diff-so-fancy ];
}
