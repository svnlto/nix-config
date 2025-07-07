# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Commands

### macOS (nix-darwin)
```bash
# Apply system configuration
darwin-rebuild switch --flake ~/.config/nix#macbook

# Update and apply configuration
git pull && darwin-rebuild switch --flake ~/.config/nix#macbook
```

### Development VM (Vagrant)
```bash
# Start VM
vagrant up

# SSH into VM
vagrant ssh

# Apply configuration changes
vagrant provision

# Inside VM: Apply home-manager configuration
nix run home-manager/master -- switch --flake ~/.config/nix#vagrant --impure
```

### Cloud (EC2)
```bash
# Build AMI with Packer
cd packer && packer build -var "aws_profile=dev" aws-ec2.pkr.hcl

# Apply EC2 home-manager configuration
nix run home-manager/master -- switch --flake ~/.config/nix#ec2 --impure
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
│   ├── default.nix        # Common Nix settings and packages
│   ├── home-packages.nix  # Shared packages for all systems
│   ├── claude-code/       # Claude Code integration with custom commands
│   └── zsh/              # Shared ZSH configuration
├── systems/
│   ├── aarch64-darwin/    # macOS-specific (nix-darwin)
│   └── aarch64-linux/     # Linux-specific (home-manager)
└── overlays/              # Custom package overlays (tfenv, etc.)
```

### Configuration Flow
1. **flake.nix** - Entry point defining `darwinConfigurations` and `homeConfigurations`
2. **common/** - Imported by all systems for shared settings
3. **systems/{arch}/** - Platform-specific configurations that extend common base
4. **overlays/** - Custom packages not in nixpkgs

## Development Workflow

### Making Configuration Changes
1. Edit configuration files in appropriate directory:
   - `common/` for shared changes
   - `systems/aarch64-darwin/` for macOS-specific
   - `systems/aarch64-linux/` for Linux-specific
2. Apply changes using commands above
3. Commit changes: `git commit -am "description"`

### Package Management
- **Add everywhere**: Edit `common/home-packages.nix`
- **macOS system packages**: Edit `systems/aarch64-darwin/default.nix`
- **macOS GUI apps**: Edit `systems/aarch64-darwin/homebrew.nix`
- **Linux packages**: Edit `systems/aarch64-linux/vagrant.nix` or `ec2.nix`

### Adding New Hosts
Create new configuration in `flake.nix`:
```nix
"hostname" = darwinSystem {
  hostname = "hostname";
  username = "username";
  # Additional config...
};
```

## Special Features

### Claude Code Integration
Located in `common/claude-code/`, this provides:
- **Custom commands**: Linear integration, conventional commits, breakdown command
- **Sophisticated hooks**: Automated linting and quality checks
- **Modular structure**: Combines local and remote commands via symlinkJoin

### Version Management
- **tfenv**: Terraform version management via custom overlay
- **Custom overlays**: Pattern for adding tools not in nixpkgs

### Multi-Environment Support
- **Vagrant**: Local development VM with UTM integration
- **EC2**: Cloud development with Packer AMI building
- **Tailscale**: Secure connectivity for cloud instances

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