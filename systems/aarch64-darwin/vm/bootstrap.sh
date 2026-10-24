#!/usr/bin/env bash
# Provisions the morty-work golden image. Runs AS ROOT (packer: sudo -n bash).
# Content only — Packer owns boot/ssh/shutdown/cleanup. See morty.pkr.hcl.
set -euo pipefail
cd /

USER_NAME="svenlito"
CLONE_DIR="/Users/${USER_NAME}/.config/nix"
REPO_TAR="/tmp/nix-config.tgz" # working-tree tarball uploaded by packer

# 1. Create svenlito as an admin with a SecureToken (via the admin creds). The
#    password is a throwaway echoed ONCE to the Packer log; it is reset at
#    first-run (Phase 5) and never escrowed into the image.
pw="$(openssl rand -hex 12)"
echo "BUILD_SVENLITO_PASSWORD=${pw}"
sysadminctl -addUser "${USER_NAME}" -fullName "Sven Lito" -admin \
  -password "${pw}" -adminUser admin -adminPassword admin
# -secureTokenStatus writes to stderr:
if ! sysadminctl -secureTokenStatus "${USER_NAME}" 2>&1 | grep -qi enabled; then
  echo "svenlito has no SecureToken" >&2
  exit 1
fi

# 2. Temp passwordless sudo for the brew activation during the build; removed in
#    the lockdown below.
echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/svenlito-build
chmod 0440 /etc/sudoers.d/svenlito-build

# 3. nix-darwin runs brew as the user owning /opt/homebrew (base is a *-base).
chown -R "${USER_NAME}" /opt/homebrew

# 4. Install upstream Nix (Determinate conflicts with nix.enable). flakes are
#    off by default, so every nix invocation enables them explicitly.
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

# 5. Install the uploaded working-tree repo at ~/.config/nix, owned by svenlito.
install -d -m 755 "/Users/${USER_NAME}/.config"
rm -rf "${CLONE_DIR}"
mkdir -p "${CLONE_DIR}"
tar xzf "${REPO_TAR}" -C "${CLONE_DIR}"
chown -R "${USER_NAME}" "/Users/${USER_NAME}/.config"

# 6. Hostname before the switch so the flake selects #morty.
scutil --set LocalHostName morty
scutil --set ComputerName morty
scutil --set HostName morty

# 7. First switch via a `path:` flakeref (not git+file://): the switch runs as
#    root over the copy, and Nix's libgit2 fetcher would reject a git repo for
#    dubious ownership. `path:` copies the directory and skips that check.
#    Zscaler install self-gates on /etc/morty/... absent, so it does NOT run here.
nix --extra-experimental-features 'nix-command flakes' run \
  --inputs-from "path:${CLONE_DIR}" nix-darwin#darwin-rebuild -- \
  switch --flake "path:${CLONE_DIR}#morty"

# 8. Authorize the operator public key (packer uploaded it).
install -d -m 700 "/Users/${USER_NAME}/.ssh"
cat /tmp/operator.pub >>"/Users/${USER_NAME}/.ssh/authorized_keys"
chown -R "${USER_NAME}" "/Users/${USER_NAME}/.ssh"
chmod 600 "/Users/${USER_NAME}/.ssh/authorized_keys"

# 9. Lockdown that PRESERVES Packer's admin communicator (admin removal is
#    deferred to first boot in step 10). Drop the build NOPASSWD, disable
#    autologin, go key-only for sshd.
rm -f /etc/sudoers.d/svenlito-build
rm -f /etc/kcpassword
defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
cat >/etc/ssh/sshd_config.d/000-lockdown.conf <<'EOF'
AuthenticationMethods publickey
PasswordAuthentication no
KbdInteractiveAuthentication no
AllowUsers svenlito
EOF

# 10. First-boot one-shot (on the daily clone): remove admin + regenerate the
#     shared host keys, then self-destruct. Deferred here because Packer shuts
#     the build VM down AS admin.
install -d -m 755 /usr/local/libexec
cat >/usr/local/libexec/morty-firstboot.sh <<'EOF'
#!/bin/sh
/usr/bin/dscl . -delete /Users/admin 2>/dev/null || true
/bin/rm -rf /Users/admin
/bin/rm -f /etc/ssh/ssh_host_*
/usr/bin/ssh-keygen -A
/bin/launchctl bootout system/morty.firstboot 2>/dev/null || true
/bin/rm -f /Library/LaunchDaemons/morty.firstboot.plist /usr/local/libexec/morty-firstboot.sh
EOF
chmod 0755 /usr/local/libexec/morty-firstboot.sh
cat >/Library/LaunchDaemons/morty.firstboot.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>morty.firstboot</string>
  <key>RunAtLoad</key><true/>
  <key>ProgramArguments</key><array>
    <string>/bin/sh</string>
    <string>/usr/local/libexec/morty-firstboot.sh</string>
  </array>
</dict></plist>
EOF
chown root:wheel /Library/LaunchDaemons/morty.firstboot.plist
chmod 0644 /Library/LaunchDaemons/morty.firstboot.plist

# 11. Scrub build detritus (tolerate protected paths under set -e).
rm -f /var/root/.zsh_history /Users/*/.zsh_history 2>/dev/null || true
rm -rf /Users/*/.zsh_sessions /Users/*/Library/Logs/Homebrew 2>/dev/null || true
rm -rf /Library/Logs/DiagnosticReports/* /var/log/install.log 2>/dev/null || true
rm -rf /nix/var/log/nix /var/db/diagnostics/* /var/db/sudo/ts/* 2>/dev/null || true

echo "bootstrap complete"
