---
paths:
  - "common/claude-code/**"
---

# Claude Code Integration

Located in `common/claude-code/`, managed via `default.nix`:

- **Settings**: `settings.json` (writable out-of-store symlink) — also
  holds the hook definitions. A `strip-automode` git clean filter
  (`.gitattributes` + `common/git`) drops the runtime-written `autoMode`
  block on stage so it never reaches this public repo — but only once
  `home-manager` has installed the filter config, so a fresh checkout
  before the first switch has no guard
- **Skills**: merged by `default.nix` (`selectedSkills`) from upstream
  flake inputs plus local `skills/`, auto-invoked by description match
- **Global CLAUDE.md**: user preferences (writable out-of-store symlink)

Upstream skill and herdr-plugin sources are `flake = false` inputs
(`cc-*`, `herdr-plugin-*` in `flake.nix`), so their revs and hashes live
in `flake.lock` and bump via `nix flake update` / Renovate rather than
drifting as inline `fetchFromGitHub` pins. The one exception: global MCP
servers are jq-deep-merged into `~/.claude.json` by the
`claudeUserMcpServers` activation script, since Claude Code reads global
MCP definitions only from that file's top-level `mcpServers` key, never
from `settings.json`.

## Skill & Agent Evals

Three tiers guard `common/claude-code/{skills,agents}` — see
`common/claude-code/eval/README.md`. An agent binding to a skill merged
from a flake input must be added to `KNOWN_EXTERNAL_SKILLS` in
`eval/lint-skills.py` or the pre-commit lint fails.
