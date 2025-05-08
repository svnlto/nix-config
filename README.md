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
   darwin-rebuild switch --flake ~/.config/nix#macbook
   
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

When working in your VM and using tools like GitHub CLI that need to open a browser for authentication, you don't want to be stuck copying and pasting URLs. This setup automatically forwards browser requests to your host machine, making the experience seamless. The `browser-forward` overlay handles this transparently.

## 🔄 Usage

### 🔁 Updating the System

Keeping everything up to date is super simple:

#### 🍎 macOS:
```bash
# Pull latest changes
git pull

# Apply configuration 
darwin-rebuild switch --flake ~/.config/nix#macbook
```

#### 🐧 Vagrant VM:
```bash
# Pull latest changes
git pull

# Rebuild VM with latest configuration
vagrant provision

# Or if you're already in the VM, you can run:
nix run home-manager/master -- switch --flake ~/.config/nix#vagrant --impure
```

### ✏️ Making Changes

Tweaking things is easy:

1. Make your changes to the config files
2. Save your work with: `git commit -am "What I changed"`
3. Share it with: `git push`
4. Apply your changes with the commands above

### 🧩 Common Tasks

Here's how to do all the usual stuff:

- 📦 Adding packages everywhere: Just edit `common/default.nix`
- 🍎 Adding Mac-only packages: Edit `darwin/default.nix`
- 🍺 Need a GUI app via Homebrew? Edit `darwin/homebrew.nix`
- ⚙️ Tweaking macOS settings: Look in `darwin/defaults.nix`
- 📱 Changing dock icons: Find your host in `flake.nix`
- 🐧 Adding stuff to your VM: Edit `vagrant/home.nix`
- 🔑 Updating your Git identity: Edit `~/.gitconfig.local`
- 🖥️ Changing VM settings: It's all in `Vagrantfile`
- 🔄 Adding a custom tool: Create a new file in `overlays/` and add it to `flake.nix`

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
- 💻 Stuff specific to each platform (in `darwin/` and `vagrant/`)
- 👤 My personal preferences and settings

### 🔐 Privacy-Focused Git Configuration

I'm big on privacy, so I've set up Git in a smart way:

- All the common Git config lives in `vagrant/git.nix`
- Your personal details (email, name) go in a separate `~/.gitconfig.local` file
- This file isn't tracked in Git, so your email stays private
- The system creates a template for you to fill in on first run

For my Mac, I keep it simple with just the standard Git package.

Here's what your `.gitconfig.local` might look like:
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

The system picks this up automatically, so you never have to worry about it!

### 📦 Custom Nix Overlays

Sometimes the standard Nix packages don't have exactly what you need, or they're not up to date. That's where my custom overlays come in:

- **tfenv**: My go-to for managing multiple Terraform versions
- **nvm**: Keeps Node.js versions under control
- **browser-forward**: My little trick for forwarding browser requests from SSH sessions to your Mac

These make life so much easier when you're working across multiple projects with different requirements.

## 💡 Tips and Tricks

Here are a few things I've learned along the way:

- 🔄 **Nix + Homebrew Harmony**: Keep an eye on your PATH - I've set Homebrew to take precedence, but you might want to adjust this

- 🖥️ **VS Code Remote SSH**: The Remote SSH extension makes working in the VM feel just like working locally

- 🌐 **Browser Integration**: When you're in VS Code and run something like `gh auth login`, browser links will open automatically on your host machine

- 🔧 **Multiple Terraform Versions**: Use tfenv to easily switch between different versions of Terraform for various projects

## 📄 License

This setup is my personal configuration, but I'm sharing it under the MIT license. Feel free to borrow ideas, adapt it, or use it as inspiration for your own perfect dev environment!