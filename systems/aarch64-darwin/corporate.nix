# Corporate Mac overrides
#
# 1. Determinate Nix — disable nix-darwin's Nix management (conflicts with
#    Determinate's own daemon).
# 2. Zscaler SSL inspection — corporate VPN replaces TLS certs with a Zscaler
#    CA not in Node's default trust store.  NODE_EXTRA_CA_CERTS fixes this.
# 3. AWS / saml2aws — SAML→STS credential exchange via CyberArk IdP.
#
# Refresh the cert after rotation:
#   refresh-zscaler
{ lib, ... }:

{
  # Determinate Nix manages its own daemon; nix-darwin must not compete.
  # Force-disable all nix.* options that common/ and systems/ set unconditionally.
  nix.enable = false;
  nix.optimise.automatic = lib.mkForce false;

  # Jamf blocks sudo on /Applications/ — disable brew operations that trigger it
  # upgrade: sudo rm old app before installing new version
  # cleanup: sudo rm app when removed from config
  # Run `brewup` manually instead
  homebrew.onActivation.upgrade = lib.mkForce false;
  homebrew.onActivation.cleanup = lib.mkForce "none";
  home-manager.sharedModules = [
    ({ pkgs, lib, ... }: {
      home = {
        sessionVariables = {
          NODE_EXTRA_CA_CERTS = "$HOME/.zscaler.pem";
          AWS_CA_BUNDLE = "$HOME/.zscaler.pem";
        };

        packages = with pkgs; [
          saml2aws # SAML → STS credential exchange; must be on PATH for saml2aws-multi
          awscli2 # AWS CLI v2
        ];

        activation.awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    if [ ! -f "$HOME/.aws/config" ]; then
                      mkdir -p "$HOME/.aws"
                      cat > "$HOME/.aws/config" << EOF
          [profile test-landing-zone]
          region = eu-central-1
          output = json

          [profile prod-landing-zone]
          region = eu-central-1
          output = json
          EOF
                    fi
        '';

        activation.saml2awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    if [ ! -f "$HOME/.saml2aws" ]; then
                      cat > "$HOME/.saml2aws" << EOF
          [default]
          url                  = https://msg-dop-test.cyberark.cloud
          username             = sven.hummelsberger@tst.do.msg.group
          provider             = CyberArk
          mfa                  = Auto
          skip_verify          = false
          timeout              = 0
          aws_urn              = urn:amazon:webservices
          aws_session_duration = 3600
          aws_profile          = test-landing-zone
          region               = eu-central-1

          [prod]
          url                  = https://msg-dop.cyberark.cloud
          username             = sven.hummelsberger@do.msg.group
          provider             = CyberArk
          mfa                  = Auto
          skip_verify          = false
          timeout              = 0
          aws_urn              = urn:amazon:webservices
          aws_session_duration = 3600
          aws_profile          = prod-landing-zone
          region               = eu-central-1
          EOF
                    fi
        '';
      };

      programs.zsh.shellAliases = {
        refresh-zscaler = ''
          curl -s http://cloud.msg.team/zertifikat/zscaler.crt -o /tmp/zscaler.crt \
          && openssl x509 -inform DER -in /tmp/zscaler.crt -out ~/.zscaler.pem 2>/dev/null \
          || cp /tmp/zscaler.crt ~/.zscaler.pem \
          && echo "Zscaler cert refreshed ✓"'';
        awswho = "aws sts get-caller-identity";
        awstest = "awslogin -s test";
        awsprod = "saml2aws login --idp-account prod";
      };
    })
  ];
}
