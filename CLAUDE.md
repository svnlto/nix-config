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
├── systems/
│   ├── aarch64-darwin/    # macOS-specific (nix-darwin)
│   └── aarch64-linux/     # Linux-specific (home-manager)
└── packer/               # Cloud image templates (Packer)
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

## Code Quality Standards

**6 Golden Rules for Clean Code** (Neo Kim):
1. **SOC** - Separation of concerns
2. **DYC** - Document your code
3. **DRY** - Don't repeat yourself
4. **KISS** - Keep it simple stupid
5. **TDD** - Test driven development
6. **YAGNI** - You ain't gonna need it
