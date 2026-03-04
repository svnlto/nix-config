# Corporate Mac overrides
#
# 1. Determinate Nix — disable nix-darwin's Nix management (conflicts with
#    Determinate's own daemon).
# 2. VPN SSL inspection — corporate VPN replaces TLS certs with a CA not in
#    Node's default trust store.  NODE_EXTRA_CA_CERTS fixes this.
#
# Refresh the cert bundle after CA rotation:
#   refresh-corp-ca
{ lib, ... }:

{
  # Determinate Nix manages its own daemon; nix-darwin must not compete.
  # Force-disable all nix.* options that common/ and systems/ set unconditionally.
  nix.enable = false;
  nix.optimise.automatic = lib.mkForce false;
  home-manager.sharedModules = [
    {
      home.sessionVariables = {
        NODE_EXTRA_CA_CERTS = "$HOME/.corporate-ca.pem";
      };

      programs.zsh.shellAliases = {
        refresh-corp-ca = ''
          security find-certificate -a -p /Library/Keychains/System.keychain > ~/.corporate-ca.pem \
          && security find-certificate -a -p ~/Library/Keychains/login.keychain-db >> ~/.corporate-ca.pem \
          && echo "Corporate CA bundle refreshed"'';
      };
    }
  ];
}
