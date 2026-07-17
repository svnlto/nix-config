---
description: Audit the Nix config for stale pins and out-of-date tool configs
allowed-tools: Bash(nix flake:*), Bash(git:*), Read, Grep, Glob
---

# Config audit

Invoke the `config-audit` skill and run a full freshness audit of this Nix
configuration:

- Compare pinned flake inputs and `fetchFromGitHub` revs against upstream.
- Flag tool configs (Claude Code settings, skills, agents) that have drifted
  from current best practice.
- Report findings ranked by impact; do not change anything without approval.

Focus area (optional): $ARGUMENTS
