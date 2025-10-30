# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Commands

### macOS (nix-darwin)

```bash
# Apply system configuration (auto-detects hostname)
nixswitch

# Or manually specify hostname
sudo darwin-rebuild switch --flake ~/.config/nix#$(scutil --get LocalHostName)

# Update and apply configuration
git pull && nixswitch
```

### Linux (Home Manager)

```bash
# Apply generic Linux configuration (minimal - for Docker/containers)
hmswitch

# Apply user-specific configuration (if exists)
hm-user

# Apply desktop configuration with Hyprland (full dev environment + GUI apps)
home-manager switch --flake ~/.config/nix#desktop

# Manual commands
home-manager switch --flake ~/.config/nix#linux
home-manager switch --flake ~/.config/nix#$(whoami)  # user-specific

# Update and apply configuration
git pull && hmswitch
```

## Architecture Overview

This is a **cross-platform Nix configuration** managing both macOS hosts and Linux development environments. The architecture follows a modular, hybrid approach:

### Key Design Principles

- **Host-VM separation**: Clean macOS host with isolated Linux development environment
- **ARM64-first**: Optimized for Apple Silicon and ARM cloud instances
- **Shared configuration**: Common settings abstracted into reusable modules
- **Hybrid package management**: Nix for development tools, Homebrew for macOS GUI apps

### Directory Structure

```
├── flake.nix                    # Main orchestrator - defines all configurations
├── common/                      # Shared configuration across platforms
│   ├── default.nix              # Common Nix settings (performance, experimental features)
│   ├── home-manager-base.nix    # Shared Home Manager configuration base
│   ├── programs/default.nix     # Shared program configs (direnv, gh, zsh)
│   ├── packages.nix             # Package definitions for all systems
│   ├── home-packages.nix        # Home Manager package imports
│   ├── git/                     # Unified cross-platform git configuration
│   ├── profiles/                # Optional configuration profiles
│   │   └── hyprland.nix         # Hyprland desktop setup (compositor + dev tools + apps)
│   ├── claude-code/             # Claude Code integration with custom commands
│   ├── neovim/                  # Neovim configuration
│   ├── tmux/                    # Tmux configuration
│   ├── zsh/
│   │   ├── shared.nix           # Shared ZSH config (aliases, functions, tools)
│   │   └── default.omp.json     # Oh My Posh theme
│   ├── lazygit/                 # Lazygit configuration (cross-platform via xdg)
│   ├── ghostty/                 # Ghostty terminal configuration
│   └── scripts/                 # Custom shell scripts
└── systems/
    ├── aarch64-darwin/          # macOS-specific (nix-darwin)
    │   ├── home.nix             # Home Manager config - imports common modules
    │   ├── homebrew.nix         # Homebrew cask definitions
    │   ├── defaults.nix         # macOS system preferences
    │   └── dock.nix             # Dock configuration
    └── aarch64-linux/           # Linux-specific (home-manager)
        └── default.nix          # Home Manager config for Linux
```

### Configuration Flow

