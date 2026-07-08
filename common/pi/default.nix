{ config, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.file = {
    # Agent settings (model, theme, packages, permissions, etc.)
    ".pi/agent/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${home}/.config/nix/common/pi/settings.json";

    # Custom model entries (input modalities, routing etc.)
    ".pi/agent/models.json".source =
      config.lib.file.mkOutOfStoreSymlink "${home}/.config/nix/common/pi/models.json";

    # Extensions (writable so Pi can cache compiled extensions)
    ".pi/agent/extensions".source =
      config.lib.file.mkOutOfStoreSymlink "${home}/.config/nix/common/pi/extensions";

    # Themes (writable for cached theme data)
    ".pi/agent/themes".source =
      config.lib.file.mkOutOfStoreSymlink "${home}/.config/nix/common/pi/themes";
  };
}
