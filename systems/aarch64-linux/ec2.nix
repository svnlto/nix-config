{ config, pkgs, username, ... }:

{
  imports = [
    ../../common/home-packages.nix
    ../../common/claude-code
    ./zsh.nix
    ./git.nix
    ./aws.nix
    ./user-scripts.nix
    ./github.nix
  ];
  # EC2-specific configuration
  # This will override or extend the base vagrant configuration

  # Additional packages specific to EC2 environment
  home.packages = with pkgs; [ awscli2 amazon-ecr-credential-helper ];

  # EC2-specific Git configuration
  programs.git.extraConfig = {
    credential.helper = "!aws --profile dev codecommit credential-helper $@";
    credential.UseHttpPath = true;
  };
}
