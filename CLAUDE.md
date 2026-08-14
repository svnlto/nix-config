# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when
working with code in this repository.

## Core Commands

The `justfile` is the canonical command surface — run recipes from the
repo root. Tools come from `nix develop` (direnv loads it automatically).

```bash
just              # list every recipe
just switch       # apply config (detects Darwin/Linux and arch)
just check        # nix flake check --no-build
just update       # update all flake inputs
just update-fresh # advance only nixpkgs-unstable (fresh-tools channel)
just fmt          # nixfmt on git-tracked *.nix
just pre-commit   # run every hook against all files
just lint-skills  # Tier 1 skill/agent frontmatter lint
just route-eval   # Tier 2 routing eval (model calls, on demand)
just clean        # GC generations older than 7d
```

`just` runs recipes in a non-interactive bash that does not inherit the
user's `nix.conf`, so its recipes invoke nix with
`--extra-experimental-features 'nix-command flakes'` explicitly. Keep
that when adding nix-invoking recipes.

Equivalent shell aliases exist for the apply path — `nixswitch` (macOS,
resolves the hostname via `scutil`) and `nixswitch`/`hmswitch` on Linux
(arch-detecting shell functions). Add `--show-trace` to debug builds.

## Skill & Agent Evals

Two tiers guard `common/claude-code/{skills,agents}` — see
`common/claude-code/eval/README.md`:

- **Tier 1** `lint-skills.py` — deterministic, runs in pre-commit
  (`claude-skills-lint`). Checks frontmatter presence, `name` ==
  directory (skills) / filename stem (agents), `description` ≤ 1536
  chars, and that agent `skills:` bindings resolve. An agent binding to
  a skill merged from a flake input must be added to
  `KNOWN_EXTERNAL_SKILLS` in the script or the lint fails
- **Tier 2** `routing/run.sh` — probabilistic, makes `claude` CLI model
  calls, never in pre-commit. `routing/cases.tsv` maps prompt →
  expected skill. Treat a single miss as a prompt to tune a
  `description`, then re-run

## Commit Convention

