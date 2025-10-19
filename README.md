# 🏠 Cross-Platform Nix Configuration

> A comprehensive, declarative development environment for macOS and Linux with
integrated AI tooling

This configuration provides a unified development setup across Apple Silicon Macs
and ARM64 Linux environments, featuring seamless package management, shell
customization, and Claude Code integration for enhanced productivity.

## ✨ What's Included

### 🛠️ Development Tools

- **Git & GitHub CLI** - Version control with seamless GitHub integration
- **Neovim** - Modern Vim with LazyVim configuration and LSP support
- **tmux** - Terminal multiplexer with custom configuration
- **Ripgrep, Ack, Bat** - Enhanced search and file viewing tools
- **Direnv** - Per-directory environment management
- **Docker & Docker Compose** - Containerization support (Linux)

### 🖥️ Terminal & Shell

- **ZSH** - Feature-rich shell with Oh My Posh theming
- **Zoxide** - Smart directory navigation
- **Eza** - Modern `ls` replacement with colors and icons
- **Carapace** - Universal shell completion for CLI tools
- **fzf** - Interactive fuzzy finder for command line
- **gh-dash** - GitHub CLI dashboard for PRs and issues (alias: `ghd`)

### 🎨 macOS Applications (via Homebrew)

- **Productivity**: Raycast, Notion Calendar, SuperWhisper
- **Development**: Orbstack, Ghostty terminal
- **Security**: 1Password, 1Password CLI
- **Communication**: Linear, Slack, Claude desktop
- **Media**: Spotify, VLC

### 🤖 AI Integration

- **Claude Code** - Advanced AI coding assistant with custom commands
- **Linear Commands** - Project management integration
- **Custom Hooks** - Automated linting and quality checks
- **MCP Servers** - Extended AI capabilities

### ☁️ Cloud & Infrastructure

- **Tailscale** - Secure networking across devices
- **AWS CLI & Tools** - Cloud development support
- **SSH Configuration** - 1Password integration for seamless key management
- **Kubernetes Tools** - Container orchestration support

## 🚀 Installation

### macOS (Apple Silicon)

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install)

# Clone and apply
git clone https://github.com/svnlto/nix-config.git ~/.config/nix
cd ~/.config/nix
nixswitch
```

### Linux Desktop (x86_64 or ARM64)

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Clone and apply (first time - specify architecture)
git clone https://github.com/svnlto/nix-config.git ~/.config/nix
cd ~/.config/nix
home-manager switch --flake .#desktop-x86   # x86_64 (Intel/AMD)
# OR
home-manager switch --flake .#desktop-arm   # ARM64

# After first install, auto-detects architecture:
nixswitch
```

### Linux Server/Container (minimal)

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Clone and apply (first time)
git clone https://github.com/svnlto/nix-config.git ~/.config/nix
cd ~/.config/nix
home-manager switch --flake .#minimal-x86   # x86_64
# OR
home-manager switch --flake .#minimal-arm   # ARM64 (EC2, DevPods)

# After first install:
nixswitch
```

## 📁 Configuration Management

### Architecture Overview

```
├── flake.nix              # 🎯 Main orchestrator - all configurations
├── common/                # 🔄 Shared across platforms
│   ├── packages.nix       # 📦 Centralized package definitions
│   ├── profiles/          # 🎨 Optional features (Hyprland, etc.)
│   ├── claude-code/       # 🤖 AI assistant integration
│   ├── neovim/           # ⚡ Editor configuration
│   ├── tmux/             # 🖥️  Terminal multiplexer
│   └── zsh/              # 🐚 Shell environment
└── systems/
    ├── aarch64-darwin/   # 🍎 macOS-specific (nix-darwin)
    │   ├── homebrew.nix  # 🍺 GUI applications
    │   ├── defaults.nix  # ⚙️  System preferences
    │   └── dock.nix      # 📱 Dock configuration
    └── aarch64-linux/    # 🐧 Linux-specific (home-manager)
                          #    Works on both x86_64 and ARM64
```

### Package Categories

- **Core Packages**: Essential CLI tools (eza, bat, zoxide, fzf)
- **Dev Packages**: Development utilities (gh, lazygit, ripgrep, tmux)
- **System Packages**: macOS system-level tools (git, tree)
- **GUI Applications**: macOS apps via Homebrew

### Adding New Packages

```bash
# Add to all systems
echo 'new-package' >> common/packages.nix

