final: prev: {
  nvm = prev.stdenv.mkDerivation {
    name = "nvm";
    version = "v0.39.7";

    src = prev.fetchFromGitHub {
      owner = "nvm-sh";
      repo = "nvm";
      rev = "v0.39.7";
      sha256 = "wtLDyLTF3eOae2htEjfFtx/54Vudsvdq65Zp/IsYTX8=";
    };

    buildInputs = with prev; [ bash ];
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin $out/share/nvm
      cp -R * $out/share/nvm

      # Create wrapper that sets up NVM_DIR in user's home
      cat > $out/bin/nvm <<EOF
      #!/usr/bin/env bash

      export NVM_DIR="\$HOME/.nvm"
      mkdir -p "\$NVM_DIR"

      source "$out/share/nvm/nvm.sh" --no-use

      nvm "\$@"
      EOF
      chmod +x $out/bin/nvm
    '';

    meta = with prev.lib; {
      description = "Node Version Manager";
      homepage = "https://github.com/nvm-sh/nvm";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = with maintainers; [ ];
    };
  };
}
