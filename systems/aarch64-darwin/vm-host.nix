{ pkgs, username, ... }:

# Host-side VM tooling for rick (NOT the morty guest). Imported only in rick's
# extraModules so it never lands inside the VM.
#   - tart + packer (nixpkgs; cirruslabs brew tart formula is broken, packer BUSL)
#   - launchd agents that keep the morty VM + its SOCKS tunnel up, gated on a
#     sentinel file so corp access is opt-in (off = no Zscaler VM burning cycles).
let
  # launchd watches this path; the agents run only while it exists. `morty up`
  # touches it, `morty down` removes it. Absent by default -> VM stays off across
  # reboots until corp access is wanted.
  flag = "/Users/${username}/.config/corp/morty-enabled";
  keepAliveWhileEnabled = {
    PathState.${flag} = true;
  };

  # Resolves morty's current IP and holds open a SOCKS proxy on :1080. Waits for
  # the VM to boot + sshd to accept before launching ssh, so a transient empty IP
  # or not-yet-ready sshd during boot doesn't wedge the agent (KeepAlive revives
  # on genuine tunnel drops; this loop covers the boot race).
  mortySocks = pkgs.writeShellScript "morty-socks" ''
    ip=""
    for _ in $(seq 1 30); do
      ip=$(${pkgs.tart}/bin/tart ip morty 2>/dev/null)
      if [ -n "$ip" ] && (exec 3<>/dev/tcp/"$ip"/22) 2>/dev/null; then
        exec 3>&- 3<&-
        break
      fi
      ip=""
      sleep 2
    done
    [ -n "$ip" ] || { echo "morty not reachable after 60s" >&2; exit 1; }
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
            s.end_headers()
            try:
                s.wfile.write(b)
            except (BrokenPipeError, ConnectionResetError):
                pass
        def log_message(s, *a): pass
    # Threaded: every app on the host resolves this PAC, so requests arrive
    # concurrently; a single-threaded server head-of-line-blocks on one slow
    # client and wedges every other PAC fetch.
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 8099), H)
    srv.daemon_threads = True
    srv.serve_forever()
  '';

  # On/off switch for the whole corp stack. Flips the sentinel; launchd does the
  # rest (starts/stops VM + tunnel + PAC via KeepAlive.PathState).
  mortyCtl = pkgs.writeShellScriptBin "morty" ''
    flag="$HOME/.config/corp/morty-enabled"
    case "''${1:-}" in
      up)
        mkdir -p "$(dirname "$flag")" && touch "$flag"
        echo "morty enabled -- launchd bringing up VM + SOCKS :1080 + PAC"
        ;;
      down)
        rm -f "$flag"
        echo "morty disabled -- launchd stopping VM + tunnel + PAC"
        ;;
      status)
        if [ -e "$flag" ]; then echo "flag: enabled"; else echo "flag: disabled"; fi
        ${pkgs.tart}/bin/tart list 2>/dev/null | grep -E 'NAME|morty' || true
        ;;
      *)
        echo "usage: morty up|down|status" >&2
        exit 2
        ;;
    esac
  '';
in
{
  environment.systemPackages = [
    pkgs.tart
    pkgs.packer
    mortyCtl
  ];

  launchd.user.agents = {
    # Run the morty VM (graphics on, so clipboard + ZCC reauth work) only while
    # the sentinel exists; `morty down` removes it and launchd SIGTERMs `tart run`.
    morty-vm.serviceConfig = {
      ProgramArguments = [
        "${pkgs.tart}/bin/tart"
        "run"
        "morty"
      ];
      RunAtLoad = false;
      KeepAlive = keepAliveWhileEnabled;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/morty-vm.log";
      StandardErrorPath = "/tmp/morty-vm.log";
    };

    # Keep the SOCKS tunnel (rick :1080 -> morty) up for the corp browser / CLI.
    morty-socks.serviceConfig = {
      ProgramArguments = [ "${mortySocks}" ];
      RunAtLoad = false;
      KeepAlive = keepAliveWhileEnabled;
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
      RunAtLoad = false;
      KeepAlive = keepAliveWhileEnabled;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/morty-pac.log";
      StandardErrorPath = "/tmp/morty-pac.log";
    };
  };
}
