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
  
  # Main provisioning script - combines system and user setup
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

    # Switch to user for personal setup
    su - vagrant <<'USERSCRIPT'
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
      
      # Clone configuration
      echo "=== Setting up configuration ==="
      mkdir -p $HOME/.config
      cd $HOME/.config
      
      if [ ! -d "$HOME/.config/nix" ]; then
        git clone https://github.com/svnlto/nix-config.git nix
      fi
      
      # Clean up potentially conflicting files
      rm -f $HOME/.zshrc $HOME/.zprofile $HOME/.config/nix/nix.conf
      
      # Minimal system-wide Nix config
      sudo mkdir -p /etc/nix
      echo "experimental-features = nix-command flakes" | sudo tee /etc/nix/nix.conf
      echo "trusted-users = root vagrant" | sudo tee -a /etc/nix/nix.conf
      sudo systemctl restart nix-daemon
      
      # Setup home-manager
      echo "=== Setting up Home Manager ==="
      export NIXPKGS_ALLOW_UNFREE=1
      nix run home-manager/master -- init --no-flake
      LOCALE_ARCHIVE="" nix run home-manager/master -- switch --flake $HOME/.config/nix#vagrant --impure
      
      # Create minimal zshenv for proper environment sourcing
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
USERSCRIPT
  SHELL

  # Minimal startup message
  config.vm.provision "shell", run: "always", inline: <<-SHELL
    echo ""
    echo "=== Development environment ready ==="
    echo "Use 'vagrant ssh' to connect with your ZSH configuration"
  SHELL
end