# 🚀 My Cross-Platform Nix Setup

## 🏗️ Why I Built This

Hey! This is just my Nix setup that I've put together over time to make coding easier. I got some ideas from Mitchell Hashimoto's approach to dev environments and tweaked things to work for me.

I like to keep my Mac clean and organized while still having access to all the tools I need for development. This configuration manages my macOS system with nix-darwin and can also set up Linux development environments for cloud or local development.

Here's why I love this setup:

- **My host stays clean** - Nix manages dependencies declaratively
- **It's consistent** - My dev environment feels the same across devices
- **Best of both worlds** - macOS for daily tasks, with Linux options for development
- **My settings follow me everywhere** - Shared configurations keep everything consistent
- **Claude Code integration** - Automated MCP server setup for enhanced AI coding assistance

This is my take on a flexible Nix configuration that manages macOS systems and can provision Linux development environments. It works for me, and maybe it'll give you some ideas for your own setup!

- 🍎 **macOS**: Using nix-darwin for system configuration and Homebrew for applications
- 🐧 **Linux**: Using Home Manager for development environments (local or cloud)
- 🤖 **Claude Code**: Automated MCP server configuration for AI-powered development

## 📁 Structure

Here's how I've organized everything:

```
.
├── flake.nix             # Main entry point for the Nix flake
├── flake.lock            # Lock file for flake dependencies
├── nix.conf              # Global Nix settings
├── Vagrantfile           # Legacy Vagrant configuration (kept for reference)
├── CLAUDE.md             # Claude Code project instructions
├── COMMIT_CONVENTION.md  # Git commit message conventions
├── LICENSE               # MIT license
├── renovate.json         # Renovate dependency updates
├── common/               # Shared configuration
│   ├── default.nix       # Common packages and settings
│   ├── home-packages.nix # Shared packages for all systems
│   ├── claude-code/      # Claude Code integration
│   │   ├── default.nix   # Claude Code setup
│   │   ├── settings.json # Claude Code settings
│   │   ├── CLAUDE.md     # Claude Code instructions
│   │   └── commands/     # Custom Claude Code commands
│   │       ├── breakdown-linear-issue.md
│   │       ├── bugfix.md
│   │       ├── process-task.md
│   │       ├── refactor.md
│   │       └── linear/   # Linear integration commands
│   └── zsh/              # Shared ZSH configuration
│       ├── default.nix   # ZSH module definition
│       ├── default.omp.json # Oh-My-Posh theme
│       └── shared.nix    # Shared ZSH settings
├── systems/              # Architecture-specific configurations
│   ├── aarch64-darwin/   # Apple Silicon macOS configurations
│   │   ├── default.nix   # Main configuration for macOS
│   │   ├── home.nix      # Home Manager configuration
│   │   ├── homebrew.nix  # Homebrew packages and settings
│   │   ├── defaults.nix  # macOS system preferences
│   │   ├── dock.nix      # Dock configuration
│   │   ├── git.nix       # macOS-specific Git setup
│   │   └── zed/          # Zed editor configuration
│   │       ├── default.nix
│   │       └── settings.json
│   └── aarch64-linux/    # ARM Linux configurations
│       ├── default.nix   # Common Linux system configuration
│       ├── vagrant.nix   # Legacy VM configuration
│       ├── ec2.nix       # EC2-specific Home Manager configuration
│       ├── aws.nix       # AWS-specific configurations
│       ├── git.nix       # Linux-specific Git configuration
│       ├── github.nix    # GitHub CLI and integrations
│       ├── ramdisk.nix   # RAM disk configurations
│       ├── rclone.nix    # Cloud storage sync configurations
│       ├── user-scripts.nix # Custom user scripts
│       └── zsh.nix       # Linux-specific ZSH setup
├── overlays/             # Custom Nix overlays
│   └── tfenv.nix         # Terraform Version Manager overlay
├── packer/               # Packer templates
│   └── aws-ec2.pkr.hcl   # AWS EC2 instance configuration
└── .github/              # GitHub Actions workflows
    └── workflows/
        └── pre-commit.yml # Code quality and formatting checks
```

## 🛠️ Installation

### ✅ Prerequisites

Before you dive in, you'll need:

- Nix package manager:
  - 🍎 macOS: `sh <(curl -L https://nixos.org/nix/install)`
  - 🐧 Linux: `sh <(curl -L https://nixos.org/nix/install) --daemon`

### 🍎 macOS Setup (Apple Silicon)

Setting up on macOS with Apple Silicon is pretty straightforward:

