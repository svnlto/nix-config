{ config, pkgs, lib, username, ... }:

{
  # Install AWS CLI and related tools
  home.packages = with pkgs; [ awscli2 aws-sso-cli ];

  # AWS configuration
  home.file.".aws/config".text = ''
    # Default SSO configuration
    [default]
    sso_session = default-sso
    sso_account_id = 123456789012  # Replace with your primary AWS account ID
    sso_role_name = ReadOnly       # Default role to assume
    region = us-east-1
    output = json

    # SSO session configuration
    [sso-session default-sso]
    sso_start_url = https://your-sso-portal.awsapps.com/start   # Replace with your SSO portal URL
    sso_region = us-east-1
    sso_registration_scopes = sso:account:access

    # Development account profile 
    [profile dev]
    sso_session = default-sso
    sso_account_id = 123456789012  # Replace with your dev account ID
    sso_role_name = Developer
    region = us-east-1
    output = json

    # Production account profile
    [profile prod]
    sso_session = default-sso
    sso_account_id = 987654321098  # Replace with your prod account ID
    sso_role_name = ReadOnly
    region = us-east-1
    output = json

    # Staging account profile
    [profile staging]
    sso_session = default-sso
    sso_account_id = 456789012345  # Replace with your staging account ID
    sso_role_name = Developer
    region = us-east-1
    output = json
  '';
}