1. **flake.nix** - Entry point defining `darwinConfigurations` and `homeConfigurations`
2. **common/home-manager-base.nix** - Imports shared modules (home-packages, claude-code, programs, scripts)
3. **common/programs/default.nix** - Centralized program configurations (direnv, gh, zsh base)
4. **common/default.nix** - Nix settings shared across platforms
5. **systems/{arch}/** - Platform-specific configurations (minimal, only truly platform-specific settings)
6. **packages.nix** - Centralized package definitions organized by category

### Recent Architectural Changes (2025)

**Major refactoring eliminated 479+ lines of duplicate configuration:**

- Created `common/home-manager-base.nix` to centralize Home Manager settings
- Created `common/programs/default.nix` for shared program configurations
- **Unified git configuration** in `common/git/` with platform detection for SSH signing
- **Made lazygit cross-platform** via `xdg.configFile` instead of hardcoded macOS paths
- **Removed all NixOS-specific code** (this config only supports nix-darwin and home-manager)
- Reduced macOS config from 127 lines to minimal platform-specific settings
- Platform configs now contain ONLY platform-specific settings
- Replaced atuin with fzf for shell history (simpler, local-only)

## Development Workflow

### Making Configuration Changes

1. Edit configuration files in appropriate directory:
   - `common/` for shared changes
   - `common/profiles/` for optional profiles (Wayland, etc.)
   - `systems/aarch64-darwin/` for macOS-specific
   - `systems/aarch64-linux/` for Linux-specific
2. Apply changes using commands above
3. Commit changes: `git commit -am "description"`

### Package Management

- **Add everywhere**: Edit `common/packages.nix`:
  - `corePackages` - Essential CLI tools (oh-my-posh, eza, zoxide, bat, etc.)
  - `devPackages` - Development tools (gh, lazygit, docker-compose, htop, curl, wget, etc.)
- **macOS-only packages**: Edit `common/packages.nix` (darwinPackages list) - for packages like `reattach-to-user-namespace`
- **macOS system packages**: Edit `common/packages.nix` (darwinSystemPackages list)
- **macOS GUI apps**: Edit `systems/aarch64-darwin/homebrew.nix`
- **Profile-specific packages**: Edit `common/profiles/hyprland.nix` for Linux desktop apps

**IMPORTANT**: Platform-specific packages must be separated:

- macOS-only packages (like `reattach-to-user-namespace`) go in `darwinPackages` and are imported via `systems/aarch64-darwin/home.nix`
- Profile-specific packages (like Hyprland/Wayland tools) go in `common/profiles/hyprland.nix` and are opt-in via `extraModules`
- Never put macOS-only packages in shared `corePackages` or `devPackages` or they'll break Linux builds
- Common development tools (curl, wget, htop, docker-compose) belong in `devPackages`, not platform-specific configs

### Configuration Profiles

**Profile Architecture**: Optional configurations that extend the base system without polluting minimal environments.

**Available Profiles**:

- `common/profiles/hyprland.nix` - Hyprland desktop environment (full-featured, Linux only)

**hyprland.nix includes**:

- **Hyprland** - Modern Wayland compositor with animations
- **Dev tools** - mise, lazydocker, btop, Docker, databases
- **Desktop apps** - Obsidian, Signal, Chromium, LocalSend
- **Media** - mpv, Spotify (OBS/Kdenlive commented out)
- **Theme** - Catppuccin Mocha throughout
- **Keybindings** - Vi-style (Super+h/j/k/l), Super key modifier

**Using Profiles**:
Profiles are opt-in via `extraModules` in `flake.nix`:

```nix
# Minimal configuration (default)
linux = mkHomeManagerConfig {
  username = "user";
};

# Desktop configuration with Hyprland
desktop = mkHomeManagerConfig {
  username = "svenlito";
  extraModules = [ ./common/profiles/hyprland.nix ];
};
```

**Customizing hyprland.nix**:
Edit the profile and comment out packages you don't want:

```nix
# Media (comment out what you don't want)
mpv
spotify
# obs-studio  # ← Already commented
# kdenlive    # ← Video editing
# pinta       # ← Image editing
```

**Benefits**:

- Default stays minimal (Docker/containers unaffected)
- Explicit opt-in for additional functionality
- Easy to compose multiple profiles
- Clear separation of concerns

### Adding New Hosts

Create new configuration in `flake.nix`:

```nix
# For macOS
"hostname" = mkDarwinSystem {
  hostname = "hostname";
  username = "username";
};

# For Linux
"username" = mkHomeManagerConfig {
  username = "username";
};
```

## Special Features

### Claude Code Integration

Located in `common/claude-code/`, this provides:

- **Custom commands**: Linear integration, conventional commits, breakdown command
- **Sophisticated hooks**: Automated linting and quality checks
- **Modular structure**: Combines local and remote commands via symlinkJoin

### Shell Configuration

- **History Search**: fzf with Catppuccin Mocha theme (`source <(fzf --zsh)`)
- **Directory Navigation**: zoxide aliased to `cd` for smart directory jumping
- **Prompt**: Oh My Posh with custom theme
- **Completions**: Carapace for 300+ CLI tools

### Tmux Session Management

Located in `common/tmux/` and `common/tmuxinator/`:

- **Tmux Plugin Manager (TPM)**: Manages plugins (resurrect, continuum, sessionx)
- **tmux-sessionx**: fzf-powered session switcher with zoxide integration
  - Keybinding: `prefix + o` opens fuzzy session picker
  - Integrated with zoxide for smart directory matching
  - Shows tmux sessions + zoxide directories + tmuxinator configs
- **Tmuxinator**: Project session manager with predefined layouts
  - Default session: config, homelab, kubestronaut windows
  - Pricelytics session: app and infra windows (separate session)
  - Layout: nvim left (70%), claude + terminal right stacked (60/40)
  - Aliases: `mux`, `muxn`, `muxs`, `muxl`
  - Start with: `muxs default` or `muxs pricelytics`

### Terminal & UI Theming

- **Ghostty terminal**: 0.85 opacity for subtle transparency
- **Neovim**: Catppuccin Mocha theme with `transparent_background = true`
- **Tmux**: Catppuccin Mocha status bar, custom 2-pane layout support
- **Consistent theme**: Catppuccin Mocha across all tools (terminal, editor, tmux, fzf)

### Version Management

- **Terraform**: Managed as regular nixpkgs in Linux configurations
- **Node.js**: Uses nodePackages.pnpm from nixpkgs

### Multi-Environment Support

- **Generic Linux**: Flexible Home Manager configuration for any Linux environment (minimal by default)
- **Profile-based configs**: Optional modules for desktop environments (Wayland/Sway), server tools, etc.
- **Development Shell**: Available via `nix develop` for working on this configuration
- **Auto-Detection**: Shell aliases automatically detect system type and hostname

## Platform-Specific Notes

### macOS (nix-darwin)

- Manages system preferences via `systems/aarch64-darwin/defaults.nix`
- Dock configuration in `systems/aarch64-darwin/dock.nix`
- Homebrew integration for GUI applications
- SSH configuration for VM connectivity

### Linux (home-manager)

- **Minimal by default** - base configuration for Docker/containers
- **Profile system** - opt-in desktop environments (Wayland/Sway) or additional tools
- Docker integration (docker-compose package)
- Linux-specific packages: htop, neofetch, curl, wget
- Imports both `common/home-manager-base.nix` and `common/default.nix`
- Auto-optimise-store enabled (better suited for Linux than macOS)

**Available Configurations**:

- `#minimal-x86` / `#minimal-arm` - Minimal (Docker/containers)
- `#desktop-x86` / `#desktop-arm` - Full desktop environment (Hyprland, dev tools, GUI apps)

## Security Considerations

- SSH keys managed through 1Password integration
- Tailscale for secure cloud connectivity
- Proper credential management for AWS profiles
- Isolated development environments prevent host contamination

## Testing with Docker

Test the Nix configuration in a clean Ubuntu environment:

```bash
# Build the Docker image
docker build -t nix-config-test .

# Run interactively
docker run -it --rm \
  -v $(pwd):/home/ubuntu/workspace \
  -w /home/ubuntu \
  nix-config-test

# Or use docker-compose (simpler)
docker-compose run --rm nix-dev
```

**Docker Setup Details:**

- Ubuntu 24.04 base with pinned SHA256
- Pinned package versions (curl, git, sudo, xz-utils, ca-certificates, zsh)
- Pinned Nix version: 2.24.10
- Pinned home-manager: release-24.05
- Applies `homeConfigurations.ubuntu` automatically during build
- All tools (tmux, neovim, zsh) pre-configured and ready to test

## Configuration Development Commands

### Nix Development Tools (via `nix develop`)

```bash
# Enter development shell with Nix tools
nix develop

# Available tools in development shell:
nixfmt-classic     # Format Nix code
statix            # Lint Nix code for common issues
deadnix           # Find dead/unused Nix code
nil               # Nix LSP for editor integration
```

### Configuration Validation

```bash
# Check flake syntax and evaluation
nix flake check

# Validate specific configuration
nix eval .#darwinConfigurations.rick.system
nix eval .#homeConfigurations.linux.activationPackage
nix eval .#homeConfigurations.ubuntu.activationPackage
```

### Troubleshooting Commands

```bash
# Debug build issues
nixswitch --show-trace
hmswitch --show-trace

# Check system status
nix-status                    # Detailed status (alias)
darwin-rebuild --list-generations    # Show previous builds

# Emergency rollback
sudo darwin-rebuild rollback        # macOS
home-manager generations            # Linux - shows available generations
```

## Advanced Architecture Details

### Module Resolution System

The configuration uses a layered import system that eliminates duplication:

1. **flake.nix**: Orchestrates everything using `mkDarwinSystem` and `mkHomeManagerConfig` functions
2. **common/home-manager-base.nix**:
   - Imports shared modules: `home-packages.nix`, `claude-code/`, `programs/`, `scripts/`
   - Sets base home configuration (username, stateVersion)
   - Exports session variables and paths from `zsh/shared.nix`
   - Configures Oh My Posh theme
3. **common/programs/default.nix**: Centralized program configurations
   - `programs.direnv` - Development environment management
   - `programs.gh` - GitHub CLI settings (editor: nvim, protocol: ssh)
   - `programs.zsh` - Base ZSH with completions, history, oh-my-zsh
4. **common/default.nix**: Nix settings shared across platforms (performance tuning, experimental features)
5. **systems/{arch}/home.nix**: Platform-specific ONLY
   - **macOS**: homeDirectory + platform-specific aliases (nixswitch, darwin-rebuild)
   - **Linux**: homeDirectory + nix settings + platform aliases (hmswitch, hm-user) + worktree manager

### Cross-Platform Module Strategy

- **Shared modules** in `common/` contain ALL cross-platform configuration
- **Platform modules** in `systems/{arch}/` are minimal - only truly platform-specific settings
- **Import chains**:
  - flake.nix → systems/{arch}/home.nix → common/home-manager-base.nix → specialized modules
  - systems/aarch64-linux also imports common/default.nix for nix settings
- **DRY principle**: Zero duplication between platforms - shared config centralized once

### Performance Optimizations

Built-in performance tuning throughout:

- **Build parallelization**: `max-jobs = "auto"`, `cores = 0`
- **Download optimization**: 256MB buffer, 50 HTTP connections
- **Store optimization**: `nix.optimise.automatic = true` on macOS only (in `systems/aarch64-darwin/default.nix`)
  - **CRITICAL**: Do NOT set `nix.optimise` in `common/default.nix` - it only works with nix-darwin, not home-manager
  - Linux uses standard nix settings without `optimise.automatic`

### State Management Architecture

- **Version pinning**: `common/versions.nix` prevents Home Manager version conflicts
- **Hostname detection**: Auto-detects via `scutil --get LocalHostName` (macOS)
- **Username validation**: Runtime validation with helpful error messages
- **Backup management**: `.backup` extension for replaced configs

## Critical Implementation Patterns

### Module Import Best Practices

```nix
# ✅ Correct: Import with proper parameter passing
./common/module.nix

# ✅ Correct: Platform-specific imports
./systems/${system}/specific.nix

# ❌ Avoid: Direct path strings without validation
"/some/hardcoded/path"
```

### Configuration Override Hierarchy

1. **flake.nix**: System-level overrides
2. **systems/{arch}/default.nix**: Platform-specific overrides
3. **common/**: Shared defaults
4. **Individual modules**: Specific functionality

### ZSH Configuration Pattern

**IMPORTANT**: ZSH configuration uses `initContent` (not deprecated `initExtra`):

- **common/programs/default.nix** sets base `programs.zsh.initContent`
- **Platform configs** can extend with their own `programs.zsh.initContent` for platform-specific init
- **Platform aliases** set via `programs.zsh.shellAliases` merge with shared aliases from `common/zsh/shared.nix`
- Shared ZSH configuration in `common/zsh/shared.nix` exports:
  - `aliases` - Common shell aliases
  - `sessionVariables` - Environment variables (DIRENV_LOG_FORMAT, NPM_CONFIG_PREFIX, FZF_DEFAULT_OPTS, etc.)
  - `sessionPath` - PATH additions
  - `historyConfig` - ZSH history settings
  - `autosuggestionConfig` - Autosuggestion settings
  - `options` - ZSH options (setopt commands)
  - `completion` - Completion styling
  - `keybindings` - Key bindings
  - `historyOptions` - History-specific options
  - `tools` - Tool initialization (fzf, zoxide, oh-my-posh, carapace)

### Error Handling Patterns

The codebase implements defensive configuration:

- **Validation functions**: `validateUsername` with helpful error messages
- **Fallback options**: `fallback = true` in Nix settings
- **Graceful degradation**: Optional features with null checks

## Security Architecture

### SSH Key Management

- **1Password integration**: SSH agent socket configuration for seamless key access
- **Per-platform paths**: macOS uses Library/Group Containers path
- **Automatic setup**: System activation scripts configure SSH properly

### Credential Isolation

- **Home Manager**: User-level secrets and configurations
- **System-level**: Only essential system packages and settings
- **Cloud integration**: AWS profiles, Tailscale for secure connectivity

## Code Quality Standards

**6 Golden Rules for Clean Code** (Neo Kim):

1. **SOC** - Separation of concerns
2. **DYC** - Document your code
3. **DRY** - Don't repeat yourself
4. **KISS** - Keep it simple stupid
5. **TDD** - Test driven development
6. **YAGNI** - You ain't gonna need it

### Nix-Specific Quality Guidelines

- **Pure functions**: All configuration functions should be deterministic
- **Explicit dependencies**: Always declare inputs explicitly
- **Modular design**: Each .nix file should have single responsibility
- **Documentation**: Comment complex expressions and business logic

### Common Pitfalls to Avoid

1. **Platform-specific Nix options in shared configs**
   - ❌ Setting `nix.optimise` in `common/default.nix` breaks home-manager
   - ✅ Set `nix.optimise.automatic` only in `systems/aarch64-darwin/default.nix`

2. **macOS-only packages in shared package lists**
   - ❌ `reattach-to-user-namespace` in `devPackages` breaks Linux builds
   - ✅ Create `darwinPackages` list and import only in macOS config

3. **NixOS-specific code**
   - ❌ This config does NOT support NixOS (no `nixosConfigurations`)
   - ✅ Only nix-darwin (macOS) and standalone home-manager (Linux) are supported
   - ❌ Don't add `boot.*`, `services.*`, `virtualisation.*`, or other NixOS modules

4. **Git tracking required for Nix flakes**
   - Nix flakes only include files tracked by Git
   - Stage new files with `git add` before running `nixswitch` or builds will fail
   - The error "file not found" often means the file isn't tracked by Git

5. **Platform detection for cross-platform modules**
   - Use `pkgs.stdenv.isLinux` or `pkgs.stdenv.isDarwin` for platform-specific config
   - Use `lib.optionalAttrs` to conditionally include settings
   - Example: `common/git/default.nix` enables SSH signing only on Linux

6. **Cross-platform file paths**
   - ❌ Don't hardcode `Library/Application Support/` (macOS-specific)
   - ✅ Use `xdg.configFile` which resolves correctly on both platforms
   - macOS: `~/Library/Application Support/app/config.yml`
   - Linux: `~/.config/app/config.yml`

7. **Tmux layout strings**
   - Tmux layout strings are terminal-size specific (e.g., `362x77`)
   - To capture current layout: `tmux display-message -p '#{window_layout}'`
   - Layouts will adapt to different terminal sizes but proportions may vary
   - For tmuxinator, use captured layout strings from actual working layouts
