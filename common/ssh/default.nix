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
  # Declaring matchBlocks."*" directly is the current idiom.
  programs.ssh = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      identityAgent = "~/.1password/agent.sock";
      compression = true;
      serverAliveInterval = 20;
      serverAliveCountMax = 10;
      extraOptions.TCPKeepAlive = "yes";
    };
  };

  # 1Password SSH agent config
  xdg.configFile."1Password/ssh/agent.toml" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ./agent.toml;
  };
}
