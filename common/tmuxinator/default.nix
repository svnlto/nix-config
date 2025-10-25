{ ... }:

{
  # Default session with multiple project windows
  xdg.configFile."tmuxinator/default.yml".text = ''
    name: default
    root: ~/

    windows:
      - config:
          root: ~/.config/nix
          layout: 055e,362x77,0,0{247x77,0,0,2,114x77,248,0[114x52,248,0,3,114x24,248,53,4]}
          panes:
            - nvim
            - claude
            - # terminal
      - homelab:
          root: ~/Projects/homelab
          layout: 055e,362x77,0,0{247x77,0,0,2,114x77,248,0[114x52,248,0,3,114x24,248,53,4]}
          panes:
            - nvim
            - claude
            - # terminal
      - kubestronaut:
          root: ~/Projects/kubestronaut
          layout: 055e,362x77,0,0{247x77,0,0,2,114x77,248,0[114x52,248,0,3,114x24,248,53,4]}
          panes:
            - nvim
            - claude
            - # terminal
  '';

  # Pricelytics - separate session with two windows (app + infra)
  xdg.configFile."tmuxinator/pricelytics.yml".text = ''
    name: pricelytics
    root: ~/Projects

    windows:
      - app:
          root: ~/Projects/pricelytics
          layout: 055e,362x77,0,0{247x77,0,0,2,114x77,248,0[114x52,248,0,3,114x24,248,53,4]}
          panes:
            - nvim
            - claude
            - # terminal
      - infra:
          root: ~/Projects/pricelytics-infrastructure
          layout: 055e,362x77,0,0{247x77,0,0,2,114x77,248,0[114x52,248,0,3,114x24,248,53,4]}
          panes:
            - nvim
            - claude
            - # terminal
  '';

  # Add shell aliases for convenience
  programs.zsh.shellAliases = {
    mux = "tmuxinator";
    muxn = "tmuxinator new";
    muxs = "tmuxinator start";
    muxl = "tmuxinator list";
  };
}
