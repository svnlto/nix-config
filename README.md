# Cross-Platform Nix Configuration

Declarative system configuration for macOS (nix-darwin) and Linux (home-manager) with Claude Code integration.

## Quick Start

### macOS (Apple Silicon)

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install)

# Clone and apply
git clone https://github.com/svnlto/nix-config.git ~/.config/nix
cd ~/.config/nix
darwin-rebuild switch --flake .#rick  # Replace 'rick' with your hostname
```

### Cloud (AWS EC2)

```bash
# Build AMI with Packer
cd ~/.config/nix/packer
packer build -var "aws_profile=dev" aws-ec2.pkr.hcl

# Or apply to existing Ubuntu instance
nix run home-manager/master -- switch --flake ~/.config/nix#ec2 --impure
```

## Structure

```
├── flake.nix              # Main entry point
├── common/                # Shared configuration
│   ├── claude-code/       # AI coding assistant integration
│   ├── neovim/           # Neovim configuration
│   └── zsh/              # Shell configuration
├── systems/
│   ├── aarch64-darwin/   # macOS configurations
│   └── aarch64-linux/    # Linux configurations
└── packer/               # Cloud image templates
```

## Features

- **Clean Host**: Nix manages dependencies declaratively
- **Consistency**: Same environment across devices
- **Claude Code**: MCP servers and custom commands
- **Cloud-Ready**: AWS, Tailscale, and GitHub integrations

## Configuration

### Add Packages
- Global: Edit `common/home-packages.nix`
- macOS: Edit `systems/aarch64-darwin/default.nix`
- GUI Apps: Edit `systems/aarch64-darwin/homebrew.nix`

### Create New Host

Add to `flake.nix`:

```nix
"hostname" = darwinSystem {
  hostname = "hostname";
  username = "username";
};
```

Apply: `darwin-rebuild switch --flake .#hostname`

## Update

```bash
git pull
darwin-rebuild switch --flake .#rick  # macOS
# or
nix run home-manager/master -- switch --flake .#ec2 --impure  # Linux
```

## License

MIT
