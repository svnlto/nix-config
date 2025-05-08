final: prev: {
  tfenv = prev.stdenv.mkDerivation {
    name = "tfenv";
    version = "v3.0.0";

    src = prev.fetchFromGitHub {
      owner = "tfutils";
      repo = "tfenv";
      rev = "v3.0.0";
      sha256 = "0jvs7bk2gaspanb4qpxzd4m2ya5pz3d1izam6k7lw30hyn7mlnnq";
    };

    buildInputs = [ prev.bash ];

    installPhase = ''
      mkdir -p $out/bin $out/share/tfenv
      cp -r * $out/share/tfenv

      cat > $out/bin/tfenv <<EOF
      #!/usr/bin/env bash
      export TFENV_CONFIG_DIR="\$HOME/.tfenv"
      export TFENV_ROOT="$out/share/tfenv"
      export TFENV_DATA_DIR="\$TFENV_CONFIG_DIR"

      # Create user data directory if needed
      mkdir -p "\$TFENV_CONFIG_DIR/versions"

      exec "$out/share/tfenv/bin/tfenv" "\$@"
      EOF
      chmod +x $out/bin/tfenv

      ln -s $out/bin/tfenv $out/bin/terraform
    '';

    meta = with prev.lib; {
      description = "Terraform version manager";
      homepage = "https://github.com/tfutils/tfenv";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = with maintainers; [ ];
    };
  };
}
