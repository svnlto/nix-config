final: prev: {
  nvm = prev.stdenv.mkDerivation {
    name = "nvm";
    version = "v0.39.7"; # You can update this version as needed

    src = prev.fetchFromGitHub {
      owner = "nvm-sh";
      repo = "nvm";
      rev = "v0.39.7"; # Match this with the version above
      sha256 = "0000000000000000000000000000000000000000000000000000"; # Will be updated by vagrant provisioning
    };

    buildInputs = with prev; [ bash ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/nvm
      cp -R * $out/share/nvm
      
      mkdir -p $out/bin
      cat > $out/bin/nvm <<EOF
      #!/usr/bin/env bash
      source $out/share/nvm/nvm.sh
      nvm "\$@"
      EOF
      chmod +x $out/bin/nvm
    '';

    meta = with prev.lib; {
      description = "Node Version Manager - Simple bash script to manage multiple active node.js versions";
      homepage = "https://github.com/nvm-sh/nvm";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = with maintainers; [ ];
    };
  };
}