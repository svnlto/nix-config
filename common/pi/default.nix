{ config, ... }:
let home = config.home.homeDirectory;
in {
  home.file = {
    # Agent settings (model, theme, packages, permissions, etc.)
    ".pi/agent/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${home}/.config/nix/common/pi/settings.json";

    # Custom model entries (input modalities, routing etc.)
    ".pi/agent/models.json".source = config.lib.file.mkOutOfStoreSymlink
      "${home}/.config/nix/common/pi/models.json";

    # Extensions
    ".pi/agent/extensions".source = ./extensions;

    # Themes
    ".pi/agent/themes".source = ./themes;
  };
}