This repo follows [Conventional Commits](https://www.conventionalcommits.org/).

Format: `<type>(<scope>): <subject>`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `chore`, `revert`
Scopes: `darwin`, `common`, `deps`, `release`

## Architecture Overview

Cross-platform Nix configuration managing macOS hosts (nix-darwin)
and Linux dev environments (home-manager). No NixOS support.

### Hosts

Defined in `flake.nix`:

- `rick` — personal macOS (user `svenlito`, personal Homebrew)
- Work macOS — not yet wired. Add a `mkDarwinSystem` entry once the machine
  identifier is known, pulling `homebrew/work.nix` +
  `systems/aarch64-darwin/corporate.nix` (a vendor-agnostic managed-Mac
  skeleton — fill in the employer's VPN CA / SSO / tooling there)
- `minimal-x86` / `minimal-arm` — Linux home-manager (containers, cloud)

macOS builds via `mkDarwinSystem`, Linux via `mkHomeManagerConfig`.
Both validate the username and apply the fresh-tools overlay.

### Fresh-tools overlay

`nixpkgs` is pinned to stable (`nixos-26.05`). Hand-picked tools that
need to be newer come from a separately-pinned `nixpkgs-unstable` input
via `common/overlays/fresh-tools.nix` (`freshToolsOverlay`). Advance the
stable base and the fresh channel independently (`nix flake update` vs
`nix flake update nixpkgs-unstable`). The overlay is applied in
`mkNixpkgs` AND re-applied inside `mkDarwinSystem` (nix-darwin builds its
own pkgs) — add it in both places if you change how pkgs is constructed.

Current fresh tools: `devbox`, `jujutsu`, `jjui`, `lazyjj` — the jj
toolchain moves fast, which is why this repo tracks it off-stable.

### Directory Structure

```text
flake.nix                        # Entry point — mkDarwinSystem, mkHomeManagerConfig
justfile                         # Task runner — canonical command surface
common/
  default.nix                    # Shared Nix settings (performance, experimental features)
  home-manager-base.nix          # Shared HM base (imports home-packages, claude-code, programs)
  programs/default.nix           # Shared program configs (direnv, gh, zsh)
  packages.nix                   # All package definitions (core, dev, darwin, system)
  home-packages.nix              # HM package imports
  constants.nix                  # Centralized tuning values (performance, history, cleanup)
  versions.nix                   # State version pinning (rarely change!)
  overlays/fresh-tools.nix       # Pulls hand-picked tools from nixpkgs-unstable
  git/                           # Cross-platform git config (SSH signing on both, via 1Password)
  zsh/shared.nix                 # Aliases, session vars, PATH, tool init
  zsh/default.omp.json           # Oh My Posh theme
  claude-code/                   # Claude Code settings, hooks, commands, skills, statusline
  claude-code/eval/              # Skill/agent lint (Tier 1) + routing eval (Tier 2)
  neovim/                        # Neovim config
  jujutsu/                       # jj config (signing, difftastic, git colocation)
  ghostty/                       # Ghostty terminal (macOS only — guarded with mkIf)
  lazygit/                       # Cross-platform via xdg.configFile
  ssh/ k9s/ herdr/ gh-dash/      # Additional tool configs
  profiles/                      # Optional opt-in modules
systems/
  aarch64-darwin/                # macOS: home.nix, homebrew/, defaults.nix, dock.nix, corporate.nix
  aarch64-linux/default.nix      # Linux: minimal HM config for containers
```

### Configuration Flow

1. `flake.nix` defines `darwinConfigurations` and `homeConfigurations`
2. `common/home-manager-base.nix` imports shared modules
   (home-packages, claude-code, programs)
3. `common/programs/default.nix` configures direnv, gh, zsh
4. `common/default.nix` sets Nix performance settings
5. `systems/{arch}/` adds only platform-specific settings
6. `packages.nix` centralizes all package definitions

### Import Chain

```text
flake.nix -> systems/{arch}/home.nix -> common/home-manager-base.nix -> specialized modules
                                     -> common/default.nix (Linux only, for nix settings)
```

## Package Management

- **Shared packages**: `common/packages.nix` (`corePackages`, `devPackages`)
- **macOS-only**: `common/packages.nix` (`darwinPackages`) — imported via `systems/aarch64-darwin/home.nix`
- **macOS GUI apps**: `systems/aarch64-darwin/homebrew/`

**Never** put macOS-only packages (like `reattach-to-user-namespace`)
in shared lists — they break Linux builds.

## Claude Code Integration

Located in `common/claude-code/`, managed via `default.nix`:

- **Settings**: `settings.json` (writable out-of-store symlink) — also
  holds the hook definitions
- **Hooks**: defined in `settings.json`, scripts in `hooks/` —
  SessionStart (herdr agent state), PreToolUse on Bash
  (`block-destructive.sh`), PostToolUse pre-commit on edited files, Stop
  `nix flake check` (only when dirty `.nix` files exist)
- **Skills**: merged by `default.nix` (`selectedSkills`) from upstream
  flake inputs plus local `skills/`, auto-invoked by description match
- **Status line**: `statusline-command.sh` (writable out-of-store symlink)
- **Global CLAUDE.md**: user preferences (writable out-of-store symlink)

Upstream skill and herdr-plugin sources are `flake = false` inputs
(`cc-*`, `herdr-plugin-*` in `flake.nix`), so their revs and hashes live
in `flake.lock` and bump via `nix flake update` / Renovate rather than
drifting as inline `fetchFromGitHub` pins. Two exceptions:

- `chrome-devtools-mcp` is pinned inline in `claude-code/default.nix` as
  a version-coupled pair (npm tarball + repo rev for its skills) — move
  both together or the skills desync from the binary
- Global MCP servers are jq-deep-merged into `~/.claude.json` by the
  `claudeUserMcpServers` activation script. Claude Code reads global MCP
  definitions only from that file's top-level `mcpServers` key, never
  from `settings.json`

## Pre-commit Hooks and CI

Installed via `pre-commit install`. Hooks: nixfmt, statix, deadnix,
flake-check, markdownlint, claude-skills-lint, trailing-whitespace,
end-of-file-fixer, check-yaml, check-added-large-files,
detect-private-key.

markdownlint excludes `common/claude-code/agents/` and the jira
reference templates — machine-consumed content that intentionally leads
with prose instead of an H1 (MD041). Prose wraps at 80 chars (MD013);
tables and code blocks are exempt.

`.github/workflows/pre-commit.yml` runs `pre-commit run --all-files` on
push and PR to `main`. Renovate bumps flake inputs and pre-commit revs.

## Critical Pitfalls

1. **`nix.optimise` is nix-darwin only** — never set in
   `common/default.nix`, only in `systems/aarch64-darwin/`
2. **Nix flakes only see git-tracked files** — this repo is
   colocated with jj, which registers new paths in git's index on
   any jj command, so no `git add` is needed. In a pure-git
   checkout, `git add` new files before `nixswitch` or builds
   silently miss them
3. **No NixOS support** — no `boot.*`, `services.*`,
   `virtualisation.*` modules
4. **Platform detection** — use
   `pkgs.stdenv.isLinux`/`isDarwin` and `lib.mkIf`
5. **Cross-platform paths** — use `xdg.configFile` not
   hardcoded `Library/Application Support/`
6. **ZSH uses `initContent`** not deprecated `initExtra`
7. **State versions rarely change** — `common/versions.nix`
   controls backward compat, update only after migration guides
8. **Imports can't depend on pkgs** — use `lib.mkIf` inside
   modules, not `lib.optionals` in import lists (infinite recursion)
9. **Ghostty is macOS-only** — guarded with
   `lib.mkIf (!pkgs.stdenv.isLinux)` in `common/ghostty/default.nix`

## Profiles

Optional modules in `common/profiles/` for extending configurations:

```nix
# In flake.nix
custom = mkHomeManagerConfig {
  username = "user";
  extraModules = [ ./common/profiles/your-profile.nix ];
};
```

## Troubleshooting

```bash
nixswitch --show-trace    # Debug macOS build issues
hmswitch --show-trace     # Debug Linux build issues
sudo darwin-rebuild rollback    # macOS emergency rollback
home-manager --rollback         # Linux emergency rollback
nix-clean                       # Cleanup (keeps 7 days)
```
