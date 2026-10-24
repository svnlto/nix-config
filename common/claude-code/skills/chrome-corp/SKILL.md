---
name: chrome-corp
description: >-
  Open and reuse a Chrome instance for internal corporate web apps (GitLab UI,
  SonarQube, dashboards) that are reachable only through the morty Zscaler VM
  proxy. Use when the user asks to open the corp/work browser, or to view or
  automate an internal corp site. Pairs with the chrome-devtools skill, which
  attaches to the same debug port and drives the page.
---

# Chrome for corp sites

## What this is

Internal corp web apps are not reachable from rick directly — they egress
through the morty Zscaler VM. A dedicated corp Chrome routes its traffic through
morty's SOCKS tunnel (`127.0.0.1:1080`, kept up by the launchd `morty-socks`
agent) via an untracked PAC. The normal Chrome and all personal browsing stay
direct and private.

The `chrome-devtools` MCP attaches to whatever Chrome is on the debug port
`9222`. So the flow is: open the corp Chrome on `9222`, then use the normal
`chrome-devtools` tools — they attach to and reuse this instance.

## Open the corp browser

Preconditions: morty is running and the tunnel is up (launchd `morty-vm` /
`morty-socks`; check `lsof -nP -iTCP:1080 -sTCP:LISTEN`). Only one Chrome can
own `:9222` — quit other debug Chrome instances first.

```bash
open -na "Google Chrome" --args \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.config/corp-chrome" \
  --proxy-server="socks5://127.0.0.1:1080" \
  --no-first-run --no-default-browser-check
```

This routes all of this profile's traffic through morty's SOCKS tunnel, so use
this dedicated profile for corp apps only — your normal Chrome stays direct.
Internal apps present real public certs (via ZPA), so no extra CA is needed.

Do NOT use `--proxy-pac-url=file://…`: current Chrome silently ignores a
`file://` PAC and goes direct, so corp sites return "RBAC: access denied"
(reached without the authorized ZPA path). A corp-only PAC would have to be
served over `http(s)://` or set as the macOS network proxy.

## Then drive it

Use the `chrome-devtools` tools as usual (`navigate_page`, `take_snapshot`,
etc.). They attach to `:9222` — the corp Chrome you just opened — and reuse it
across calls.
