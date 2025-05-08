final: prev: {
  tfenv = prev.stdenv.mkDerivation {
    pname = "tfenv";
    version = "v3.0.0";

    src = prev.fetchFromGitHub {
      owner = "tfutils";
      repo = "tfenv";
      rev = "v3.0.0";
      sha256 = "0jvs7bk2gaspanb4qpxzd4m2ya5pz3d1izam6k7lw30hyn7mlnnq";
    };

    buildInputs = with prev; [ bash ];

    nativeBuildInputs = with prev; [ makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin $out/share/tfenv
      cp -r * $out/share/tfenv

      makeWrapper $out/share/tfenv/bin/tfenv $out/bin/tfenv \
        --set TFENV_CONFIG_DIR "$HOME/.tfenv" \
        --set TFENV_ROOT "$out/share/tfenv" \
        --set TFENV_DATA_DIR "$HOME/.tfenv" \
        --prefix PATH : ${prev.lib.makeBinPath (with prev; [ curl unzip ])}

      # Do not symlink terraform -> tfenv
    '';

    meta = with prev.lib; {
      description = "Terraform version manager";
      homepage = "https://github.com/tfutils/tfenv";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = [ ];
    };
  };
}
