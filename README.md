# 🚀 My Cross-Platform Nix Setup

## 🏗️ Why I Built This

Hey! This is just my Nix setup that I've put together over time to make coding easier. I got some ideas from Mitchell Hashimoto's approach to dev environments and tweaked things to work for me.

I like to keep my Mac clean and organized while still having access to all the tools I need for development. That's why I set things up this way: I use my Mac for everyday tasks, but I do all my actual coding and development work in an OrbStack Ubuntu VM.

Here's why I love this setup:

- **My host stays clean** - No more dependency issues
- **I can experiment freely** - Breaking my dev environment doesn't affect my system
- **It's consistent** - My dev environment feels the same on all my devices
- **Best of both worlds** - macOS for daily tasks, Linux for development
- **My settings follow me everywhere** - Shared ZSH configs keep my shell experience consistent

This is my take on a flexible Nix configuration that manages both my macOS system and my Ubuntu development VM. It works for me, and maybe it'll give you some ideas for your own setup!

- 🍎 **macOS**: Using nix-darwin for system configuration and Homebrew for applications
- 🐧 **Linux/Ubuntu**: Using Home Manager for user environment configuration

## 📁 Structure

```
.
├── flake.nix             # Main entry point for the Nix flake
├── nix.conf              # Global Nix settings
├── common/               # Shared configuration
│   └── default.nix       # Common packages and settings
├── darwin/               # macOS specific configuration
│   ├── default.nix       # Main configuration for macOS
│   ├── homebrew.nix      # Homebrew packages and settings
│   └── defaults.nix      # macOS system preferences
└── ubuntu-orbstack/      # Ubuntu configuration (used for both generic Ubuntu and OrbStack)
    ├── default.nix       # System configuration
    ├── home.nix          # User environment via Home Manager
    ├── setup-linuxbrew.sh # Script to set up Linuxbrew
    └── zshrc-custom      # Custom ZSH configuration
```

## 🛠️ Installation

### ✅ Prerequisites

- Install Nix package manager:
  - 🍎 macOS: `sh <(curl -L https://nixos.org/nix/install)`
  - 🐧 Linux: `sh <(curl -L https://nixos.org/nix/install) --daemon`
  - 🐧 Containerized Linux (e.g., OrbStack): See below for specialized installation

### 🍎 macOS Setup

1. Install Nix and nix-darwin:
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

2. Clone this repository:
   ```bash
   git clone https://github.com/svnlto/nix-config.git ~/.config/nix
   cd ~/.config/nix
   ```

3. Apply the configuration:
   ```bash
   # For the default configuration (hostname: macbook)
   darwin-rebuild switch --flake ~/.config/nix#macbook
   ```

### ✨ Creating a New macOS Host Configuration

This configuration allows for multiple macOS hosts with different settings:

1. Add your host to flake.nix under darwinConfigurations:
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

2. Apply the configuration:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix#your-hostname
   ```

### 🐧 Ubuntu/Linux Setup

1. Install Nix (standard installation):
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

   For containerized environments (like OrbStack):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --extra-conf "sandbox = false" --extra-conf='filter-syscalls = false' --init none --no-confirm
   ```

2. Clone this repository:
   ```bash
   git clone https://github.com/svnlto/nix-config.git ~/.config/nix
   cd ~/.config/nix
   ```

3. Apply the Home Manager configuration:
   ```bash
   # For generic Ubuntu setup
   nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu-orbstack
   ```

4. (Optional) Set up Linuxbrew:
   ```bash
   chmod +x ~/.config/nix/ubuntu-orbstack/setup-linuxbrew.sh
   ~/.config/nix/ubuntu-orbstack/setup-linuxbrew.sh
   ```

## 🔄 Usage

### 🔁 Updating the System

#### 🍎 macOS:
```bash
# Pull latest changes
git pull

# Apply configuration (replace macbook with your hostname)
darwin-rebuild switch --flake ~/.config/nix#macbook
```

#### 🐧 Linux/Ubuntu:
```bash
# Pull latest changes
git pull

# Apply configuration
nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu-orbstack
```

### ✏️ Making Changes

1. Modify the relevant configuration files
2. Commit your changes: `git commit -am "Description of changes"`
3. Push to your repository: `git push`
4. Apply the changes using the commands above

### 🧩 Common Tasks

- 📦 Add a new package to all systems: Edit `common/default.nix`
- 🍎 Add a macOS-specific package: Edit `darwin/default.nix`
- 🍺 Add a Homebrew cask: Edit `darwin/homebrew.nix`
- ⚙️ Change macOS settings: Edit `darwin/defaults.nix`
- 📱 Customize dock applications: Edit your host configuration in `flake.nix`
- 🐧 Configure Ubuntu environment: Edit `ubuntu-orbstack/home.nix`

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

## 💡 Tips and Tricks

- 🔒 **Lock Issues in OrbStack**: If you encounter Nix store lock issues in OrbStack, try increasing the timeout:
  ```bash
  nix --option stalled-download-timeout 600 run home-manager/master -- switch --flake .#ubuntu-orbstack
  ```

- 👨‍💻 **VSCode Integration**: Use Remote SSH rather than Remote Containers for working with OrbStack

- 🔄 **Working with Both Nix and Homebrew**: Be aware of potential PATH conflicts when using both package managers; the default configuration puts Homebrew ahead of Nix in the PATH

## 📄 License

This configuration is personal but freely available under the MIT license. Feel free to use it as inspiration for your own setup.