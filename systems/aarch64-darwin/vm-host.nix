{ pkgs, ... }:

# Host-side VM tooling for rick (NOT the morty guest). Imported only in rick's
# extraModules so it never lands inside the VM. tart + packer come from nixpkgs
# (the cirruslabs brew tart formula is broken on current Homebrew; packer is
# BUSL/unfree, allowed via the flake). tart runs the VMs; packer builds the
# morty-work golden image (systems/aarch64-darwin/vm/morty.pkr.hcl).
{
  environment.systemPackages = [
    pkgs.tart
    pkgs.packer
  ];
}
