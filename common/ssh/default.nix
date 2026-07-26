{ pkgs, lib, ... }:

{
  # Darwin gets a Nix-managed SSH config file and public keys; Linux uses read-only programs.ssh instead.
  home.file.".ssh/config" = lib.mkIf pkgs.stdenv.isDarwin { source = ./config; };

  # 1Password resolves per-host identities by fingerprint against these
  home.file.".ssh/keys" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ./keys;
    recursive = true;
  };

  # enableDefaultConfig=false: HM injects its own Host * block first, and SSH is
  # first-match-wins, so the defaults would silently override these values.
  programs.ssh = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "yes";
      IdentityAgent = "~/.1password/agent.sock";
      Compression = true;
      ServerAliveInterval = 20;
      ServerAliveCountMax = 10;
      TCPKeepAlive = "yes";
    };
  };

  xdg.configFile."1Password/ssh/agent.toml" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ./agent.toml;
  };
}
