_:

# morty (Zscaler VM) tooling is NOT homebrew:
#   Zscaler ZCC -> runtime installer (common/profiles/zscaler.nix)
#   Avira Free  -> manual install, first-run (Phase 5)
#   tailscale   -> nixpkgs (systems/aarch64-darwin/vm/proxy.nix)
# Intentionally empty; morty inherits only common.nix (font-sf-pro + dockutil).
{
  homebrew.casks = [ ];
}
