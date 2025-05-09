{ config, pkgs, lib, username, ... }:

{
  # Configure development tools to use RAM disk for temporary files
  home.sessionVariables = {
    # NPM configuration
    npm_config_cache = "/ramdisk/.npm";

    # PNPM configuration
    PNPM_HOME = "/ramdisk/.pnpm";

    # Node.js and NPM tmp directory
    TMPDIR = "/ramdisk/tmp";

    # Terraform plugin cache
    TF_PLUGIN_CACHE_DIR = "/ramdisk/.terraform.d/plugin-cache";
  };

  # Create directories for npm, pnpm and Terraform caches on the RAM disk
  home.activation.setupRamdiskDirs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Create tmp directory in ramdisk
      mkdir -p /ramdisk/tmp
      chmod 1777 /ramdisk/tmp

      # NPM cache
      mkdir -p /ramdisk/.npm
      chmod 755 /ramdisk/.npm

      # PNPM cache and store
      mkdir -p /ramdisk/.pnpm/store
      chmod -R 755 /ramdisk/.pnpm

      # Terraform plugin cache
      mkdir -p /ramdisk/.terraform.d/plugin-cache
      chmod -R 755 /ramdisk/.terraform.d

      # Set ownership of all directories
      chown -R ${username}:${username} /ramdisk || true
    '';

  # NPM specific configuration
  home.file.".npmrc".text = ''
    cache=/ramdisk/.npm
    tmp=/ramdisk/tmp
    registry=https://registry.npmjs.org/
  '';

  # PNPM specific configuration
  home.file.".pnpmrc".text = ''
    store-dir=/ramdisk/.pnpm/store
    state-dir=/ramdisk/.pnpm
    cache-dir=/ramdisk/.pnpm/cache
  '';

  # Terraform CLI configuration
  home.file.".terraformrc".text = ''
    plugin_cache_dir = "/ramdisk/.terraform.d/plugin-cache"
    disable_checkpoint = true
  '';
}
