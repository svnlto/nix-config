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
      # Check if ramdisk is mounted and accessible
      if [ -d "/ramdisk" ]; then
        echo "RAM disk is available at /ramdisk"
        
        # Verify we can write to it - first try without sudo
        if touch /ramdisk/.test-write-access 2>/dev/null; then
          echo "RAM disk is writable"
          rm -f /ramdisk/.test-write-access
          
          # Ensure subdirectories exist and have correct permissions
          # but don't fail if they already exist with correct permissions
          for dir in "/ramdisk/tmp" "/ramdisk/.npm" "/ramdisk/.pnpm/store" "/ramdisk/.terraform.d/plugin-cache"; do
            if [ ! -d "$dir" ]; then
              echo "Creating directory: $dir"
              mkdir -p "$dir" || echo "Warning: Could not create $dir"
            fi
          done
        else
          echo "WARNING: Cannot write to /ramdisk - RAM disk features may not work correctly"
          echo "System service may not have run yet or permissions are incorrect"
        fi
      else
        echo "WARNING: /ramdisk directory does not exist. RAM disk features will not work."
      fi
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
