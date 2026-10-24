{ pkgs, ... }:

# Host-side VM tooling for rick (NOT the morty guest). Imported only in rick's
# extraModules so it never lands inside the VM.
#   - tart + packer (nixpkgs; cirruslabs brew tart formula is broken, packer BUSL)
#   - launchd agents that keep the morty VM + its SOCKS tunnel up (so corp access
#     survives reboots/blips with no hand-run ssh).
let
  # Resolves morty's current IP and holds open a SOCKS proxy on :1080. KeepAlive
  # retries until morty is up and reconnects if the tunnel drops.
  mortySocks = pkgs.writeShellScript "morty-socks" ''
    ip=$(${pkgs.tart}/bin/tart ip morty 2>/dev/null)
    [ -n "$ip" ] || { echo "morty not running yet" >&2; exit 1; }
    exec /usr/bin/ssh -N -D 127.0.0.1:1080 \
      -i "$HOME/.ssh/morty_operator" \
      -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ServerAliveInterval=20 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes \
      admin@"$ip"
  '';
in
{
  environment.systemPackages = [
    pkgs.tart
    pkgs.packer
  ];

  # Keep the morty VM running (graphics on, so clipboard + ZCC reauth work).
  # bootout the agent to stop it deliberately (KeepAlive revives it otherwise).
  launchd.user.agents.morty-vm.serviceConfig = {
    ProgramArguments = [
      "${pkgs.tart}/bin/tart"
      "run"
      "morty"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    ThrottleInterval = 10;
    StandardOutPath = "/tmp/morty-vm.log";
    StandardErrorPath = "/tmp/morty-vm.log";
  };

  # Keep the SOCKS tunnel (rick :1080 -> morty) up for the corp Chrome / CLI.
  launchd.user.agents.morty-socks.serviceConfig = {
    ProgramArguments = [ "${mortySocks}" ];
    RunAtLoad = true;
    KeepAlive = true;
    ThrottleInterval = 10;
    StandardOutPath = "/tmp/morty-socks.log";
    StandardErrorPath = "/tmp/morty-socks.log";
  };
}
