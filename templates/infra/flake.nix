{
  description = "Cloud infrastructure platform engineering";

  nixConfig = {
    extra-substituters = [ "https://nixpkgs-terraform.cachix.org" ];
    extra-trusted-public-keys = [
      "nixpkgs-terraform.cachix.org-1:8Sit092rIdAVENA3ZVeH9hzSiqI/jng6JiCrQ1Dmusw="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
  };

  outputs = { nixpkgs, flake-utils, nixpkgs-terraform, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        terraform = nixpkgs-terraform.packages.${system}."terraform-1.14.1";
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            terraform
            pkgs.tflint
            pkgs.terragrunt
            pkgs.packer
            pkgs.terraform-docs

            pkgs.kubectl
            pkgs.kubernetes-helm
            pkgs.kubeconform
            pkgs.k9s
            pkgs.kustomize
            pkgs.stern
            pkgs.kubectx

            pkgs.trivy
            pkgs.checkov
            # install manually: pip install checkov

            (pkgs.azure-cli.withExtensions
              [ pkgs.azure-cli.extensions.azure-devops ])
            pkgs.kubelogin

            pkgs.jq
            pkgs.yq-go
            pkgs.yamllint
            pkgs.hadolint

            pkgs.nodejs
            pkgs.pre-commit
          ];

          shellHook = ''
            echo "infra platform engineering environment loaded"
          '';
        };
      });
}
