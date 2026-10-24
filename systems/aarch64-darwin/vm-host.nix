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
  # Serves the untracked corp PAC over http on 127.0.0.1:8099 with the correct
  # MIME (macOS honors an http:// system PAC; a file:// PAC is silently ignored).
  # The system auto-proxy URL points here (set once via networksetup).
  pacServer = pkgs.writeText "corp-pac-server.py" ''
    import http.server, os
    PAC = os.path.expanduser("~/.config/corp/corp.pac")
    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(s):
            try:
                b = open(PAC, "rb").read()
            except OSError:
                s.send_error(503); return
            s.send_response(200)
            s.send_header("Content-Type", "application/x-ns-proxy-autoconfig")
            s.send_header("Content-Length", str(len(b)))
            s.end_headers(); s.wfile.write(b)
        def log_message(s, *a): pass
    http.server.HTTPServer(("127.0.0.1", 8099), H).serve_forever()
  '';
in
{
  environment.systemPackages = [
    pkgs.tart
    pkgs.packer
  ];

  launchd.user.agents = {
    # Keep the morty VM running (graphics on, so clipboard + ZCC reauth work).
    # bootout the agent to stop it deliberately (KeepAlive revives it otherwise).
    morty-vm.serviceConfig = {
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

    # Keep the SOCKS tunnel (rick :1080 -> morty) up for the corp browser / CLI.
    morty-socks.serviceConfig = {
      ProgramArguments = [ "${mortySocks}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/morty-socks.log";
      StandardErrorPath = "/tmp/morty-socks.log";
    };

    # Serve the corp PAC over http (the system auto-proxy URL points here) so any
    # browser routes corp domains through the tunnel; everything else DIRECT.
    morty-pac.serviceConfig = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "${pacServer}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/morty-pac.log";
      StandardErrorPath = "/tmp/morty-pac.log";
    };
  };
}