1. First, let's get Nix and nix-darwin installed:

   ```bash
   # Install Nix
   sh <(curl -L https://nixos.org/nix/install)

   # Enable flakes (minimal bootstrap configuration)
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

   # Install nix-darwin
   nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
   ./result/bin/darwin-installer
   ```

2. Grab my config:

   ```bash
   git clone https://github.com/svnlto/nix-config.git ~/.config/nix
   cd ~/.config/nix
   ```

3. Apply it to your Mac:
   ```bash
   # For the rick configuration (replace with your hostname)
   darwin-rebuild switch --flake ~/.config/nix#rick

   # Or use the generic macbook configuration
   darwin-rebuild switch --flake ~/.config/nix#macbook
   ```

### 🌩️ Cloud Deployment with Packer {#-cloud-deployment-with-packer}

I've added Packer configuration to build an AWS EC2 instance with my Nix setup:

```bash
# Initialize Packer plugins
cd ~/.config/nix/packer
packer init aws-ec2.pkr.hcl

# Make sure you have AWS credentials configured
# Best practice: Use AWS profiles in ~/.aws/credentials
# See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html

# Build the AMI with your AWS profile
packer build -var "aws_profile=your-profile" aws-ec2.pkr.hcl

# Or use the default profile
packer build aws-ec2.pkr.hcl
```

### ✨ Creating a New macOS Host Configuration

Want to use this on multiple Macs? No problem! You can have different settings for each:

1. Add your Mac to flake.nix under darwinConfigurations:

   ```nix
   "your-hostname" = darwinSystem {
     hostname = "your-hostname";
     username = "your-username";
     dockApps = [
       "/Applications/Safari.app"
       "/Applications/Mail.app"
       "/Applications/Zed.app"
     ];
   };
   ```

