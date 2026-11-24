# Tools taken from the `nixpkgs-unstable` input instead of the pinned stable
# nixpkgs. Advance them with `nix flake update nixpkgs-unstable`.
{ inputs }:
_final: prev:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  freshTools = [
    "devbox"
    "glab"
    "spec-kit"
  ];
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = unstable.${name};
  }) freshTools
)
