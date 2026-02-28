# Cross-Platform Nix Configuration

Declarative development environment for macOS (nix-darwin) and Linux (home-manager). ARM64-first, optimized for Apple Silicon and ARM cloud instances.

## Quick Start

### macOS (Apple Silicon)

```bash
sh <(curl -L https://nixos.org/nix/install)
git clone https://github.com/svnlto/nix-config.git ~/.config/nix
cd ~/.config/nix
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)

# After first install, the nixswitch alias is available:
nixswitch
```

### Linux (Server/Container)

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
git clone https://github.com/svnlto/nix-config.git ~/.config/nix
cd ~/.config/nix
nix run home-manager -- switch --flake .#minimal-x86   # x86_64
nix run home-manager -- switch --flake .#minimal-arm   # ARM64

# After first install, the hmswitch alias is available:
hmswitch
```

### Docker

```bash
just build    # Build image (multi-stage: Ubuntu builder + Debian slim runtime)
just dev      # Drop into configured zsh shell
```

## Commands

```bash
nixswitch                # Apply config (auto-detects platform)
hmswitch                 # Apply Home Manager config (Linux)
nix develop              # Dev shell with nixfmt, statix, deadnix, nil
nix flake check          # Validate configuration
nixswitch --show-trace   # Debug build failures
flake-init               # Scaffold new project (defaults to minimal template)
flake-init <template>    # Scaffold with a specific template
```

### flake-init

Scaffolds a new project directory using Nix flake templates stored in this repo. Uses `nix flake init` under the hood.

```bash
cd ~/Projects/new-thing
flake-init          # creates flake.nix, .envrc, .gitignore, .pre-commit-config.yaml
direnv allow        # activate the devShell
```

**Available templates:**

| Template | Description |
|----------|-------------|
| `minimal` (default) | devShell with pre-commit, direnv, gitignore |

Templates live in `templates/` and are registered as flake outputs.

## Structure

```
flake.nix                    # Entry point — darwinConfigurations + homeConfigurations
common/
  packages.nix               # All package definitions (core, dev, darwin)
  home-manager-base.nix      # Shared HM config base
  programs/default.nix       # Shared programs (direnv, gh, zsh)
  claude-code/               # Claude Code settings, hooks, commands, skills
  neovim/ tmux/ zsh/ git/    # Tool configurations
  ghostty/ lazygit/          # Terminal configs (ghostty macOS-only)
  profiles/                  # Optional opt-in modules
systems/
  aarch64-darwin/            # macOS: homebrew, defaults, dock
  aarch64-linux/             # Linux: minimal container config
```

## Available Configurations

| Config | Target |
|--------|--------|
| `#rick` | macOS (auto-detected via hostname) |
| `#minimal-x86` | x86_64 Linux (Docker, servers) |
| `#minimal-arm` | ARM64 Linux (EC2, cloud) |

## Adding a Host

```nix
# flake.nix — macOS
"hostname" = mkDarwinSystem {
  hostname = "hostname";
  username = "username";
};

# flake.nix — Linux
"config-name" = mkHomeManagerConfig {
  username = "username";
  extraModules = [ ./common/profiles/optional.nix ];  # optional
};
```

## Key Design Decisions

- **Shared-first**: All cross-platform config lives in `common/`, platform dirs are minimal
- **Hybrid package management**: Nix for CLI tools, Homebrew for macOS GUI apps
- **Catppuccin Mocha**: Consistent theme across Ghostty, Neovim, tmux, fzf
- **Pre-commit hooks**: nixfmt, statix, deadnix, flake-check, hadolint
- **1Password SSH**: Agent integration for key management
- **Profiles**: Opt-in modules that extend without polluting the base config

## Maintenance

```bash
nix flake update             # Update all inputs
nix-clean                    # Garbage collect (keeps 7 days)
sudo darwin-rebuild rollback # macOS rollback
home-manager --rollback      # Linux rollback
```

See [CLAUDE.md](./CLAUDE.md) for detailed development guidance.
