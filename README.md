# 🚀 My Cross-Platform Nix Setup

## 🏗️ Why I Built This

Hey! This is just my Nix setup that I've put together over time to make coding easier. I got some ideas from Mitchell Hashimoto's approach to dev environments and tweaked things to work for me.

I like to keep my Mac clean and organized while still having access to all the tools I need for development. That's why I set things up this way: I use my Mac for everyday tasks, but I do all my actual coding and development work in a Vagrant-managed UTM VM.

Here's why I love this setup:

- **My host stays clean** - No more dependency issues
- **I can experiment freely** - Breaking my dev environment doesn't affect my system
- **It's consistent** - My dev environment feels the same on all my devices
- **Best of both worlds** - macOS for daily tasks, Linux for development
- **My settings follow me everywhere** - Shared ZSH configs keep my shell experience consistent

This is my take on a flexible Nix configuration that manages both my macOS system and my Linux development VM. It works for me, and maybe it'll give you some ideas for your own setup!

- 🍎 **macOS**: Using nix-darwin for system configuration and Homebrew for applications
- 🐧 **Linux/UTM VM**: Using Home Manager for user environment configuration

## 📁 Structure

Here's how I've organized everything:

```
.
├── flake.nix             # Main entry point for the Nix flake
├── flake.lock            # Lock file for flake dependencies
├── nix.conf              # Global Nix settings
├── Vagrantfile           # Definition for Vagrant VM development environment
├── common/               # Shared configuration
│   ├── default.nix       # Common packages and settings
│   └── zsh/              # Shared ZSH configuration
│       ├── default.nix   # ZSH module definition
│       ├── default.omp.json # Oh-My-Posh theme
│       └── shared.nix    # Shared ZSH settings
├── darwin/               # macOS specific configuration
│   ├── default.nix       # Main configuration for macOS
│   ├── homebrew.nix      # Homebrew packages and settings
│   ├── defaults.nix      # macOS system preferences
│   ├── dock.nix          # Dock configuration
│   └── zsh.nix           # macOS-specific ZSH setup
├── overlays/             # Custom Nix overlays
│   ├── browser-forward.nix  # Browser forwarding for SSH sessions
│   ├── nvm.nix           # Node Version Manager overlay
│   └── tfenv.nix         # Terraform Version Manager overlay
├── scripts/              # Utility scripts
│   └── setup-local-config.sh # Script to set up Git local configuration
└── vagrant/              # Vagrant VM configuration
    ├── default.nix       # System configuration
    ├── home.nix          # User environment via Home Manager
    ├── git.nix           # VM-specific Git configuration
    └── zsh.nix           # VM-specific ZSH setup
```

## 🛠️ Installation

### ✅ Prerequisites

Before you dive in, you'll need:

- Nix package manager:
  - 🍎 macOS: `sh <(curl -L https://nixos.org/nix/install)`
  - 🐧 Linux: `sh <(curl -L https://nixos.org/nix/install) --daemon`

### 🍎 macOS Setup

Setting up on macOS is pretty straightforward:

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
   # For the default configuration (hostname: macbook)
   darwin-rebuild switch --flake ~/.config/nix#macbook
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
       "/Applications/Visual Studio Code.app"
     ];
   };
   ```

2. Then just apply it:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix#your-hostname
   ```

### 🖥️ UTM + Vagrant Setup (Apple Silicon)

Here's my favorite part - the VM setup! If you've got an Apple Silicon Mac, UTM + Vagrant is a match made in heaven. You get the speed of native ARM virtualization with the convenience of Vagrant's declarative VM management:

1. First, grab the basics:
   ```bash
   # Apply your nix-darwin config to install UTM and Vagrant
   darwin-rebuild switch --flake ~/.config/nix#Rick
   
   # Install the Vagrant UTM plugin
   vagrant plugin install vagrant-utm
   ```

2. Fire up the VM:
   ```bash
   cd ~/.config/nix
   vagrant up
   ```
   
   **Heads up**: The first time you do this:
   - UTM will ask for permission (just say yes)
   - Your terminal will ask if you want to download the VM image (say yes to that too)
   - It'll download the Ubuntu ARM64 VM image (~600MB)
   - Then it'll set up Nix and all your dev tools automatically

3. Jump into the VM:
   ```bash
   # Quick way - SSH from your terminal
   vagrant ssh
   
   # Or get the VM's IP for connecting with VS Code
   ip addr show | grep "inet " | grep -v 127.0.0.1
   ```

4. Connect with VS Code (this is where the magic happens):
   - Install the "Remote - SSH" extension in VS Code
   - Add a new SSH host: `ssh vagrant@VM_IP_ADDRESS` (password: `vagrant`)
   - Open the `/vagrant` folder - it's synced with your host's nix config

5. Some handy VM commands:
   ```bash
   vagrant suspend  # Take a coffee break (pauses the VM)
   vagrant resume   # Back to work! (resumes the VM)
   vagrant halt     # Calling it a day (stops the VM)
   vagrant destroy  # Starting fresh (deletes the VM)
   vagrant provision # Apply new config changes
   ```

