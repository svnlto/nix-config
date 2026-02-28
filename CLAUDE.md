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
│   │   └── wallpapers/          # Wallpaper images for macOS desktop
│   ├── claude-code/             # Claude Code integration with custom commands
│   ├── neovim/                  # Neovim configuration
│   ├── tmux/                    # Tmux configuration
│   ├── zsh/
│   │   ├── shared.nix           # Shared ZSH config (aliases, functions, tools)
│   │   └── default.omp.json     # Oh My Posh theme
│   ├── lazygit/                 # Lazygit configuration (cross-platform via xdg)
│   ├── ghostty/                 # Ghostty terminal configuration
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
   - `common/profiles/` for optional profiles
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
**IMPORTANT**: Platform-specific packages must be separated:

- macOS-only packages (like `reattach-to-user-namespace`) go in `darwinPackages` and are imported via `systems/aarch64-darwin/home.nix`
- Never put macOS-only packages in shared `corePackages` or `devPackages` or they'll break Linux builds
- Common development tools (curl, wget, htop, docker-compose) belong in `devPackages`, not platform-specific configs

### Configuration Profiles

**Profile Architecture**: Optional configurations that extend the base system without polluting minimal environments.

Profiles are opt-in via `extraModules` in `flake.nix`:

```nix
# Minimal configuration (default)
linux = mkHomeManagerConfig {
  username = "user";
};

# Extended configuration with custom profile
custom = mkHomeManagerConfig {
  username = "user";
  extraModules = [ ./common/profiles/your-profile.nix ];
};
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

### Creating Custom Profiles

Profiles allow you to extend configurations without polluting minimal environments:

**1. Create your profile file:**

```nix
# common/profiles/your-profile.nix
{ pkgs, lib, ... }:

# Add platform assertion if needed (optional)
assert lib.assertMsg pkgs.stdenv.isLinux
  "This profile is Linux-only. Remove from macOS configurations.";

{
  # Add your packages
  home.packages = with pkgs; [
    # your-package-1
    # your-package-2
  ];

  # Add your program configurations
  programs.yourProgram = {
    enable = true;
    # ... settings
  };

  # Add any other Home Manager options
  home.sessionVariables = {
    YOUR_VAR = "value";
  };
}
```

**2. Add profile to flake.nix:**

```nix
# In flake.nix homeConfigurations section
yourconfig = mkHomeManagerConfig {
  username = "youruser";
  extraModules = [ ./common/profiles/your-profile.nix ];
};

# Or combine multiple profiles
advanced = mkHomeManagerConfig {
  username = "youruser";
  extraModules = [
    ./common/profiles/your-profile.nix
    ./common/profiles/another-profile.nix
  ];
};
```

**3. Apply the configuration:**

```bash
# For the new configuration
home-manager switch --flake ~/.config/nix#yourconfig

# Or update your existing config to include it
vim ~/.config/nix/flake.nix  # Add to extraModules
nixswitch  # or hmswitch
```

**Profile Best Practices:**

- ✅ Use platform assertions (`pkgs.stdenv.isLinux` / `isDarwin`)
- ✅ Document what the profile provides at the top
- ✅ Group related functionality (desktop, development, media, etc.)
- ✅ Make profiles optional - don't require them in base config
- ✅ Test profile in isolation before combining with others
- ❌ Don't add platform-specific code to cross-platform profiles
- ❌ Don't create circular dependencies between profiles

**Example Use Cases:**

- **Gaming profile**: Steam, gaming tools, performance tweaks
- **Work profile**: VPN configs, work-specific tools, credentials
- **Media profile**: Video/audio editing tools, codecs
- **Server profile**: Monitoring tools, server-specific settings
- **Development profile**: Language-specific toolchains, IDEs

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
- **Profile-based configs**: Optional modules for additional tools, server configs, etc.
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
- **Profile system** - opt-in additional tools and configurations
- Docker integration (docker-compose package)
- Linux-specific packages: htop, neofetch, curl, wget
- Imports both `common/home-manager-base.nix` and `common/default.nix`
- Auto-optimise-store enabled (better suited for Linux than macOS)

**Available Configurations**:

- `#minimal-x86` / `#minimal-arm` - Minimal (Docker/containers)

## Backup & Recovery Strategy

### Automatic Backups

Home Manager automatically creates backups when replacing existing configuration files:

- **Location**: Original file path with `.backup` extension
  - Example: `~/.zshrc.backup`, `~/.config/nvim/init.lua.backup`
- **When created**: During `nixswitch` or `home-manager switch` when files would be overwritten
- **Retention**: Not automatically cleaned up - manual management required
- **Restore**: Simply move the backup file back to original location

```bash
# Restore a backed-up file
mv ~/.zshrc.backup ~/.zshrc

# Find all backup files
find ~/ -name "*.backup" -type f

# List backup files with modification times
find ~/ -name "*.backup" -type f -exec ls -lh {} \;

# Remove old backups (older than 30 days)
find ~/ -name "*.backup" -mtime +30 -delete

# Dry run to see what would be deleted
find ~/ -name "*.backup" -mtime +30 -print
```

