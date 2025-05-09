{ config, pkgs, lib, username, ... }:

{
  # Install AWS CLI and related tools
  home.packages = with pkgs; [ awscli2 aws-sso-cli ssm-session-manager-plugin ];

  # Ensure .aws directory exists with proper permissions
  home.activation.setupAwsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.aws
    chmod 700 $HOME/.aws
  '';

  # Add placeholder AWS config file
  home.file.".aws/config".text = ''
    # This is a placeholder AWS config file.
    # To load your actual configuration from your private GitHub Gist, run:
    # $ update-aws-config  (or simply use the alias: uaws)
    #
    # This will fetch your AWS configuration securely using your authenticated GitHub CLI.

    # Default fallback configuration
    [default]
    region = eu-west-2
    output = json
  '';

  # Configure ZSH aliases for AWS-related scripts
  programs.zsh.shellAliases = {
    "uaws" = "update-aws-config"; # Short alias for update-aws-config
    "awssso" = "aws sso login"; # Quick login to AWS SSO
    "awswho" = "aws sts get-caller-identity"; # Check current AWS identity
  };
}
