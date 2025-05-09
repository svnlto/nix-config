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
  # Use a more aggressive approach with sudo to ensure permission issues don't block us
  home.activation.setupRamdiskDirs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Function to run commands with sudo if normal command fails
      run_with_fallback() {
        if ! $@; then
          echo "Command failed, retrying with sudo: $@"
          sudo $@
        fi
      }

      # Check if ramdisk exists, and if not try to create it
      if [ ! -d "/ramdisk" ]; then
        echo "Creating /ramdisk directory..."
        run_with_fallback mkdir -p /ramdisk
      fi

      # Check if ramdisk is mounted, if not try to mount it
      if ! mount | grep -q "/ramdisk"; then
        echo "Mounting RAM disk..."
        run_with_fallback sudo mount -t tmpfs -o size=2G,mode=1777 none /ramdisk
      fi

      echo "Setting up RAM disk directories and permissions..."

      # Create all required directories
      for dir in "/ramdisk/tmp" "/ramdisk/.npm" "/ramdisk/.pnpm" "/ramdisk/.pnpm/store" "/ramdisk/.terraform.d" "/ramdisk/.terraform.d/plugin-cache"; do
        if [ ! -d "$dir" ]; then
          echo "Creating directory: $dir"
          run_with_fallback mkdir -p "$dir"
        fi
      done

      # Set permissions
      run_with_fallback chmod 1777 /ramdisk/tmp
      run_with_fallback chmod -R 755 /ramdisk/.npm /ramdisk/.terraform.d /ramdisk/.pnpm

      # Ensure current user owns the directories
      run_with_fallback sudo chown -R $USER:$USER /ramdisk

      echo "RAM disk setup complete"
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
