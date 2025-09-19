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
# Apply generic Linux configuration
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
├── flake.nix              # Main orchestrator - defines all configurations
├── common/                # Shared configuration across platforms
│   ├── default.nix        # Common Nix settings
│   ├── packages.nix       # Package definitions for all systems
│   ├── home-packages.nix  # Home Manager package imports
│   ├── claude-code/       # Claude Code integration with custom commands
│   ├── neovim/           # Neovim configuration
│   ├── tmux/             # Tmux configuration
│   └── zsh/              # Shared ZSH configuration
└── systems/
    ├── aarch64-darwin/    # macOS-specific (nix-darwin)
    └── aarch64-linux/     # Linux-specific (home-manager)
```

### Configuration Flow
1. **flake.nix** - Entry point defining `darwinConfigurations` and `homeConfigurations`
2. **common/** - Imported by all systems for shared settings
3. **systems/{arch}/** - Platform-specific configurations that extend common base
4. **packages.nix** - Centralized package definitions organized by category

## Development Workflow

### Making Configuration Changes
1. Edit configuration files in appropriate directory:
   - `common/` for shared changes
   - `systems/aarch64-darwin/` for macOS-specific
   - `systems/aarch64-linux/` for Linux-specific
2. Apply changes using commands above
3. Commit changes: `git commit -am "description"`

### Package Management
- **Add everywhere**: Edit `common/packages.nix` (corePackages or devPackages lists)
- **macOS system packages**: Edit `common/packages.nix` (darwinSystemPackages list)
- **macOS GUI apps**: Edit `systems/aarch64-darwin/homebrew.nix`
- **Linux-specific packages**: Edit `systems/aarch64-linux/home-linux.nix`

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

### Version Management
- **Terraform**: Managed as regular nixpkgs in Linux configurations
- **Node.js**: Uses nodePackages.pnpm from nixpkgs

### Multi-Environment Support
- **Generic Linux**: Flexible Home Manager configuration for any Linux environment
- **Development Shell**: Available via `nix develop` for working on this configuration
- **Auto-Detection**: Shell aliases automatically detect system type and hostname

## Platform-Specific Notes

### macOS (nix-darwin)
- Manages system preferences via `systems/aarch64-darwin/defaults.nix`
- Dock configuration in `systems/aarch64-darwin/dock.nix`
- Homebrew integration for GUI applications
- SSH configuration for VM connectivity

### Linux (home-manager)
- Docker integration with proper user permissions
- Development-focused package selection
- Cloud integrations (AWS CLI, Kubernetes tools)
- Optimized for remote development workflows

## Security Considerations
- SSH keys managed through 1Password integration
- Tailscale for secure cloud connectivity
- Proper credential management for AWS profiles
- Isolated development environments prevent host contamination

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
The configuration uses a sophisticated import system:

1. **flake.nix**: Orchestrates everything using `mkDarwinSystem` and `mkHomeManagerConfig` functions
2. **common/default.nix**: Base Nix settings imported by all systems
3. **common/home-manager-base.nix**: Home Manager defaults for Linux systems
4. **common/versions.nix**: Centralized state version management to prevent conflicts

### Cross-Platform Module Strategy
- **Shared modules** in `common/` use conditional logic for platform differences
- **Platform modules** in `systems/{arch}/` extend shared configuration
- **Import chains**: flake.nix → systems/{arch} → common → specialized modules

### Performance Optimizations
Built-in performance tuning throughout:
- **Build parallelization**: `max-jobs = "auto"`, `cores = 0`
- **Download optimization**: 256MB buffer, 50 HTTP connections
- **Store optimization**: Automatic optimization, substituter caching
- **RAM disk** (Linux): `/ramdisk` for temporary build artifacts

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
