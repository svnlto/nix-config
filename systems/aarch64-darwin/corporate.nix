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
          AWS_CA_BUNDLE = "$HOME/.corporate-ca-bundle.pem";
        };

        packages = with pkgs; [
          awscli2 # AWS CLI v2
          devbox # Isolated dev environments via Nix
        ];

        activation = {
          # ~/.aws/config is managed manually — profiles added as accounts
          # are provisioned through CyberArk SCA portal
          awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/.aws"
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

        };
      };

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
        awsp = ''source "$(brew --prefix awsp)/_source-awsp.sh"'';
      };
    })
  ];
}
