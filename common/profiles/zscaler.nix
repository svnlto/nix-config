# Opt-in profile: provision + support a TLS-inspecting corporate proxy client.
#
# Some corporate proxies (Zscaler ZIA and similar) inspect HTTPS by re-signing
# every connection with an internal CA. macOS apps and Safari trust it via the
# System keychain, but CLI tools (the nix daemon, git, curl, node, python) ship
# their own CA store and ignore the keychain — so they fail with cert errors
# until pointed at a bundle that includes those internal roots.
#
# Three layers, because each tool reads its trust store differently:
#
#   1. system.activationScripts (root): install the client if absent, then
#      build a CA bundle = public roots + whatever the System keychain trusts.
#   2. nix.settings.ssl-cert-file: on macOS multi-user Nix this sets the
#      nix-daemon's launchd NIX_SSL_CERT_FILE (the daemon ignores shell env).
#   3. home-manager (user): nix-darwin's environment.variables do NOT reach
#      login shells on this setup, so the CLI env + git config are set through
#      home-manager instead, which writes the user's shell + ~/.gitconfig.
#
# SECURITY: the installer runs a remote script as root. The URL is a public
# employer blob (no secrets/identifiers), gated on the app being absent so it
# runs once. Set installerUrl to "" to disable auto-install.
#
# Still manual after install: approving the client's macOS System Extension
# (GUI) and the SSO/MFA login. ZPA access also needs a supported antivirus
# running + the firewall on, or device posture blocks it.
#
# Wired into `rick` via extraModules in flake.nix.
{
  pkgs,
  lib,
  username,
  ...
}:

let
  bundle = "/etc/ssl/certs/corp-ca-bundle.crt";
  appPath = "/Applications/Zscaler/Zscaler.app";
  installerUrl = "https://blobintunestore.blob.core.windows.net/sources/Install-FastSTD-Zscaler.sh";
  certEnv = {
    NIX_SSL_CERT_FILE = bundle;
    SSL_CERT_FILE = bundle;
    CURL_CA_BUNDLE = bundle;
    GIT_SSL_CAINFO = bundle;
    NODE_EXTRA_CA_CERTS = bundle;
    REQUESTS_CA_BUNDLE = bundle;
    AWS_CA_BUNDLE = bundle;
  };
in
{
  # nix-darwin only runs a fixed set of activation hooks (postActivation, ...);
  # arbitrary custom keys are silently dropped, so this must ride postActivation.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # 1. One-shot install of the proxy client (if absent).
    ${lib.optionalString (installerUrl != "") ''
      if [ ! -e "${appPath}" ]; then
        echo "Corp proxy client absent; running installer..." >&2
        tmp=$(mktemp)
        if /usr/bin/curl -fsSL "${installerUrl}" -o "$tmp"; then
          /bin/bash "$tmp" >&2 || echo "  installer exited non-zero" >&2
        else
          echo "  installer download failed; skipping" >&2
        fi
        rm -f "$tmp"
      fi
    ''}

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

  # The nix daemon runs as root and reads this from its launchd plist, not the
  # shell env.
  nix.settings.ssl-cert-file = bundle;

  # Shell env + git trust for the user (nix-darwin environment.variables do not
  # reach login shells here; home-manager owns the user's shell).
  home-manager.users.${username} = {
    home.sessionVariables = certEnv;
    programs.git.settings.http.sslCAInfo = bundle;
  };
}
