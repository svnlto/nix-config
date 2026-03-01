{
  description = "Kubernetes manifests, Helm charts, and cluster ops";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            kubectl
            kubernetes-helm
            kubeconform
            k9s
            talosctl
            argocd
            cilium-cli
            yq-go
            yamllint
            hadolint
            nodejs
            pre-commit
          ];

          shellHook = ''
            echo "kubernetes dev environment loaded"
          '';
        };
      });
}
