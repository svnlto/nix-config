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
#
# SSL_CERT_FILE uses a combined bundle (system CAs + Zscaler) because tools
# like curl treat it as a *replacement* for the default trust store, not an
# addition.  NODE_EXTRA_CA_CERTS is additive, so it only needs the Zscaler cert.
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
          SSL_CERT_FILE = "$HOME/.corporate-ca-bundle.pem";
          CURL_CA_BUNDLE = "$HOME/.corporate-ca-bundle.pem";
          AWS_CA_BUNDLE = "$HOME/.zscaler.pem";
          SAML2AWS_AUTO_BROWSER_DOWNLOAD = "true";
        };

        packages = with pkgs; [
          saml2aws # SAML → STS credential exchange; must be on PATH for saml2aws-multi
          awscli2 # AWS CLI v2
          devbox # Isolated dev environments via Nix
        ];

        activation = {
          awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

          # ~/.saml2aws: only [default] (TEST) — saml2aws-multi reads flat, ignoring sections.
          # PROD config lives in a separate file used by saml2aws --idp-account prod.
          saml2awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                        if [ ! -f "$HOME/.saml2aws" ]; then
                          cat > "$HOME/.saml2aws" << EOF
            [default]
            url                  = https://msg-dop-test.cyberark.cloud
            username             = sven.hummelsberger@tst.do.msg.group
            provider             = Browser
            mfa                  = Auto
            skip_verify          = false
            timeout              = 0
            aws_urn              = urn:amazon:webservices
            aws_session_duration = 3600
            aws_profile          = test-landing-zone
            region               = eu-central-1
            EOF
                        fi
                        if [ ! -f "$HOME/.saml2aws-prod" ]; then
                          cat > "$HOME/.saml2aws-prod" << EOF
            [default]
            url                  = https://msg-dop.cyberark.cloud
            username             = sven.hummelsberger@prd.do.msg.group
            provider             = Browser
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

          # Build combined CA bundle: macOS system roots + Zscaler CA
          # Needed because SSL_CERT_FILE replaces (not appends to) the trust store
          corporateCaBundle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ -f "$HOME/.zscaler.pem" ]; then
              _bundle="$HOME/.corporate-ca-bundle.pem"
              security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > "$_bundle" 2>/dev/null
              security find-certificate -a -p /Library/Keychains/System.keychain >> "$_bundle" 2>/dev/null
              cat "$HOME/.zscaler.pem" >> "$_bundle"
              echo "Corporate CA bundle: $(grep -c 'BEGIN CERTIFICATE' "$_bundle") certificates"
            fi
          '';

          saml2awsMulti = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if ! command -v awslogin >/dev/null 2>&1; then
              echo "Installing saml2aws-multi via pipx..."
              PATH="${pkgs.git}/bin:$PATH" ${pkgs.pipx}/bin/pipx install git+https://github.com/kyhau/saml2aws-multi.git \
                || echo "WARNING: saml2aws-multi install failed — run manually: pipx install git+https://github.com/kyhau/saml2aws-multi.git"
            fi
          '';
        };
      };

      programs.zsh.initContent = ''
        # Auto-detect browser for saml2aws Browser provider
        if [ -z "$SAML2AWS_BROWSER_EXECUTABLE_PATH" ]; then
          for _b in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
                    "/Applications/Arc.app/Contents/MacOS/Arc" \
                    "/Applications/Chromium.app/Contents/MacOS/Chromium"; do
            if [ -x "$_b" ]; then
              export SAML2AWS_BROWSER_EXECUTABLE_PATH="$_b"
              break
            fi
          done
        fi
      '';

      programs.zsh.shellAliases = {
        refresh-zscaler = ''
          curl -s http://cloud.msg.team/zertifikat/zscaler.crt -o /tmp/zscaler.crt \
          && openssl x509 -inform DER -in /tmp/zscaler.crt -out ~/.zscaler.pem 2>/dev/null \
          || cp /tmp/zscaler.crt ~/.zscaler.pem \
          && { security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain; \
               security find-certificate -a -p /Library/Keychains/System.keychain; \
               cat ~/.zscaler.pem; } > ~/.corporate-ca-bundle.pem 2>/dev/null \
          && echo "Zscaler cert + CA bundle refreshed ✓"'';
        awswho = "aws sts get-caller-identity";
        awstest = "awslogin -s test";
        awsprod = "saml2aws login --config=$HOME/.saml2aws-prod";
      };
    })
  ];
}