6. Made some config tweaks? Apply them like this:
   ```bash
   # From your Mac
   vagrant provision
   
   # Or from inside the VM
   cd ~/.config/nix
   nix run home-manager/master -- switch --flake ~/.config/nix#vagrant --impure
   ```

### 🔧 Version Manager Setup

I've set up two super handy version managers in the VM that make switching between different versions of tools a breeze:

1. **tfenv** - For all your Terraform needs:
   ```bash
   # Grab any Terraform version you want
   tfenv install 1.5.0
   
   # Switch versions with a single command
   tfenv use 1.5.0
   
   # See what you've got installed
   tfenv list
   ```

2. **nvm** - For juggling Node.js versions:
   ```bash
   # Install Node versions like candy
   nvm install 18
   
   # Hop between versions instantly
   nvm use 16
   
   # Check what you've got
   nvm list
   ```

### 🔗 Browser Forwarding

This is a cool trick! When you're deep into coding in your VM and need to authenticate with GitHub CLI or any other tool that pops open a browser, you don't want to be stuck. My setup automatically forwards those browser requests to your Mac. No more copying and pasting URLs - just click and go! The `browser-forward` overlay handles all this magic behind the scenes.

## 🔄 Usage

### 🔁 Updating the System

#### 🍎 macOS:
```bash
# Pull latest changes
git pull

# Apply configuration (replace macbook with your hostname)
darwin-rebuild switch --flake ~/.config/nix#macbook
```

#### 🐧 Vagrant VM:
```bash
# Pull latest changes
git pull

# Rebuild VM with latest configuration
vagrant provision

# Alternative: Apply Home Manager configuration directly in VM
nix run home-manager/master -- switch --flake ~/.config/nix#vagrant
```

### ✏️ Making Changes

1. Modify the relevant configuration files
2. Commit your changes: `git commit -am "Description of changes"`
3. Push to your repository: `git push`
4. Apply the changes using the commands above

### 🧩 Common Tasks

- 📦 Add a new package to all systems: Edit `common/default.nix`
- 🍎 Add a macOS-specific package: Edit `darwin/default.nix`
- 🍺 Add a Homebrew package: Edit `darwin/homebrew.nix`
- ⚙️ Change macOS settings: Edit `darwin/defaults.nix`
- 📱 Customize dock applications: Edit your host configuration in `flake.nix`
- 🐧 Configure VM environment: Edit `vagrant/home.nix`
- 🔑 Update Git personal settings: Edit `~/.gitconfig.local`
- 🖥️ Customize Vagrant VM: Edit `Vagrantfile`
- 🔄 Add a Nix overlay: Create a new file in `overlays/` and reference it in `flake.nix`

## ✨ Features

### 📱 Customizable Dock Applications

Each macOS host can have its own set of dock applications:

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

The configuration uses a modular approach to manage:
- 🌐 Common packages across platforms
- 💻 Platform-specific packages
- 👤 User-specific configurations

### 🔐 Privacy-Focused Git Configuration

The Git configuration is designed with privacy in mind:

- Complete Git config for the Vagrant VM in `vagrant/git.nix`
- Personal information stored in a local, untracked `~/.gitconfig.local` file
- Automatically creates a template `~/.gitconfig.local` file during first run
- Prevents exposing your email address in public repositories

For macOS, Git is installed as a system package without specialized configuration.

Example `.gitconfig.local`:
```
# Local Git configuration - NOT tracked in Git
# This file contains your personal Git configuration, including email

[user]
    name = Your Name
    email = your.email@example.com

# You can add other private Git configurations here
[github]
    user = yourusername
```

The system will automatically include this file in your Git configuration.

### 📦 Custom Nix Overlays

The configuration includes custom Nix overlays for tools that aren't available in the standard nixpkgs:

- **tfenv**: Terraform version manager
- **nvm**: Node.js version manager
- **browser-forward**: Utility to forward browser requests from SSH sessions to the host

These overlays make it easy to add and manage tools that might not be available or up-to-date in the standard Nix repositories.

## 💡 Tips and Tricks

- 🔄 **Working with Both Nix and Homebrew**: Be aware of potential PATH conflicts when using both package managers; the default configuration puts Homebrew ahead of Nix in the PATH

- 🖥️ **VSCode Integration**: Use the Remote SSH extension to connect to your Vagrant VM and work on your projects with full VS Code functionality

- 🌐 **Browser Forwarding**: When working in the VM via VS Code and using tools that need to open a browser (like `gh auth login`), the browser-forward utility will automatically open the URL in your host machine's browser

- 🔧 **Managing Multiple Terraform Versions**: Use tfenv to switch between different versions of Terraform for different projects

## 📄 License

This configuration is personal but freely available under the MIT license. Feel free to use it as inspiration for your own setup.