### Generation-Based Recovery

Nix configurations are **versioned automatically** via generations:

**macOS (nix-darwin):**
```bash
# List all system generations
sudo darwin-rebuild --list-generations

# Rollback to previous generation
sudo darwin-rebuild rollback

# Boot into specific generation (survives reboot)
sudo darwin-rebuild switch --rollback
```

**Linux (home-manager):**
```bash
# List generations with activation paths
home-manager generations

# Activate specific generation
/nix/store/HASH-home-manager-generation/activate

# Rollback to previous
home-manager --rollback
```

### Cleanup Recommendations

**Safe cleanup strategy:**
```bash
# Keep recent generations (last 30 days), clean old ones
nix-collect-garbage --delete-older-than 30d

# Or use the quick cleanup alias
nix-clean  # Keeps last 7 days

# Deep cleanup (removes ALL old generations)
nix-clean-deep  # Use with caution!
```

**IMPORTANT**: Always keep at least one or two recent generations as a safety net before running deep cleanup.

### Disaster Recovery

If a configuration breaks your system:

1. **Immediate rollback**: Use generation rollback (see above)
2. **Restore from backup**: Use `.backup` files for specific configs
3. **Git history**: All changes tracked in this repository
   ```bash
   git log --oneline  # See recent changes
   git diff HEAD~1    # Compare with previous commit
   git checkout HEAD~1 -- path/to/file  # Restore specific file
   ```
4. **Clean rebuild**: Clone fresh repository and rebuild

## Security Considerations

- SSH keys managed through 1Password integration
- Tailscale for secure cloud connectivity
- Proper credential management for AWS profiles
- Isolated development environments prevent host contamination

## Testing with Docker

Test the Nix configuration in a clean environment:

```bash
# Build the image
just build

# Run interactively (drops into zsh as svenlito)
just dev
```

**Docker Setup Details:**

- Multi-stage build: Ubuntu 24.04 + Determinate Nix installer
- Stage 1 (builder): installs Nix, runs `home-manager switch`, discarded after build
- Stage 2 (runtime): slim Ubuntu with only `/nix/store` and user home copied over
- Auto-detects architecture (`minimal-arm` or `minimal-x86`)
- All tools (tmux, neovim, zsh, oh-my-posh) pre-configured and ready to test
- No `nix-daemon` needed at runtime — packages are pre-built in the store

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
nix eval .#homeConfigurations.minimal-x86.activationPackage
nix eval .#homeConfigurations.minimal-arm.activationPackage
```

### Version Management

This configuration uses centralized version management in `common/versions.nix`.

**IMPORTANT: State versions should RARELY be updated!**

```bash
# Check current versions
cat common/versions.nix

# Check what version your system is using
nix eval .#darwinConfigurations.rick.system.stateVersion    # macOS
home-manager --version                                       # Linux
```

**When to update state versions:**
- ✅ When release notes explicitly recommend updating
- ✅ After reading and understanding migration guides
- ❌ NEVER "just because" a new version exists
- ❌ NEVER to fix unrelated build issues

State versions control backward compatibility. Updating them can **break your system** by changing default behaviors.

**Updating nixpkgs (safe and recommended):**
```bash
# Update all flake inputs
nix flake update

# Update specific input only
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# Test before committing
nixswitch --show-trace

# Commit if successful
git add flake.lock
git commit -m "chore: update flake inputs"
```

**Updating state versions (rare, use caution):**
```bash
# Read release notes first!
# Visit: https://github.com/nix-community/home-manager/releases

# Edit versions file ONLY after reading migration guide
vim common/versions.nix

# Test thoroughly before committing
nixswitch --show-trace

# Commit only if everything works
git add common/versions.nix
git commit -m "feat: update state version to XX.YY (breaking change)"
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

## macOS (nix-darwin)
# Quick rollback to previous generation
sudo darwin-rebuild rollback

# Or use --rollback flag
sudo darwin-rebuild --rollback

# List all available generations
sudo darwin-rebuild --list-generations

# Switch to specific generation (replace N with generation number)
sudo nix-env --switch-generation N --profile /nix/var/nix/profiles/system

## Linux (home-manager)
# List available generations with their paths
home-manager generations

# Activate specific generation (copy path from above command)
/nix/store/HASH-home-manager-generation/activate

# Or rollback to previous generation
home-manager --rollback

# List generations with details
nix-env --list-generations --profile ~/.local/state/nix/profiles/home-manager

# Switch to specific generation number
nix-env --switch-generation N --profile ~/.local/state/nix/profiles/home-manager
home-manager switch  # Re-activate after switching
```

## Advanced Architecture Details

### Module Resolution System

The configuration uses a layered import system that eliminates duplication:

1. **flake.nix**: Orchestrates everything using `mkDarwinSystem` and `mkHomeManagerConfig` functions
2. **common/home-manager-base.nix**:
   - Imports shared modules: `home-packages.nix`, `claude-code/`, `programs/`
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
   - **Linux**: homeDirectory + nix settings + platform aliases (hmswitch, hm-user)

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
