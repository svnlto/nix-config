# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Basic VM Configuration
  config.vm.box = "utm/ubuntu-24.04"
  config.vm.hostname = "nix-dev"
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  
  # UTM Provider Configuration
  config.vm.provider "utm" do |utm|
    utm.memory = "4096"
    utm.cpus = 4
    utm.name = "nix-dev-vm"
    utm.directory_share_mode = "virtFS"
  end
  
  # Improved synced folder configuration
  config.vm.synced_folder ".", "/home/vagrant/.config/nix-host", exclude: ["result"]
  config.vm.synced_folder "/Users/svenlito/Sites", "/home/vagrant/projects"

  # Fix permissions for synced folders (run before other provisioners)
  config.vm.provision "shell", privileged: true, run: "always", inline: <<-SHELL
    echo "=== Fixing permissions for synced folders ==="
    chown -R vagrant:vagrant /home/vagrant/.config/nix-host
    chown -R vagrant:vagrant /home/vagrant/projects
  SHELL

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
    
    # Enable flakes
    echo "experimental-features = nix-command flakes" > $HOME/.config/nix/nix.conf
    
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
    # Sync any changes from the host to the VM's local copy
    echo "=== Syncing configuration from host ==="
    mkdir -p $HOME/.config/nix
    rsync -av --exclude='.git' --exclude='result' $HOME/.config/nix-host/ $HOME/.config/nix/
    
    # Ensure Git is not trying to track changes in the copied directory
    touch $HOME/.config/nix/.git/info/exclude
    echo "*" > $HOME/.config/nix/.git/info/exclude
    
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