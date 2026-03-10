{ pkgs, lib, ... }:

{
  # Darwin: Nix-managed SSH config and public keys
  # Linux: read-only managed config via programs.ssh
  home.file.".ssh/config" =
    lib.mkIf pkgs.stdenv.isDarwin { source = ./config; };

  # Public keys for per-host identity matching (1Password resolves via fingerprint)
  home.file.".ssh/keys" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ./keys;
    recursive = true;
  };

  programs.ssh = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    extraConfig = ''
      AddKeysToAgent yes
      IdentityAgent ~/.1password/agent.sock
      Compression yes
      ServerAliveInterval 20
      ServerAliveCountMax 10
      TCPKeepAlive yes
    '';
  };

  # 1Password SSH agent config
  xdg.configFile."1Password/ssh/agent.toml" =
    lib.mkIf pkgs.stdenv.isDarwin { source = ./agent.toml; };
}
