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
    
    # Setup Nix configuration
    mkdir -p $HOME/.config/nix
    cat > $HOME/.config/nix/nix.conf <<EOL
experimental-features = nix-command flakes
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
trusted-substituters = true
trusted-users = root vagrant
max-jobs = 3
cores = 1
download-buffer-size = 32768
builders-use-substitutes = true
http-connections = 25
keep-outputs = true
keep-derivations = true
EOL
    
    # Install home-manager and apply configuration
    echo "=== Setting up Home Manager ==="
    export NIXPKGS_ALLOW_UNFREE=1
    
    # Apply configuration with optimizations
    echo "=== Applying configuration with Home Manager ==="
    nix run home-manager/master -- init --no-flake
    
    # Apply the flake configuration
    LOCALE_ARCHIVE="" nix run home-manager/master -- switch --flake $HOME/.config/nix#vagrant \
      --impure \
      --option binary-caches-parallel-connections 5 \
      --option narinfo-cache-positive-ttl 43200 \
      --option builders-use-substitutes true
    
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