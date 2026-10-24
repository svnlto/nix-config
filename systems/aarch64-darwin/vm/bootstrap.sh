#!/usr/bin/env bash
# Provisions the morty-work golden image: a plain Zscaler appliance — NO nix,
# no repo, no darwin-rebuild. morty's whole job is ZCC + sshd + guest agent, so
# it runs as the stock base image's `admin` user with these few additions.
# Runs AS ROOT (packer: sudo -n bash). Packer owns boot/ssh/shutdown/cleanup.
set -euo pipefail
cd /

USER_NAME="admin"
# Public Intune blob (accepted as disclosed; already in git history). Wrapper is
# SHA-pinned before it runs as root; a vendor republish changes the hash.
ZSCALER_URL="https://blobintunestore.blob.core.windows.net/sources/Install-FastSTD-Zscaler.sh"
ZSCALER_SHA="f9e167400c04b2690ca70ef743af96dd18784416c09b53cdbe00b98fdc2081e3"
GUEST_AGENT_URL="https://github.com/cirruslabs/tart-guest-agent/releases/download/v0.15.0/tart-guest-agent-darwin-all.tar.gz"
GUEST_AGENT_SHA="eb47f402f18e742a8ea96344115ca776179f9c4c67494bc0c46a10a68db280b7"

# 1. Install ZCC. Extension approval + SSO/MFA stay manual (interactive) in
#    first-run; the pkg install itself is headless.
if [ ! -e /Applications/Zscaler/Zscaler.app ]; then
  tmp=$(mktemp)
  curl -fsSL "$ZSCALER_URL" -o "$tmp"
  got=$(shasum -a 256 "$tmp" | awk '{print $1}')
  [ "$got" = "$ZSCALER_SHA" ] || { echo "ZCC installer SHA mismatch: $got" >&2; exit 1; }
  bash "$tmp" >&2
  rm -f "$tmp"
  [ -d /Applications/Zscaler/Zscaler.app ] || { echo "ZCC ran but app absent" >&2; exit 1; }
fi

# 2. Application firewall on (ZPA posture).
/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on >/dev/null 2>&1 || true

# 3. Hostname (identification only).
scutil --set LocalHostName morty
scutil --set ComputerName morty
scutil --set HostName morty

# 4. Authorize the operator public key so rick can ssh in (ProxyJump / ssh -D).
install -d -m 700 "/Users/${USER_NAME}/.ssh"
cat /tmp/operator.pub >>"/Users/${USER_NAME}/.ssh/authorized_keys"
chown -R "${USER_NAME}" "/Users/${USER_NAME}/.ssh"
chmod 600 "/Users/${USER_NAME}/.ssh/authorized_keys"

# 5. tart guest agent (clipboard via vdagent + `tart exec`). Pinned + verified;
#    binary + both launchd units, WorkingDirectory /var/empty.
ga=$(mktemp)
curl -fsSL "$GUEST_AGENT_URL" -o "$ga"
[ "$(shasum -a 256 "$ga" | awk '{print $1}')" = "$GUEST_AGENT_SHA" ] \
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
