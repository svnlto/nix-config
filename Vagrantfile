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
    
    # Create system Nix configuration with experimental features
    # This needs to be done RIGHT AFTER Nix installation
    sudo mkdir -p /etc/nix
    echo 'experimental-features = nix-command flakes' | sudo tee /etc/nix/nix.conf
    echo 'trusted-users = root vagrant' | sudo tee -a /etc/nix/nix.conf
    sudo chown root:root /etc/nix/nix.conf
    sudo chmod 644 /etc/nix/nix.conf
    
    # Create user-specific Nix configuration as well
    mkdir -p $HOME/.config/nix
    echo 'experimental-features = nix-command flakes' > $HOME/.config/nix/nix.conf
    
    # Restart the Nix daemon to apply settings BEFORE sourcing Nix
    sudo systemctl restart nix-daemon
    
    # NOW source Nix environment (after config has been created & daemon restarted)
    if [ -e /etc/profile.d/nix.sh ]; then
      . /etc/profile.d/nix.sh
    fi
    
    # Verify Nix is working with experimental features
    echo "Checking Nix version and features..."
    nix --version
    echo "Testing experimental features directly..."
    nix-env --version  # Should work without extra flags now
    
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
    rm -f $HOME/.zshrc $HOME/.zprofile $HOME/.zshenv
    
    # Install basic tools directly (this skips home-manager for now)
    echo "=== Installing basic tools ==="
    nix-env -iA nixpkgs.zsh nixpkgs.git
    
    # Create zshenv with proper permissions
    echo "Setting up ZSH environment..."
    touch $HOME/.zshenv
    chmod 644 $HOME/.zshenv
    cat > $HOME/.zshenv <<EOL
# Source Nix environment
if [ -e /etc/profile.d/nix.sh ]; then
  . /etc/profile.d/nix.sh
fi
EOL
    
    # Set ZSH as default shell
    echo "Setting ZSH as default shell..."
    sudo chsh -s $(which zsh) vagrant
    
    # Create a minimal .zshrc to ensure the shell works
    # This will be overwritten by home-manager once it's properly set up
    echo "Creating temporary .zshrc..."
    cat > $HOME/.zshrc <<EOL
# This is a temporary .zshrc that will be replaced by home-manager
# when you manually run: home-manager switch --flake ~/.config/nix#vagrant
export PS1="%B%F{green}%n@%m%f:%F{blue}%~%f%(!.#.$)%b "
export PATH=\$PATH:\$HOME/.nix-profile/bin
EOL
  SHELL

  # Minimal startup message with instructions
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    echo ""
    echo "=== Development environment partially ready ==="
    echo "The VM has been set up with Nix and basic tools."
    echo ""
    echo "To complete your home-manager setup, connect to the VM using:"
    echo "  vagrant ssh"
    echo ""
    echo "Then run the following command:"
    echo "  nix run home-manager/master -- switch --flake ~/.config/nix#vagrant --impure"
    echo ""
  SHELL
end