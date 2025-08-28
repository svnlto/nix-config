# Base Home Manager configuration shared across all platforms
{ nixpkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nix configuration with experimental features
  nix = {
    package = nixpkgs.legacyPackages.aarch64-linux.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];

      # Additional performance settings
      auto-optimise-store = false; # Let nix-darwin handle this
      use-case-hack = true;
      fallback = true;
    };
  };
}
