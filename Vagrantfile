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
    
    # Create projects directory with correct permissions
    mkdir -p /home/vagrant/projects
    chown -R vagrant:vagrant /home/vagrant/projects
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
    
    # Set up Git with proper credentials
    echo "=== Setting up Git ==="
    git config --global init.defaultBranch main
    git config --global core.editor "vim"
    
    # Create directory structure and clone nix config repository
    echo "=== Cloning nix configuration repository ==="
    mkdir -p $HOME/.config
    cd $HOME/.config
    
    # Clone your nix configuration repo
    if [ ! -d "$HOME/.config/nix" ]; then
      git clone https://github.com/svnlto/nix-config.git nix
    fi
    
    # Enable flakes
    mkdir -p $HOME/.config/nix
    echo "experimental-features = nix-command flakes" > $HOME/.config/nix/nix.conf
    
    # Install home-manager and apply configuration
    echo "=== Setting up Home Manager ==="
    export NIXPKGS_ALLOW_UNFREE=1
    nix run home-manager/master -- init --no-flake
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
    
    # Show helpful message
    echo ""
    echo "======================================================="
    echo " Development environment is ready!"
    echo " - Projects directory: ~/projects"
    echo " - Nix config: ~/.config/nix"
    echo "======================================================="
  SHELL
end