{ config, pkgs, lib, username, ... }:

{
  # Install AWS CLI and related tools
  home.packages = with pkgs; [ awscli2 aws-sso-cli ssm-session-manager-plugin ];

  # Ensure custom AWS directory exists with proper permissions
  home.activation.setupAwsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.aws-custom
    chmod 700 $HOME/.aws-custom
  '';

  # Add a wrapper script that sets AWS_CONFIG_FILE before running aws commands
  home.file.".bin/aws-wrapper" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Wrapper for AWS CLI that uses custom config location
      export AWS_CONFIG_FILE="$HOME/.aws-custom/config"
      aws "$@"
    '';
  };

  # Add placeholder AWS config file in our custom location
  home.file.".aws-custom/config".text = ''
    # This is a placeholder AWS config file.
    # To load your actual configuration from your private GitHub Gist, run:
    # $ update-aws-config  (or simply use the alias: uaws)
    #
    # This will fetch your AWS configuration securely using your GitHub CLI.

    # Default fallback configuration
    [default]
    region = eu-west-2
    output = json
  '';

  # Configure ZSH aliases for AWS-related scripts
  programs.zsh.shellAliases = {
    "uaws" = "update-aws-config"; # Short alias for update-aws-config
    "aws" = "aws-wrapper"; # Use our wrapper for AWS commands
    "awssso" = "aws-wrapper sso login"; # Quick login to AWS SSO
    "awswho" =
      "aws-wrapper sts get-caller-identity"; # Check current AWS identity
  };
}
