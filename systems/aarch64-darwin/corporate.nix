# Corporate Mac overrides
#
# 1. Determinate Nix — disable nix-darwin's Nix management (conflicts with
#    Determinate's own daemon).
# 2. Zscaler SSL inspection — corporate VPN replaces TLS certs with a Zscaler
#    CA not in Node's default trust store.  NODE_EXTRA_CA_CERTS fixes this.
#
# Refresh the cert after rotation:
#   refresh-zscaler
{ lib, ... }:

{
  # Determinate Nix manages its own daemon; nix-darwin must not compete.
  # Force-disable all nix.* options that common/ and systems/ set unconditionally.
  nix.enable = false;
  nix.optimise.automatic = lib.mkForce false;
  home-manager.sharedModules = [{
    home.sessionVariables = { NODE_EXTRA_CA_CERTS = "$HOME/.zscaler.pem"; };

    programs.zsh.shellAliases = {
      refresh-zscaler = ''
        curl -s http://cloud.msg.team/zertifikat/zscaler.crt -o /tmp/zscaler.crt \
        && openssl x509 -inform DER -in /tmp/zscaler.crt -out ~/.zscaler.pem 2>/dev/null \
        || cp /tmp/zscaler.crt ~/.zscaler.pem \
        && echo "Zscaler cert refreshed ✓"'';
    };
  }];
}
