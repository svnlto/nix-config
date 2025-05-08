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
    utm.memory = "8192"
    utm.cpus = 4
    utm.name = "nix-dev-vm"
    utm.directory_share_mode = "virtFS"
  end
  
  # System provisioning script
  config.vm.provision "shell", inline: <<-SHELL
    # System dependencies and settings
    echo "=== Setting up system ==="
    apt-get update
    apt-get install -y locales sudo build-essential curl file git unzip zsh
    
    # Generate required locales
    localedef -i en_US -f UTF-8 en_US.UTF-8
    localedef -i en_GB -f UTF-8 en_GB.UTF-8
    echo "LANG=en_US.UTF-8" > /etc/default/locale
    echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
    
    # Setup user environment
    echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant
    mkdir -p /home/vagrant/projects
    chown -R vagrant:vagrant /home/vagrant/projects
    
    # Optimize system
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
    sysctl -p

    # Minimal system-wide Nix config (only what's needed to bootstrap)
    mkdir -p /etc/nix
    cat > /etc/nix/nix.conf <<EOL
experimental-features = nix-command flakes
trusted-users = root vagrant
EOL
  SHELL

  # User provisioning script
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    # Environment variables
    export HOME=/home/vagrant
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    
    # Install Nix
    echo "=== Installing Nix ==="
    sh <(curl -L https://nixos.org/nix/install) --daemon
    . /etc/profile.d/nix.sh
    
    # Basic Git configuration
    git config --global init.defaultBranch main
    git config --global core.editor "vim"
    
    # Clone configuration (shallow clone to avoid dirty tree issues)
    echo "=== Setting up configuration ==="
    mkdir -p $HOME/.config
    
    if [ ! -d "$HOME/.config/nix" ]; then
      git clone --depth=1 https://github.com/svnlto/nix-config.git $HOME/.config/nix
    fi
    
    # Clean up potentially conflicting files with proper permissions
    rm -f $HOME/.zshrc $HOME/.zprofile $HOME/.zshenv $HOME/.config/nix/nix.conf
    
    # Restart the Nix daemon to apply settings
    sudo systemctl restart nix-daemon
    . /etc/profile.d/nix.sh
    
    # Setup home-manager
    echo "=== Setting up Home Manager ==="
    export NIXPKGS_ALLOW_UNFREE=1
    
    # Apply the flake configuration
    echo "=== Switching to Home Manager configuration ==="
    nix run home-manager/master -- init --no-flake
    LOCALE_ARCHIVE="" nix run home-manager/master -- switch --flake $HOME/.config/nix#vagrant --impure
    
    # Create zshenv with proper permissions
    touch $HOME/.zshenv
    chmod 644 $HOME/.zshenv
    cat > $HOME/.zshenv <<EOL
# Source Nix environment
if [ -e /etc/profile.d/nix.sh ]; then
  . /etc/profile.d/nix.sh
fi
# Source home-manager session variables
if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi
EOL
    
    # Set ZSH as default shell
    sudo chsh -s $(which zsh) vagrant
  SHELL

  # Minimal startup message
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    echo ""
    echo "=== Development environment ready ==="
    echo "Use 'vagrant ssh' to connect with your ZSH configuration"
  SHELL
end