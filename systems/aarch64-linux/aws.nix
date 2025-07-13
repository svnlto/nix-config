{ config, pkgs, lib, username, ... }:

{
  # Install AWS CLI and related tools
  home.packages = with pkgs; [ awscli2 aws-sso-cli ssm-session-manager-plugin ];

  # Explicitly tell home-manager not to manage the AWS config file
  xdg.configFile."aws/config".enable = false;

  home.activation.setupAws = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Create AWS directory with proper permissions
    mkdir -p $HOME/.aws
    chmod 700 $HOME/.aws
  '';

  # Configure ZSH aliases for AWS-related scripts
  programs.zsh.shellAliases = {
    "uaws" = "update-aws-config"; # Short alias for update-aws-config
    "awssso" = "aws sso login"; # Quick login to AWS SSO
    "awswho" = "aws sts get-caller-identity"; # Check current AWS identity
  };
}
