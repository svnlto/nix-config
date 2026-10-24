#!/usr/bin/env bash
# Provisions the morty-work golden image. Runs AS ROOT (packer: sudo -n bash).
# Local VM: uses the base image's `admin` user as-is — no user management.
# Content only — Packer owns boot/ssh/shutdown/cleanup. See morty.pkr.hcl.
set -euo pipefail
cd /

USER_NAME="admin"
CLONE_DIR="/Users/${USER_NAME}/.config/nix"
REPO_TAR="/tmp/nix-config.tgz" # working-tree tarball uploaded by packer
# Public Intune blob (accepted as disclosed; already in git history). Written to
# the runtime file below so the in-build switch installs ZCC (SHA-pinned wrapper).
ZSCALER_URL="https://blobintunestore.blob.core.windows.net/sources/Install-FastSTD-Zscaler.sh"

# 1. nix-darwin runs brew as the user owning /opt/homebrew (base is a *-base).
chown -R "${USER_NAME}" /opt/homebrew

# 2. Install upstream Nix (Determinate conflicts with nix.enable). flakes are off
#    by default, so every nix invocation enables them explicitly.
curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes
set +u
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
set -u
export NONINTERACTIVE=1
# Move aside files the installer wrote that nix-darwin's /etc check rejects.
for f in /etc/nix/nix.conf /etc/zshrc /etc/bashrc; do
  [ -e "$f" ] && mv "$f" "$f.before-nix-darwin" || true
done

# 3. Install the uploaded working-tree repo at ~/.config/nix.
install -d -m 755 "/Users/${USER_NAME}/.config"
rm -rf "${CLONE_DIR}"
mkdir -p "${CLONE_DIR}"
tar xzf "${REPO_TAR}" -C "${CLONE_DIR}"
chown -R "${USER_NAME}" "/Users/${USER_NAME}/.config"

# 4. Hostname before the switch so the flake selects #morty.
scutil --set LocalHostName morty
scutil --set ComputerName morty
scutil --set HostName morty

# 5. Write the runtime installer-url so the switch's zscaler.nix activation
#    INSTALLS ZCC now (SHA-pinned). Extension approval + SSO stay manual.
install -d -m 755 /etc/morty
umask 077
printf '%s' "${ZSCALER_URL}" >/etc/morty/zscaler-installer-url
chmod 600 /etc/morty/zscaler-installer-url
umask 022

# 6. First switch via a `path:` flakeref (not git+file://): the switch runs as
#    root over the copy, and Nix's libgit2 fetcher would reject a git repo for
#    dubious ownership. `path:` copies the directory and skips that check.
nix --extra-experimental-features 'nix-command flakes' run \
  --inputs-from "path:${CLONE_DIR}" nix-darwin#darwin-rebuild -- \
  switch --flake "path:${CLONE_DIR}#morty"

# 7. Authorize the operator public key so rick can ssh in (ProxyJump / ssh -D).
install -d -m 700 "/Users/${USER_NAME}/.ssh"
cat /tmp/operator.pub >>"/Users/${USER_NAME}/.ssh/authorized_keys"
chown -R "${USER_NAME}" "/Users/${USER_NAME}/.ssh"
chmod 600 "/Users/${USER_NAME}/.ssh/authorized_keys"

# 8. tart guest agent (clipboard via vdagent + `tart exec`). Pinned + verified;
#    binary + both launchd units so clipboard works regardless of base state.
ga=$(mktemp)
curl -fsSL "https://github.com/cirruslabs/tart-guest-agent/releases/download/v0.15.0/tart-guest-agent-darwin-all.tar.gz" -o "$ga"
[ "$(shasum -a 256 "$ga" | awk '{print $1}')" = "eb47f402f18e742a8ea96344115ca776179f9c4c67494bc0c46a10a68db280b7" ] \
  || { echo "guest-agent SHA mismatch" >&2; exit 1; }
gad=$(mktemp -d)
tar xzf "$ga" -C "$gad" tart-guest-agent
install -m 0755 "$gad/tart-guest-agent" /opt/homebrew/bin/tart-guest-agent
rm -rf "$ga" "$gad"
cat >/Library/LaunchDaemons/org.cirruslabs.tart-guest-daemon.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>org.cirruslabs.tart-guest-daemon</string>
  <key>ProgramArguments</key><array>
    <string>/opt/homebrew/bin/tart-guest-agent</string><string>--run-daemon</string>
  </array>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>/bin:/usr/bin:/usr/sbin:/usr/local/bin:/opt/homebrew/bin</string></dict>
  <key>WorkingDirectory</key><string>/var/empty</string>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
</dict></plist>
EOF
cat >/Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>org.cirruslabs.tart-guest-agent</string>
  <key>ProgramArguments</key><array>
    <string>/opt/homebrew/bin/tart-guest-agent</string><string>--run-agent</string>
  </array>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>/bin:/usr/bin:/usr/sbin:/usr/local/bin:/opt/homebrew/bin</string></dict>
  <key>WorkingDirectory</key><string>/var/empty</string>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
</dict></plist>
EOF
chown root:wheel /Library/LaunchDaemons/org.cirruslabs.tart-guest-daemon.plist /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist
chmod 0644 /Library/LaunchDaemons/org.cirruslabs.tart-guest-daemon.plist /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist

echo "bootstrap complete"
