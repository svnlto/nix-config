{
  description = "Terraform/Terragrunt IaC development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # terraform BSL 1.1
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            terraform
            tflint
            terragrunt
            # checkov — broken in nixpkgs-unstable (pycep-parser uv_build + psycopg)
            # install manually: pip install checkov
            nodejs
            pre-commit
          ];

          shellHook = ''
            echo "terraform dev environment loaded"
          '';
        };
      });
}
