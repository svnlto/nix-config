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
    utm.memory = "6144"  # Increased for better Rust compilation performance
    utm.cpus = 4
    utm.name = "nix-dev-vm"
    utm.directory_share_mode = "virtFS"
  end
  
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
    
    # Create projects directory
    mkdir -p /home/vagrant/projects
    chown -R vagrant:vagrant /home/vagrant/projects
    
    # Optimize system for builds
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
    sysctl -p
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
    
    # Set up Git
    echo "=== Setting up Git ==="
    git config --global init.defaultBranch main
    git config --global core.editor "vim"
    
    # Clone nix configuration repository
    echo "=== Cloning nix configuration repository ==="
    mkdir -p $HOME/.config
    cd $HOME/.config
    
    if [ ! -d "$HOME/.config/nix" ]; then
      git clone https://github.com/svnlto/nix-config.git nix
    fi
    
    # Minimal Nix bootstrap configuration to enable flakes
    mkdir -p /etc/nix
    sudo tee /etc/nix/nix.conf > /dev/null <<EOL
experimental-features = nix-command flakes
trusted-users = root vagrant
EOL
    
    # Restart the Nix daemon to apply basic settings
    sudo systemctl restart nix-daemon
    
    # Source nix profile again after daemon restart
    . /etc/profile.d/nix.sh
    
    # Install home-manager and apply configuration
    echo "=== Setting up Home Manager ==="
    export NIXPKGS_ALLOW_UNFREE=1
    
    # Apply configuration with home-manager
    echo "=== Applying configuration with Home Manager ==="
    nix run home-manager/master -- init --no-flake
    
    # Apply the flake configuration
    echo "=== Switching to Home Manager configuration ==="
    LOCALE_ARCHIVE="" nix run home-manager/master -- switch --flake $HOME/.config/nix#vagrant --impure
    
    # Set up SSH keys directory
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
    
    # Set ZSH as default shell
    sudo chsh -s $(which zsh) vagrant
  SHELL

  # Run a minimal startup script
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    # Ensure nix environment is available
    if [ -f "/etc/profile.d/nix.sh" ]; then
      . /etc/profile.d/nix.sh
    fi
    
    echo ""
    echo "======================================================="
    echo " Development environment is ready!"
    echo " - Projects directory: ~/projects"
    echo " - Nix config: ~/.config/nix"
    echo "======================================================="
  SHELL
end