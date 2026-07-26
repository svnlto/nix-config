_:

let
  sharedZsh = import ../zsh/shared.nix;
in
{
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global = {
          hide_env_diff = true;
        };
      };
    };

    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        editor = "nvim";
        prompt = "enabled";
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion = sharedZsh.autosuggestionConfig;
      history = sharedZsh.historyConfig;

      # Platform-specific aliases are merged in separately
      shellAliases = sharedZsh.aliases;

      initContent = ''
        ${sharedZsh.tools}
        ${sharedZsh.functions}
        ${sharedZsh.historyOptions}
        ${sharedZsh.options}
        ${sharedZsh.completion}
        ${sharedZsh.keybindings}

        if command -v oh-my-posh &> /dev/null; then
          eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/default.omp.json)"
        fi
      '';
    };
  };
}
