rec {
  # Common environment variables
  commonEnvVars = {
    # NPM configuration for global packages
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";

    # Locale settings
    LANG = "en_GB.UTF-8";
    LC_ALL = "en_GB.UTF-8";

    # ZSH history settings
    HISTFILE = "$HOME/.zsh_history";
    HIST_SIZE = "10000";
    HIST_STAMPS = "dd/mm/yyyy";
    SAVEHIST = "10000";
    HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE = "1";
  };

  # Common PATH additions as a list for easy composition
  commonPaths = [
    "$HOME/.npm-global/bin" # NPM global packages
    "$HOME/.bin" # User custom binaries
  ];

  # PATH export string for shell init
  pathExports = ''
    # Add common paths to PATH
    export PATH="${builtins.concatStringsSep ":$PATH:" commonPaths}:$PATH"
  '';

  # Environment variable exports for shell init
  envExports = ''
    # Common environment variables
    ${builtins.concatStringsSep "\n" (builtins.attrValues
      (builtins.mapAttrs (name: value: "export ${name}=${value}")
        commonEnvVars))}
  '';

  # Combined environment setup for shell initialization
  shellEnvironment = ''
    ${envExports}
    ${pathExports}
  '';
}
