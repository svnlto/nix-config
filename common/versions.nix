# Centralized version management for consistent state versions
{
  # Home Manager state version - update when upgrading Home Manager
  # This should remain at the version you originally installed
  homeManagerStateVersion = "24.05";

  # nix-darwin system state version
  darwinStateVersion = 5;

  # Nixpkgs state version (when applicable)
  nixpkgsStateVersion = "24.05";
}
