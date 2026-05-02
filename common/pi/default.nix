{ config, ... }:
let home = config.home.homeDirectory;
in {
  home.file = {
    # Top-level settings (theme selection etc.) — writable symlink
    ".pi/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${home}/.config/nix/common/pi/settings.json";

    # Agent settings (permissions etc.) — writable symlink
    ".pi/agent/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${home}/.config/nix/common/pi/agent-settings.json";

    # Custom model entries (input modalities, routing etc.) — writable symlink
    ".pi/agent/models.json".source = config.lib.file.mkOutOfStoreSymlink
      "${home}/.config/nix/common/pi/models.json";

    # Extensions (store symlink — edit in repo, reload with /reload)
    ".pi/agent/extensions".source = ./extensions;

    # Themes
    ".pi/agent/themes".source = ./themes;
  };
}
