{ config, pkgs, lib, username, ... }:

{
  home.activation.setupBinDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Create user scripts directory with proper permissions
    mkdir -p $HOME/.bin
    chmod 700 $HOME/.bin

    # fetch user scripts and then create alias for each script in the directory
    # This assumes the scripts are executable and located in $HOME/.bin
    for script in $HOME/.bin/*; do
      if [ -x "$script" ]; then
        # Create an alias for each script
        echo "alias $(basename "$script" .sh)=\"$script\"" >> $HOME/.bin_aliases
      fi
    done
  '';

  # Configure ZSH aliases for user scripts
  programs.zsh.shellAliases = {
    "fusg" =
      "fetch-user-script-gists"; # Short alias for fetch-user-script-gists
  };
}
