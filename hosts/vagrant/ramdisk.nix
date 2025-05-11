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
  # Use a simpler approach that doesn't depend on sudo
  home.activation.setupRamdiskDirs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Only try to create subdirectories if the ramdisk is already mounted
      # The main /ramdisk mount is handled by the Vagrantfile provisioner
      if [ -d "/ramdisk" ] && [ -w "/ramdisk" ]; then
        echo "RAM disk is mounted and writable"
        
        # Try creating user-specific directories that we should have permission for
        echo "Setting up user cache directories in RAM disk..."
        
        # Create user directories in ramdisk - focus on directories we'll use
        mkdir -p "/ramdisk/.npm" 2>/dev/null || echo "Could not create npm cache dir"
        mkdir -p "/ramdisk/tmp" 2>/dev/null || echo "Could not create tmp dir"
        mkdir -p "/ramdisk/.pnpm/store" 2>/dev/null || echo "Could not create pnpm dirs"
        mkdir -p "/ramdisk/.terraform.d/plugin-cache" 2>/dev/null || echo "Could not create terraform dirs"
        
        # Try to set permissions but don't fail if we can't
        chmod 777 "/ramdisk/tmp" 2>/dev/null || true
      else
        echo "WARNING: /ramdisk is not mounted or not writable"
        echo "RAM disk features will fall back to regular disk"
        # Create fallback directories in home directory
        mkdir -p "$HOME/.cache/npm-ramdisk"
        mkdir -p "$HOME/.cache/pnpm-ramdisk"
        mkdir -p "$HOME/.cache/terraform-ramdisk"
      fi

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
    # Plugin cache on RAM disk for faster operations
    plugin_cache_dir = "/ramdisk/.terraform.d/plugin-cache"

    # Disable version checking to reduce network calls
    disable_checkpoint = true
    disable_checkpoint_signature = true

    # HashiCorp Cloud Platform (HCP) Terraform credentials
    # Replace with your actual token or use environment variables
    credentials "app.terraform.io" {
      token = "TERRAFORM_TOKEN_PLACEHOLDER"
    }

    # Optional: Provider installation optimization
    provider_installation {
      filesystem_mirror {
        path = "/ramdisk/.terraform.d/plugins"
      }
      direct {}
    }
  '';
}
