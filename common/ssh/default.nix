{ pkgs, lib, ... }:

{
  # Darwin gets a Nix-managed SSH config file and public keys; Linux uses read-only programs.ssh instead.
  home.file.".ssh/config" = lib.mkIf pkgs.stdenv.isDarwin { source = ./config; };

  # Public keys for per-host identity matching (1Password resolves via fingerprint)
  home.file.".ssh/keys" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ./keys;
    recursive = true;
  };

  # enableDefaultConfig=false: the HM ssh module now injects a Host * block
  # (Compression no, ServerAliveInterval 0, …) *before* any extraConfig and
  # SSH is first-match-wins, so the defaults would silently override our values.
  # settings.* takes upstream ssh_config(5) directive names verbatim; the
  # camelCase matchBlocks form and its extraOptions escape hatch are deprecated.
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

  # 1Password SSH agent config
  xdg.configFile."1Password/ssh/agent.toml" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ./agent.toml;
  };
}
