{ config, pkgs, username, ... }:

{
  imports = [ ./zsh.nix ./git.nix ];

  # Home Manager packages for server (CLI only)
  home.packages = with pkgs; [
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
    awscli2
    docker
    docker-compose
    # nvm
    # tfenv
    pre-commit
  ];

  # Program configurations
  programs = {
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
