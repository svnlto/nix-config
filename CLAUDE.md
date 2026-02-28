# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Commands

```bash
# macOS — apply system configuration (auto-detects hostname)
nixswitch

# Linux — apply Home Manager configuration (for Docker/containers)
hmswitch

# Docker — build and test in clean environment
just build          # builds the Docker image
just dev            # drops into zsh shell as svenlito

# Development shell with Nix tools (nixfmt, statix, deadnix, nil)
nix develop

# Validate flake
nix flake check
```

## Commit Convention

This repo follows [Conventional Commits](https://www.conventionalcommits.org/). See `docs/COMMIT_CONVENTION.md` for full spec.

Format: `<type>(<scope>): <subject>`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `chore`, `revert`
Scopes: `darwin`, `common`, `overlays`, `deps`, `release`

## Architecture Overview

Cross-platform Nix configuration managing macOS hosts (nix-darwin) and Linux dev environments (home-manager). No NixOS support.

### Directory Structure

```
flake.nix                        # Entry point — mkDarwinSystem, mkHomeManagerConfig
common/
  default.nix                    # Shared Nix settings (performance, experimental features)
  home-manager-base.nix          # Shared HM base (imports home-packages, claude-code, programs)
  programs/default.nix           # Shared program configs (direnv, gh, zsh)
  packages.nix                   # All package definitions (core, dev, darwin, system)
  home-packages.nix              # HM package imports
  constants.nix                  # Centralized tuning values (performance, history, cleanup)
  versions.nix                   # State version pinning (rarely change!)
  git/                           # Cross-platform git config (SSH signing on Linux only)
  zsh/shared.nix                 # Aliases, session vars, PATH, tool init
  zsh/default.omp.json           # Oh My Posh theme
  claude-code/                   # Claude Code settings, hooks, commands, skills, statusline
  neovim/                        # Neovim config
  tmux/                          # Tmux config + plugins
  tmuxinator/                    # Session layouts
  ghostty/                       # Ghostty terminal (macOS only — guarded with mkIf)
  lazygit/                       # Cross-platform via xdg.configFile
  profiles/                      # Optional opt-in modules
systems/
  aarch64-darwin/                # macOS: home.nix, homebrew/, defaults.nix, dock.nix
  aarch64-linux/default.nix      # Linux: minimal HM config for containers
```

### Configuration Flow

1. `flake.nix` defines `darwinConfigurations` and `homeConfigurations`
2. `common/home-manager-base.nix` imports shared modules (home-packages, claude-code, programs)
3. `common/programs/default.nix` configures direnv, gh, zsh
4. `common/default.nix` sets Nix performance settings
5. `systems/{arch}/` adds only platform-specific settings
6. `packages.nix` centralizes all package definitions

### Import Chain

```
flake.nix -> systems/{arch}/home.nix -> common/home-manager-base.nix -> specialized modules
                                     -> common/default.nix (Linux only, for nix settings)
```

## Package Management

- **Shared packages**: `common/packages.nix` (`corePackages`, `devPackages`)
- **macOS-only**: `common/packages.nix` (`darwinPackages`) — imported via `systems/aarch64-darwin/home.nix`
- **macOS GUI apps**: `systems/aarch64-darwin/homebrew/`

**Never** put macOS-only packages (like `reattach-to-user-namespace`) in shared lists — they break Linux builds.

## Claude Code Integration

Located in `common/claude-code/`, managed via `default.nix`:

- **Settings**: `settings.json` (writable out-of-store symlink)
- **Hooks**: `hooks.json` (automated linting/quality checks)
- **Commands**: `commands/` (breakdown-linear-issue)
- **Skills**: External skills from `claude-skills-generator` repo (ci-cd, devsecops, rest-api-design, security-auditing, argo, cilium, cloud-api, database-design, talos-os)
- **Output styles**: `output-styles/`
- **Status line**: `statusline-command.sh`
- **Global CLAUDE.md**: User preferences (writable out-of-store symlink)

## Docker Testing

Multi-stage build: Ubuntu 24.04 builder + Debian bookworm-slim runtime.

- Builder: Determinate Nix installer, `home-manager switch`, `nix-collect-garbage`
- Runtime: Only `/nix/store` and user home copied over — no nix-daemon needed
- Auto-detects architecture (`minimal-arm` or `minimal-x86`)
- `USERNAME` build arg (default from docker-compose: `svenlito`)

## Pre-commit Hooks

Installed via `pre-commit install`. Hooks: nixfmt, statix, deadnix, flake-check, hadolint, trailing-whitespace, check-yaml, detect-private-key.

## Critical Pitfalls

1. **`nix.optimise` is nix-darwin only** — never set in `common/default.nix`, only in `systems/aarch64-darwin/`
2. **Nix flakes require git tracking** — `git add` new files before `nixswitch` or builds silently fail
3. **No NixOS support** — no `boot.*`, `services.*`, `virtualisation.*` modules
4. **Platform detection** — use `pkgs.stdenv.isLinux`/`isDarwin` and `lib.mkIf` for conditional config
5. **Cross-platform paths** — use `xdg.configFile` not hardcoded `Library/Application Support/`
6. **ZSH uses `initContent`** not deprecated `initExtra`
7. **State versions rarely change** — `common/versions.nix` controls backward compat, update only after reading migration guides
8. **Imports can't depend on pkgs** — use `lib.mkIf` inside modules, not `lib.optionals` in import lists (causes infinite recursion)
9. **Ghostty is macOS-only** — guarded with `lib.mkIf (!pkgs.stdenv.isLinux)` in `common/ghostty/default.nix`

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
