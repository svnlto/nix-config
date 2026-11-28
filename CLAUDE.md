# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when
working with code in this repository.

## Core Commands

The `justfile` is the canonical command surface — run recipes from the
repo root (`just` lists them). Tools come from `nix develop` (direnv
loads it automatically).

`just` runs recipes in a non-interactive bash that does not inherit the
user's `nix.conf`, so its recipes invoke nix with
`--extra-experimental-features 'nix-command flakes'` explicitly. Keep
that when adding nix-invoking recipes.

Equivalent shell aliases exist for the apply path — `nixswitch` (macOS,
resolves the hostname via `scutil`) and `nixswitch`/`hmswitch` on Linux
(arch-detecting shell functions). Add `--show-trace` to debug builds.

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
- `schwifty` — music studio macOS (user `svenlito`, `homebrew/schwifty.nix`)
- Work macOS — not yet wired. Add a `mkDarwinSystem` entry once the
  machine identifier is known, pulling `homebrew/work.nix` +
  `systems/aarch64-darwin/corporate.nix` (a vendor-agnostic managed-Mac
  skeleton — fill in the employer's VPN CA / SSO / tooling there)
- `minimal-x86` / `minimal-arm` — Linux home-manager (containers, cloud)

Every macOS host shares `homebrew/common.nix` (baseline) + its own
`homebrew/<host>.nix` (host-specific brews/casks).

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

The current list is `freshTools` in that file.

## Package Management

- **Shared packages**: `common/packages.nix` (`corePackages`, `devPackages`)
- **macOS-only**: `common/packages.nix` (`darwinPackages`) — imported via `systems/aarch64-darwin/home.nix`
- **macOS GUI apps**: `systems/aarch64-darwin/homebrew/`

**Never** put macOS-only packages (like `reattach-to-user-namespace`)
in shared lists — they break Linux builds.

## Claude Code Integration

Conventions for `common/claude-code/` (settings, skills, evals) live in
`.claude/rules/claude-code.md`, which loads when working under that
directory.

## Pre-commit Hooks

markdownlint excludes `common/claude-code/agents/` — machine-consumed
content that intentionally leads with prose instead of an H1 (MD041).
Prose wraps at 80 chars (MD013); tables and code blocks are exempt.

## Critical Pitfalls

1. **`nix.optimise` is nix-darwin only** — never set in
   `common/default.nix`, only in `systems/aarch64-darwin/`
2. **Nix flakes only see git-tracked files** — `git add` new files
   before `nixswitch` or builds silently miss them
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
