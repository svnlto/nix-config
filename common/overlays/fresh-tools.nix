# Tools I want newer than the stable channel provides.
#
# Each name below is taken from the `nixpkgs-unstable` flake input instead of
# the pinned stable nixpkgs. The version is whatever that input is locked to,
# so it only moves when you say so:
#
#   nix flake update nixpkgs-unstable && nixswitch   # advance all fresh tools
#   nix flake metadata | grep nixpkgs-unstable       # see the current pin
#
# Add a tool by appending its package attribute name to `freshTools`.
{ inputs }:
_final: prev:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  freshTools = [
    "devbox"
  ];
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = unstable.${name};
  }) freshTools
)
