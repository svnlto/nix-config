{ config, pkgs, username, ... }:

{
  # Home Manager packages for server (CLI only)
  home.packages = with pkgs; [
    # Server-appropriate packages
    tmux
    htop
    ripgrep
    fd
    jq
    fzf
    tree
    unzip
    ncdu # disk usage analyzer
    mosh # mobile shell with roaming
    nmap
  ];

  # Program configurations
  programs = {
    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
      };

      # Set up custom zshrc handling
      initExtra = builtins.readFile ./zshrc-custom;
    };

    git = {
      enable = true;
      userName = "Sven Lito";
      userEmail = "your-email@example.com";
    };

    # Configure neovim
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    # Configure tmux
    tmux = {
      enable = true;
      shortcut = "a";
      terminal = "screen-256color";
      escapeTime = 0;
      historyLimit = 50000;
    };
  };

  # SSH configuration - without 1Password integration
  home.file.".ssh/config".text = ''
    Host *
      AddKeysToAgent yes
      Protocol 2
      Compression yes
      ServerAliveInterval 20
      ServerAliveCountMax 10
      TCPKeepAlive yes
      IdentityAgent "~/.ssh/agent.sock"
  '';

  # Required for home-manager
  home.stateVersion = "23.11";
}