2. Then just apply it:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix#your-hostname
   ```

### 🤖 Claude Code Integration

This configuration includes automated setup for Claude Code with MCP (Model Context Protocol) servers:

```bash
# Claude Code and MCP servers are automatically installed and configured
# when you apply the nix-darwin configuration
darwin-rebuild switch --flake ~/.config/nix#rick
```

**Included MCP servers:**

- **context7**: Documentation and context retrieval
- **code-reasoning**: Code analysis and reasoning capabilities
- **sequential-thinking**: Step-by-step problem solving

The configuration automatically:

- Installs Claude Code via npm
- Configures MCP servers as user-scoped (available across all projects)
- Sets up custom commands and workflows
- Manages settings and documentation

**Claude Code features:**

- Custom commands for Linear integration
- Sophisticated development workflows
- Automated code quality checks
- Context-aware AI assistance

### 🖥️ Local Development Options

While this configuration previously included Vagrant VM setup, the focus has shifted to:

- **Direct macOS development** with Nix managing dependencies
- **Cloud development** using EC2 instances with Tailscale
- **Claude Code integration** for AI-enhanced development

The Vagrant configuration files are retained for reference but are no longer actively maintained.

### ☁️ AWS EC2 + Ubuntu Setup

Want to take your development environment to the cloud? Here's how to set up your Nix configuration on an EC2 instance:

> **Note**: As an alternative to manual setup, consider using the Packer template in `packer/aws-ec2.pkr.hcl` to automatically build an AMI with Nix pre-configured. See the [Cloud Deployment with Packer](#-cloud-deployment-with-packer) section.

1. Launch an Ubuntu EC2 instance:
   - Use Ubuntu Server 22.04 LTS or newer (ARM64 for Graviton instances)
   - Recommended: t4g.medium or better for decent performance
   - You can keep the instance completely private in a private subnet
   - Make sure the instance has internet access through a NAT gateway

2. Install Tailscale on your EC2 instance:

   ```bash
   # Add Tailscale's package repository
   curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
   curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

   # Install Tailscale
   sudo apt-get update
   sudo apt-get install -y tailscale

   # Start and authenticate Tailscale
   # This will output a URL to authenticate your instance
   sudo tailscale up

   # Open the URL in your browser and authenticate the machine
   # Once authenticated, note the tailscale hostname (e.g., "ec2-dev.example.tailnet.ts.net")
   tailscale status
   ```

3. Install Tailscale on your local machine:
   - macOS: `brew install tailscale`
   - Visit https://tailscale.com/download for other platforms
   - Run `tailscale up` and authenticate
   - Verify connectivity with `tailscale ping ec2-hostname`

4. Install Nix with multi-user support:

   ```bash
   # Update system packages first
   sudo apt update && sudo apt upgrade -y

   # Install required dependencies
   sudo apt install -y curl git xz-utils

   # Install Nix with daemon (multi-user install)
   sh <(curl -L https://nixos.org/nix/install) --daemon

   # Reload shell to get Nix in PATH
   . /etc/profile.d/nix.sh
   ```

5. Clone your configuration:

   ```bash
   mkdir -p ~/.config
   git clone https://github.com/svnlto/nix-config.git ~/.config/nix
   cd ~/.config/nix
   ```

6. Create EC2-specific configuration:
   - Modify your `flake.nix` to add an EC2 configuration:

     ```nix
     homeConfigurations = {
       # ...existing vagrant configuration...

       # EC2 instance configuration
       "ec2" = home-manager.lib.homeManagerConfiguration {
         pkgs = nixpkgsWithOverlays "aarch64-linux";
         modules = [
           ./systems/aarch64-linux/vagrant.nix  # Reuse Vagrant config as base
           ./systems/aarch64-linux/ec2.nix      # EC2-specific overrides
           {
             home = {
               username = "ubuntu";
               homeDirectory = "/home/ubuntu";
               stateVersion = "23.11";
             };
             nixpkgs.config.allowUnfree = true;
           }
         ];
         extraSpecialArgs = { username = "ubuntu"; };
       };
     };
     ```

   - Create a directory for EC2-specific configuration:

     ```bash
     mkdir -p ~/.config/nix/systems/aarch64-linux
     ```

   - Create a basic `systems/aarch64-linux/ec2.nix` file:

     ```nix
     { config, pkgs, username, ... }:

     {
       # EC2-specific configuration
       # This will override or extend the base vagrant configuration

       # Additional packages specific to EC2 environment
       home.packages = with pkgs; [
         awscli2
         amazon-ecr-credential-helper
       ];

       # EC2-specific Git configuration
       programs.git.extraConfig = {
         credential.helper = "!aws codecommit credential-helper $@";
         credential.UseHttpPath = true;
       };
     }
     ```

7. Enable Nix flakes and apply the configuration:

   ```bash
   # Enable flakes
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

   # Apply the EC2-specific configuration
   export NIXPKGS_ALLOW_UNFREE=1
   nix run home-manager/master -- switch --flake ~/.config/nix#ec2 --impure
   ```

8. Connect with your editor:
   - Use SSH to connect to your development environment:
     ```bash
     ssh ubuntu@ec2-hostname.tailnet.ts.net
     ```
   - Or configure your editor's remote development features
   - Open your projects folder and enjoy your cloud development environment!

9. To update your configuration:
   ```bash
   cd ~/.config/nix
   git pull
   nix run home-manager/master -- switch --flake ~/.config/nix#ec2 --impure
   ```

With this Tailscale-powered setup, you get all the benefits of a cloud development environment with none of the security headaches:

- Keep your EC2 instance completely private (no public IP needed)
- Secure, encrypted connections between all your devices
- Connection works even if the instance's IP changes
- Get consistent development environments across your entire team
- Access your environment securely from anywhere

### 🔧 Additional Features

This configuration includes several advanced features:

#### 🌟 Enhanced Linux Development
- **AWS Integration**: Pre-configured AWS CLI with profile support
- **GitHub CLI**: Seamless GitHub integration with authentication
- **RAM Disk Support**: High-performance temporary storage configurations
- **Cloud Storage**: Rclone integration for syncing with cloud providers
- **Custom Scripts**: User-defined scripts for workflow automation

#### 🛠️ Specialized Configurations
- **Renovate**: Automated dependency updates via `renovate.json`
- **Commit Conventions**: Standardized commit message format via `COMMIT_CONVENTION.md`
- **Zed Editor**: Modern editor configuration with settings
- **Linear Integration**: Custom Claude Code commands for Linear workflow

## 🔄 Usage

### 🔁 Updating the System

Keeping everything up to date is super simple:

#### 🍎 macOS:

```bash
# Pull latest changes
git pull

# Apply configuration (replace with your hostname)
darwin-rebuild switch --flake ~/.config/nix#rick

# Or use the generic configuration
darwin-rebuild switch --flake ~/.config/nix#macbook
```

#### ☁️ EC2 Instance:

```bash
# Pull latest changes
git pull

# Apply updated configuration
nix run home-manager/master -- switch --flake ~/.config/nix#ec2 --impure
```

### ✏️ Making Changes

Tweaking things is easy:

1. Make your changes to the config files
2. Save your work with: `git commit -am "What I changed"`
3. Share it with: `git push`
4. Apply your changes with the commands above

### 🧩 Common Tasks

Here's how to do all the usual stuff:

- 📦 Adding packages everywhere: Edit `common/home-packages.nix`
- 🍎 Adding Mac-only packages: Edit `systems/aarch64-darwin/default.nix`
- 🍺 Need a GUI app via Homebrew? Edit `systems/aarch64-darwin/homebrew.nix`
- ⚙️ Tweaking macOS settings: Look in `systems/aarch64-darwin/defaults.nix`
- 📱 Changing dock icons: Edit `systems/aarch64-darwin/dock.nix`
- 🤖 Configuring Claude Code: Edit `common/claude-code/default.nix`
- ☁️ Adding stuff to your EC2 instance: Edit `systems/aarch64-linux/ec2.nix`
- 🔧 AWS-specific configurations: Edit `systems/aarch64-linux/aws.nix`
- 🐙 GitHub CLI setup: Edit `systems/aarch64-linux/github.nix`
- 💾 RAM disk configurations: Edit `systems/aarch64-linux/ramdisk.nix`
- ☁️ Cloud storage sync: Edit `systems/aarch64-linux/rclone.nix`
- 📜 Custom user scripts: Edit `systems/aarch64-linux/user-scripts.nix`
- ⚡ Modifying AWS EC2 image: Edit `packer/aws-ec2.pkr.hcl`
- 🔧 Pre-commit hooks: Edit `.pre-commit-config.yaml`

### ☁️ AWS Configuration

This setup includes special support for working with AWS:

#### AWS Profiles

The EC2 configuration uses AWS profiles for better credential management:

```nix
# In systems/aarch64-linux/ec2.nix
programs.git.extraConfig = {
  credential.helper = "!aws --profile dev codecommit credential-helper $@";
  credential.UseHttpPath = true;
};
```

#### Packer AWS EC2 Images

The Packer configuration also supports AWS profiles:

```hcl
# In packer/aws-ec2.pkr.hcl
variable "aws_profile" {
  type    = string
  default = "default"
  description = "AWS profile to use for authentication"
}

source "amazon-ebs" "nixos" {
  ami_name        = var.ami_name
  profile         = var.aws_profile
  # ...
}
```

To build an EC2 image with a specific profile:

```bash
cd ~/.config/nix/packer
packer build -var "aws_profile=dev" aws-ec2.pkr.hcl
```

## ✨ Features

### 📱 Customizable Dock Applications

I love being able to have different dock setups for different Macs:

```nix
"macbook-work" = darwinSystem {
  hostname = "macbook-work";
  username = "workuser";
  dockApps = [
    "/Applications/Safari.app"
    "/Applications/Mail.app"
    "/Applications/Slack.app"
    "/Applications/Calendar.app"
  ];
};

"macbook-personal" = darwinSystem {
  hostname = "macbook-personal";
  username = "personaluser";
  dockApps = [
    "/Applications/Arc.app"
    "/Applications/Spotify.app"
    "/Applications/Discord.app"
  ];
};
```

### 🔄 Cross-Platform Package Management

I've set things up so I can easily manage:

- 🌐 Tools I want everywhere (in `common/`)
- 💻 Stuff specific to each ARM platform (in `systems/aarch64-darwin/` for macOS and `systems/aarch64-linux/` for Linux)
- 👤 My personal preferences and settings

This configuration focuses exclusively on ARM64 architecture (aarch64), optimized for Apple Silicon Macs and ARM-based Linux environments like ARM EC2 instances.

### 📦 Modern Development Workflow

This configuration emphasizes a streamlined development approach:

- **Declarative Configuration**: All system and development tools managed through Nix
- **Cross-Platform Consistency**: Shared configuration between macOS and Linux environments
- **AI-Enhanced Development**: Deep Claude Code integration with custom commands
- **Cloud-Native Ready**: Built-in support for AWS, GitHub, and cloud storage
- **Automated Maintenance**: Renovate for dependency updates, pre-commit hooks for quality

## 💡 Tips and Tricks

Here are a few things I've learned along the way:

- 🔄 **Nix + Homebrew Harmony**: Keep an eye on your PATH - I've set Homebrew to take precedence, but you might want to adjust this

- 🖥️ **Remote Development**: SSH-based remote development works seamlessly with modern editors

- 🌐 **Browser Integration**: When you run commands like `gh auth login`, browser links will open automatically on your host machine

- 🤖 **Claude Code Commands**: Use the custom commands in `common/claude-code/commands/` for Linear integration and development workflows

- 🔧 **Tailscale Networking**: Secure networking between your devices without exposing services to the internet

- 📦 **Shared vs Specific**: Use `common/home-packages.nix` for tools you want everywhere, platform-specific configs for specialized tools

## 📄 License

This setup is my personal configuration, but I'm sharing it under the MIT license. Feel free to borrow ideas, adapt it, or use it as inspiration for your own perfect dev environment!
