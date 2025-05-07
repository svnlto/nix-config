# macOS-specific Git configuration
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
  # Apply the shared git configuration for macOS (nix-darwin)
  programs.git = gitShared.gitConfig or { };

  # Create .gitignore file
  system.activationScripts.gitignore = {
    text = ''
      echo "Setting up .gitignore..."
      echo '${sharedGitignore}' > /Users/${username}/.gitignore
      chown ${username}: /Users/${username}/.gitignore
    '';
  };

  # Create local git config template
  system.activationScripts.gitLocalConfig = {
    text = ''
            echo "Checking local git configuration..."
            if [ ! -f /Users/${username}/.gitconfig.local ]; then
              echo "Creating template for local git configuration..."
              cat > /Users/${username}/.gitconfig.local << EOF
      ${localGitConfigTemplate}
      EOF
              echo "⚠️  IMPORTANT: Please edit ~/.gitconfig.local to set your email address ⚠️"
            fi
            chown ${username}: /Users/${username}/.gitconfig.local 2>/dev/null || true
    '';
  };

  # Install diff-so-fancy
  environment.systemPackages = with pkgs; [ diff-so-fancy ];
}