# macOS GUI applications
echo '"new-app"' >> systems/aarch64-darwin/homebrew.nix

# Linux-specific packages
echo 'package-name' >> systems/aarch64-linux/home-linux.nix
```

## 🎛️ Commands & Shortcuts

### Core Commands

```bash
# Apply configurations (works on macOS and Linux)
nixswitch              # Auto-detects platform, architecture, and config type

# Update and rebuild
git pull && nixswitch  # Update flake inputs and rebuild

# Development
nix develop            # Enter development shell with tools
nix flake check        # Validate configuration
```

### Available Configurations

```bash
# Linux Desktop (with Hyprland)
.#desktop-x86          # x86_64 (Intel/AMD laptops/desktops)
.#desktop-arm          # ARM64 (cloud instances, DevPods)

# Linux Minimal (servers/containers)
.#minimal-x86          # x86_64 servers
.#minimal-arm          # ARM64 (EC2, cloud instances)

# macOS
.#rick                 # Auto-detects via hostname
```

### Maintenance Commands

```bash
# System status
nix-status             # Detailed system information

# Cleanup (macOS only, set CLEANUP_ON_REBUILD=true)
CLEANUP_ON_REBUILD=true nixswitch

# Rollback
sudo darwin-rebuild rollback     # macOS
home-manager generations         # Linux (shows available)
```

### Development Tools

```bash
# Code formatting and linting
nixfmt-classic **/*.nix    # Format Nix code
statix check               # Check for issues
deadnix --edit             # Remove dead code

# Package management
nix search nixpkgs <name>  # Find packages
nix profile list           # Show installed packages
```

## 🔧 Customization

### Adding New Hosts

Edit `flake.nix` to add new machine configurations:

```nix
# macOS
"new-hostname" = mkDarwinSystem {
  hostname = "new-hostname";
  username = "your-username";
};

# Linux
"new-user" = mkHomeManagerConfig {
  username = "new-user";
};
```

### Shell Customization

ZSH configuration is shared via `common/zsh/shared.nix`:

- **Aliases**: Common shortcuts and system-specific commands
- **History**: Encrypted sync with Atuin
- **Prompt**: Oh My Posh with custom theme
- **Completion**: Enhanced with Carapace

### Claude Code Integration

Advanced AI coding assistant with:

- **Custom Commands**: Linear integration, conventional commits
- **Quality Hooks**: Automated linting and formatting
- **Remote Commands**: Fetched from dedicated repository
- **Settings**: Managed via out-of-store symlinks for easy editing

## 🔒 Security Features

- **1Password SSH Agent**: Seamless SSH key management
- **Tailscale Integration**: Secure device connectivity
- **Credential Isolation**: Proper separation of user/system secrets
- **Validated Configurations**: Runtime username validation with helpful errors

## 🌍 Multi-Environment Support

- **Host-VM Separation**: Clean macOS host with isolated development VMs
- **ARM64 Optimized**: First-class support for Apple Silicon and ARM cloud instances
- **Consistent Environments**: Same tools and configurations across all platforms
- **Cloud Ready**: Pre-configured for AWS, GitHub, and container workflows

## 📊 Performance Optimizations

Built-in performance tuning:

- **Parallel Builds**: Auto-detected core count utilization
- **Download Optimization**: 256MB buffers, 50 HTTP connections
- **Store Optimization**: Automatic Nix store maintenance
- **Substituter Caching**: Fast binary downloads from trusted sources

## 🆘 Troubleshooting

### Common Issues

```bash
# Build failures
nixswitch --show-trace     # Detailed error information
hmswitch --show-trace      # Linux equivalent

# Validation errors
nix eval .#darwinConfigurations.rick.system    # Test macOS config
nix eval .#homeConfigurations.linux.activationPackage  # Test Linux config

# Emergency recovery
sudo darwin-rebuild rollback  # macOS
home-manager generations      # Linux - list available rollbacks
```

### Getting Help

- Check the [CLAUDE.md](./CLAUDE.md) for detailed development guidance
- Review configuration files in the appropriate `systems/` directory
- Use `nix develop` for access to development tools and validation

---

**Built with ❤️ using Nix, nix-darwin, and Home Manager**
