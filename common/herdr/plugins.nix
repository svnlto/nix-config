{ pkgs, inputs, ... }:

let
  # Rust binaries. Built here so no cargo toolchain is needed in the profile.
  # herdr-plugin.toml points at ./target/release/<bin> relative to the plugin
  # root, so the linked tree has to keep the cargo layout.
  buildRustPlugin =
    {
      pname,
      src,
      bin,
    }:
    pkgs.rustPlatform.buildRustPackage {
      inherit pname src;
      version = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).package.version;
      cargoLock.lockFile = "${src}/Cargo.lock";

      postInstall = ''
        install -Dm444 ${src}/herdr-plugin.toml $out/herdr-plugin.toml
        mkdir -p $out/target/release
        ln -s $out/bin/${bin} $out/target/release/${bin}
      '';
    };
in
{
  # Stable paths: herdr records these in its own plugins.json on `plugin link`,
  # so the registration survives every store-path change on rebuild.
  xdg.configFile = {
    "herdr/plugins/jj-workspace".source = buildRustPlugin {
      pname = "herdr-plugin-jj-workspace";
      src = inputs.herdr-plugin-jj-workspace;
      bin = "jj-workspace";
    };
    "herdr/plugins/muster".source = buildRustPlugin {
      pname = "herdr-muster";
      src = inputs.herdr-plugin-muster;
      bin = "herdr-muster";
    };
    # Pure bash + jq, no build step — the input tree is already the plugin root.
    "herdr/plugins/jj-status".source = inputs.herdr-plugin-jj-status;
  };
}
