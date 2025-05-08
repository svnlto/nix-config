final: prev: {
  tfenv = prev.stdenv.mkDerivation {
    name = "tfenv";
    version = "v3.0.0"; # You can update this version as needed

    src = prev.fetchFromGitHub {
      owner = "tfutils";
      repo = "tfenv";
      rev = "v3.0.0"; # Match this with the version above
      sha256 = "0jvs7bk2gaspanb4qpxzd4m2ya5pz3d1izam6k7lw30hyn7mlnnq";
    };

    buildInputs = [ prev.bash ];

    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/
      # Don't create symbolic links, rely on PATH to find the binaries
      # Make sure bin scripts are executable
      chmod +x $out/bin/*
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
