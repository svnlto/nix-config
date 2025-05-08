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

      # Create additional utility commands for tfenv but keep terraform separate
      cat > $out/bin/tf <<EOF
      #!/usr/bin/env bash
      export TFENV_CONFIG_DIR="\$HOME/.tfenv"
      export TFENV_ROOT="$out/share/tfenv"
      export TFENV_DATA_DIR="\$TFENV_CONFIG_DIR"

      # Create user data directory if needed
      mkdir -p "\$TFENV_CONFIG_DIR/versions"

      # Find the active terraform version
      if [ -f "\$TFENV_CONFIG_DIR/version" ]; then
        VERSION=\$(cat "\$TFENV_CONFIG_DIR/version")
        TERRAFORM="\$TFENV_CONFIG_DIR/versions/\$VERSION/terraform"
        if [ -x "\$TERRAFORM" ]; then
          exec "\$TERRAFORM" "\$@"
        fi
      fi

      # Fallback to system terraform if tfenv version not found
      if command -v /run/current-system/sw/bin/terraform &>/dev/null; then
        exec /run/current-system/sw/bin/terraform "\$@"
      elif command -v ${prev.terraform}/bin/terraform &>/dev/null; then
        exec ${prev.terraform}/bin/terraform "\$@"
      else
        echo "No terraform installation found. Please run 'tfenv install' first." >&2
        exit 1
      fi
      EOF
      chmod +x $out/bin/tf

      # Don't override the system terraform command anymore
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
