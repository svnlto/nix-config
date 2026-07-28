{ pkgs, inputs, ... }:

let
  jj-workspace-src = inputs.herdr-plugin-jj-workspace;

  # Rust binary. Built here so no cargo toolchain is needed in the profile.
  jj-workspace = pkgs.rustPlatform.buildRustPackage {
    pname = "herdr-plugin-jj-workspace";
    version = (builtins.fromTOML (builtins.readFile "${jj-workspace-src}/Cargo.toml")).package.version;
    src = jj-workspace-src;
    cargoLock.lockFile = "${jj-workspace-src}/Cargo.lock";

    # herdr-plugin.toml points at ./target/release/jj-workspace relative to the
    # plugin root, so the linked tree has to keep the cargo layout.
    postInstall = ''
      install -Dm444 ${jj-workspace-src}/herdr-plugin.toml $out/herdr-plugin.toml
      mkdir -p $out/target/release
      ln -s $out/bin/jj-workspace $out/target/release/jj-workspace
    '';
  };
in
{
  # Stable paths: herdr records these in its own plugins.json on `plugin link`,
  # so the registration survives every store-path change on rebuild.
  xdg.configFile = {
    "herdr/plugins/jj-workspace".source = jj-workspace;
    # Pure bash + jq, no build step — the input tree is already the plugin root.
    "herdr/plugins/jj-status".source = inputs.herdr-plugin-jj-status;
  };
}
