# Opt-in profile: provision + support a TLS-inspecting corporate proxy client.
#
# Some corporate proxies (Zscaler ZIA and similar) inspect HTTPS by re-signing
# every connection with an internal CA. macOS apps and Safari trust it via the
# System keychain, but CLI tools (the nix daemon, git, curl, node, python) ship
# their own CA store and ignore the keychain — so they fail with cert errors
# until pointed at a bundle that includes those internal roots.
#
# This module, on activation (which already runs as root), does two things:
#
#   1. If the proxy client app is not yet installed AND a local, untracked URL
#      file exists, fetch and run the employer's installer. The installer puts
#      the client in /Applications and trusts the internal CAs in the System
#      keychain. The installer URL is NOT in this repo — drop it in the file
#      below so no employer identifiers are committed:
#
#        sudo sh -c 'echo "<installer-url>" > /etc/corp-proxy-installer-url'
#
#      SECURITY: when the app is absent this executes a remote script as root.
#      It is gated on the app being missing, so it runs once, not every switch.
#      Leave the URL file absent to disable auto-install and provision by hand.
#
#   2. Rebuild a CA bundle = public roots + whatever the System keychain trusts,
#      and repoint the toolchain at it. With nothing extra trusted the bundle is
#      just the public roots, so nothing breaks.
#
# Not automatable here, still manual after install: approving the client's macOS
# System Extension (GUI) and the SSO/MFA login.
#
# Wired into `rick` via extraModules in flake.nix.
{ pkgs, lib, ... }:

let
  bundle = "/etc/ssl/certs/corp-ca-bundle.crt";
  urlFile = "/etc/corp-proxy-installer-url";
  appPath = "/Applications/Zscaler/Zscaler.app";
in
{
  system.activationScripts.corpProxyClient.text = ''
    # 1. One-shot install from a local, untracked URL file (if present).
    if [ ! -e "${appPath}" ] && [ -r "${urlFile}" ]; then
      url=$(/usr/bin/head -n1 "${urlFile}" | /usr/bin/tr -d '[:space:]')
      if [ -n "$url" ]; then
        echo "Corp proxy client absent; running installer from ${urlFile}..." >&2
        tmp=$(mktemp)
        if /usr/bin/curl -fsSL "$url" -o "$tmp"; then
          /bin/bash "$tmp" >&2 || echo "  installer exited non-zero" >&2
        else
          echo "  installer download failed; skipping" >&2
        fi
        rm -f "$tmp"
      fi
    fi

    # 2. Rebuild the CA bundle for CLI tooling from the System keychain.
    echo "Building corporate CA bundle..." >&2
    tmp=$(mktemp)
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt > "$tmp"
    /usr/bin/security find-certificate -a -p \
      /Library/Keychains/System.keychain >> "$tmp" 2>/dev/null || true
    install -m 0644 "$tmp" ${bundle}
    rm -f "$tmp"
    echo "  wrote ${bundle} ($(grep -c 'BEGIN CERT' ${bundle}) certs)" >&2
  '';

  # The nix daemon runs as root and reads this from nix.conf, not the user env.
  nix.settings.ssl-cert-file = bundle;

  environment.variables = {
    # Override the public-only default set in systems/aarch64-darwin/default.nix.
    NIX_SSL_CERT_FILE = lib.mkForce bundle;
    SSL_CERT_FILE = bundle;
    CURL_CA_BUNDLE = bundle;
    GIT_SSL_CAINFO = bundle;
    NODE_EXTRA_CA_CERTS = bundle;
    REQUESTS_CA_BUNDLE = bundle;
    AWS_CA_BUNDLE = bundle;
  };
}
