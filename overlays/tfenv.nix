final: prev: {
  tfenv = prev.stdenvNoCC.mkDerivation rec {
    pname = "tfenv";
    version = "v3.0.0";

    src = prev.fetchFromGitHub {
      owner = "tfutils";
      repo = "tfenv";
      rev = "v3.0.0";
      sha256 = "0jvs7bk2gaspanb4qpxzd4m2ya5pz3d1izam6k7lw30hyn7mlnnq";
    };

    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [ prev.makeWrapper ];

    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';

    # TFENV_CONFIG_DIR is only set if not already specified.
    # Using '--run export ...' instead of the builtin --set-default, since
    # expanding $HOME fails with --set-default.
    fixupPhase = ''
      wrapProgram $out/bin/tfenv \
      --prefix PATH : "${
        prev.lib.makeBinPath [
          prev.unzip
          prev.curl
        ]
      }" \
      --run 'export TFENV_CONFIG_DIR="''${TFENV_CONFIG_DIR:-$HOME/.tfenv}"' \
      --run 'mkdir -p $TFENV_CONFIG_DIR'

      wrapProgram $out/bin/terraform \
      --run 'export TFENV_CONFIG_DIR="''${TFENV_CONFIG_DIR:-$HOME/.tfenv}"' \
      --run 'mkdir -p $TFENV_CONFIG_DIR'
    '';

    meta = with prev.lib; {
      description = "Terraform version manager";
      homepage = "https://github.com/tfutils/tfenv";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };
}
