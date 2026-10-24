_:

# morty VM networking: Tailscale only (stable MagicDNS address for the host's
# ProxyJump + `ssh -D` tunnel). No proxy daemon — the host's `ssh -D` is the
# transport. No corp CA here (SSH/CONNECT don't terminate TLS). sshd comes from
# the cirruslabs base image; the build/first-run lockdown makes it key-only.
{
  services.tailscale.enable = true;
}
