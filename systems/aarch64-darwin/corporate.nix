# Corporate Mac overrides
#
# 1. Determinate Nix — disable nix-darwin's Nix management (conflicts with
#    Determinate's own daemon).
# 2. Zscaler SSL inspection — corporate VPN replaces TLS certs with a Zscaler
#    CA not in Node's default trust store.  NODE_EXTRA_CA_CERTS fixes this.
# 3. AWS SSO — CyberArk SCA (grant-cli) + IAM Identity Center (granted/assume).
#
# Refresh the cert after rotation:
#   refresh-zscaler
{ lib, ... }:

let
  aws = {
    region = "eu-central-1";
    sso = {
      sessionName = "msg-test";
      startUrl = "https://d-99676ad5b7.awsapps.com/start";
      region = "eu-central-1";
      registrationScopes = "sso:account:access";
    };
  };
in {
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
    ({ pkgs, lib, ... }:
      let
        seedConfig = pkgs.writeText "aws-config-seed" ''
          [default]
          region = ${aws.region}
          output = json

          [sso-session ${aws.sso.sessionName}]
          sso_start_url = ${aws.sso.startUrl}
          sso_region = ${aws.sso.region}
          sso_registration_scopes = ${aws.sso.registrationScopes}
          region = ${aws.sso.region}
          output = json
        '';
      in {
        home = {
          sessionVariables = {
            NODE_EXTRA_CA_CERTS = "$HOME/.zscaler.pem";
            AWS_CA_BUNDLE = "/etc/ssl/cert.pem";
          };

          packages = with pkgs; [ awscli2 devbox granted jq ];

          activation = {
            # Seed ~/.aws/config with SSO defaults on first run.
            # User owns the file after that — edits are preserved.
            awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p "$HOME/.aws"
              if [ ! -f "$HOME/.aws/config" ]; then
                cp ${seedConfig} "$HOME/.aws/config"
                chmod 644 "$HOME/.aws/config"
              fi
            '';

            # Install grant-cli (CyberArk SCA CLI) — not in nixpkgs
            installGrantCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              GRANT_VERSION="0.6.1"
              GRANT_BIN="$HOME/.local/bin/grant"
              if [ ! -x "$GRANT_BIN" ] || ! "$GRANT_BIN" version 2>/dev/null | grep -q "$GRANT_VERSION"; then
                mkdir -p "$HOME/.local/bin"
                ARCH=$(/usr/bin/uname -m)
                case "$ARCH" in
                  arm64|aarch64) ARCH="arm64" ;;
                  x86_64) ARCH="amd64" ;;
                esac
                URL="https://github.com/aaearon/grant-cli/releases/download/v$GRANT_VERSION/grant-cli_''${GRANT_VERSION}_darwin_''${ARCH}.tar.gz"
                echo "Installing grant-cli v$GRANT_VERSION..."
                /usr/bin/curl -skL "$URL" | /usr/bin/tar xz -C "$HOME/.local/bin" grant
                chmod +x "$GRANT_BIN"
              fi
            '';
          };
        };

        programs.zsh = {
          shellAliases = {
            refresh-zscaler = ''
              curl -s http://cloud.msg.team/zertifikat/zscaler.crt -o /tmp/zscaler.crt \
              && openssl x509 -inform DER -in /tmp/zscaler.crt -out ~/.zscaler.pem 2>/dev/null \
              || cp /tmp/zscaler.crt ~/.zscaler.pem \
              && echo "Zscaler cert refreshed ✓"'';
            awswho = "aws sts get-caller-identity";
            assume = "source assume";
          };

          initContent = ''
            # Populate ~/.aws/config with SSO profiles from CyberArk-provisioned accounts
            aws-sync-profiles() {
              command -v grant &>/dev/null || { echo "grant-cli not found. Run 'nixswitch' to install." >&2; return 1; }
              grant status &>/dev/null || { echo "Not logged in to CyberArk. Run 'grant login' first." >&2; return 1; }

              local config="$HOME/.aws/config" added=0 profile
              local entries
              entries=$(grant list --provider aws --output json | jq -r '.cloud[] | [.target, .workspaceId, .role] | @tsv')

              while IFS=$'\t' read -r target account_id role; do
                profile=$(echo "$target" | tr '[:upper:]' '[:lower:]' | sed 's/[_() ]/-/g; s/--*/-/g; s/^-//; s/-$//')
                grep -q "^\[profile $profile\]" "$config" 2>/dev/null && continue
                printf '\n[profile %s]\nsso_session = ${aws.sso.sessionName}\nsso_account_id = %s\nsso_role_name = %s\nregion = ${aws.region}\n' \
                  "$profile" "$account_id" "$role" >> "$config"
                (( added++ ))
              done <<< "$entries"

              echo "$added profile(s) added."
            }
          '';
        };
      })
  ];
}
