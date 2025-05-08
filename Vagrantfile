# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Basic VM Configuration
  config.vm.box = "utm/ubuntu-24.04"
  config.vm.hostname = "nix-dev"
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  
  # UTM Provider Configuration
  config.vm.provider "utm" do |utm|
    utm.memory = "4096"
    utm.cpus = 4
    utm.name = "nix-dev-vm"
    utm.directory_share_mode = "virtFS"
  end
  
  # Synced folder configuration - exclude the result symlink
  config.vm.synced_folder ".", "/vagrant", exclude: ["result"]

  # System provisioning (with root privileges)
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    echo "=== Setting up system dependencies ==="
    apt-get update
    apt-get install -y locales sudo build-essential curl file git unzip zsh

    # Generate required locales
    localedef -i en_US -f UTF-8 en_US.UTF-8
    localedef -i en_GB -f UTF-8 en_GB.UTF-8

    # Set system-wide locale
    echo "LANG=en_US.UTF-8" > /etc/default/locale
    echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale

    # Make sure vagrant user has sudo privileges
    echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant
  SHELL

  # User provisioning (as vagrant user)
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    # Set environment variables
    export HOME=/home/vagrant
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    
    echo "=== Installing Nix ==="
    sh <(curl -L https://nixos.org/nix/install) --daemon
    
    # Source the nix profile
    . /etc/profile.d/nix.sh
    
    # Copy configuration to ~/.config/nix
    echo "=== Setting up Nix configuration ==="
    mkdir -p $HOME/.config/nix
    
    # Copy files excluding result symlink
    cd /vagrant
    find . -type f -not -path "*/\\.*" -not -path "*/result/*" -not -name "result" | while read file; do
      mkdir -p "$HOME/.config/nix/$(dirname "$file")"
      cp "$file" "$HOME/.config/nix/$file"
    done
    
    # Enable flakes
    echo "experimental-features = nix-command flakes" > $HOME/.config/nix/nix.conf
    
    # Get the SHA256 hash for tfenv
    echo "=== Getting SHA256 hash for tfenv ==="
    nix-shell -p nix-prefetch-git --command "nix-prefetch-git --url https://github.com/tfutils/tfenv.git --rev v3.0.0" > $HOME/tfenv-hash.json
    TFENV_HASH=$(cat $HOME/tfenv-hash.json | grep -o '"sha256": "[^"]*"' | cut -d'"' -f4)
    echo "tfenv SHA256 hash: $TFENV_HASH"
    
    # Get the SHA256 hash for nvm
    echo "=== Getting SHA256 hash for nvm ==="
    nix-shell -p nix-prefetch-git --command "nix-prefetch-git --url https://github.com/nvm-sh/nvm.git --rev v0.39.7" > $HOME/nvm-hash.json
    NVM_HASH=$(cat $HOME/nvm-hash.json | grep -o '"sha256": "[^"]*"' | cut -d'"' -f4)
    echo "nvm SHA256 hash: $NVM_HASH"
    
    # Update the tfenv overlay with the correct hash
    if [ -f "$HOME/.config/nix/overlays/tfenv.nix" ]; then
      echo "Updating tfenv.nix with the correct hash..."
      sed -i 's|sha256 = "[^"]*"|sha256 = "'"$TFENV_HASH"'"|' $HOME/.config/nix/overlays/tfenv.nix
    fi
    
    # Update the nvm overlay with the correct hash
    if [ -f "$HOME/.config/nix/overlays/nvm.nix" ]; then
      echo "Updating nvm.nix with the correct hash..."
      sed -i 's|sha256 = "[^"]*"|sha256 = "'"$NVM_HASH"'"|' $HOME/.config/nix/overlays/nvm.nix
    fi
    
    # Install home-manager
    echo "=== Setting up Home Manager ==="
    nix run home-manager/master -- init --no-flake
    
    # Apply configuration
    echo "=== Applying configuration with Home Manager ==="
    rm -f $HOME/.zshrc
    export NIXPKGS_ALLOW_UNFREE=1
    LOCALE_ARCHIVE="" nix run home-manager/master -- switch --flake $HOME/.config/nix#vagrant --impure
    
    # Install Oh-My-Posh
    if ! command -v oh-my-posh &> /dev/null; then
      echo "=== Installing Oh My Posh ==="
      curl -s https://ohmyposh.dev/install.sh | bash -s
    fi
    mkdir -p $HOME/.config/oh-my-posh
    
    # Set ZSH as default shell
    sudo chsh -s $(which zsh) vagrant
  SHELL

  # Run a simpler script on every startup to ensure proper configuration
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    # Ensure proper ZSH configuration on every startup
    if [ -f "$HOME/.config/home-manager/zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
      echo "Fixing ZSH configuration links..."
      rm -f $HOME/.zshrc
      ln -sf $HOME/.config/home-manager/zshrc $HOME/.zshrc
    fi
    
    # Ensure nix environment is available
    if [ -f "/etc/profile.d/nix.sh" ]; then
      . /etc/profile.d/nix.sh
    fi
  SHELL
end