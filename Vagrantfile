# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Basic VM Configuration
  config.vm.box = "utm/ubuntu-24.04"
  config.vm.hostname = "nix-dev"
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  
  # Fix SSH authentication issues
  config.ssh.insert_key = true
  config.ssh.forward_agent = true
  
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
    
    # Fix SSH permissions
    chmod 700 /home/vagrant/.ssh
    chmod 600 /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
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
    sudo bash -c 'cat > /etc/nix/nix.conf << EOL
experimental-features = nix-command flakes
trusted-users = root vagrant
EOL'
    sudo chown root:root /etc/nix/nix.conf
    sudo chmod 644 /etc/nix/nix.conf
    
    # Make sure ~/.config/nix directory exists
    mkdir -p $HOME/.config/nix
    
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
    
    # Clone configuration with better handling for reprovisioning
    echo "=== Setting up configuration ==="
    mkdir -p $HOME/.config
    
    # Handle existing directory on reprovisioning
    if [ -d "$HOME/.config/nix" ]; then
      echo "Found existing nix config directory, backing it up..."
      mv $HOME/.config/nix $HOME/.config/nix.bak.$(date +%s)
    fi
    
    git clone --depth=1 https://github.com/svnlto/nix-config.git $HOME/.config/nix
    
    # Verify flake.nix exists
    if [ ! -f "$HOME/.config/nix/flake.nix" ]; then
      echo "WARNING: flake.nix not found in repository!"
      exit 1
    fi
    
    # Set proper permissions for the config directory
    sudo chown -R vagrant:vagrant $HOME/.config/nix
    # Fix the find command with proper syntax
    find $HOME/.config/nix -type d -exec chmod 755 {} \\;
    find $HOME/.config/nix -type f -exec chmod 644 {} \\;
    
    # Create minimal ZSH environment to ensure we can login 
    # Home Manager will replace this later
    echo "Setting up minimal ZSH environment..."
    # Ensure we can write to .zshenv
    rm -f $HOME/.zshenv
    cat > $HOME/.zshenv <<EOL
# Source Nix environment
if [ -e /etc/profile.d/nix.sh ]; then
  . /etc/profile.d/nix.sh
fi
EOL
    chmod 644 $HOME/.zshenv
    
    # Set ZSH as default shell
    echo "Setting ZSH as default shell..."
    sudo chsh -s $(which zsh) vagrant
    
    # Create a minimal .zshrc to ensure the shell works
    # This will be overwritten by home-manager once it's properly set up
    echo "Creating temporary .zshrc..."
    # Ensure we can write to .zshrc
    rm -f $HOME/.zshrc
    cat > $HOME/.zshrc <<EOL
# This is a temporary .zshrc that will be replaced by home-manager
# when you manually run: home-manager switch --flake ~/.config/nix#vagrant
export PS1="%B%F{green}%n@%m%f:%F{blue}%~%f%(!.#.$)%b "
export PATH=\$PATH:\$HOME/.nix-profile/bin
EOL
    chmod 644 $HOME/.zshrc

    # Run home-manager switch command AFTER creating the minimal .zshrc
    # This way home-manager can safely replace it with its own configuration
    echo "=== Setting up Home Manager ==="
    echo "Running home-manager switch command..."
    # Use a unique backup extension to avoid conflicts
    NIXPKGS_ALLOW_UNFREE=1 nix run home-manager/master -- switch -b backup.$RANDOM --flake ~/.config/nix#vagrant --impure || {
      # Just mark failure - detailed instructions will appear in startup message
      echo "Home Manager switch failed."
    }
  SHELL

  # Add a special provision step just for git cleanup
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    # Ensure git repo stays clean by dealing with problematic files after home-manager runs
    if [ -L "$HOME/.config/nix/nix.conf" ] && [ -d "$HOME/.config/nix/.git" ]; then
      echo "=== Cleaning up git conflicts ==="
      cd "$HOME/.config/nix"
      
      # Reset git repo state
      git reset --hard HEAD
    fi
  SHELL

  # Minimal startup message with instructions
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    echo ""
    echo "=== Development environment ready ==="
    echo "The VM has been set up with Nix and tools."
    echo ""
    echo "Connect to the VM using:"
    echo "  vagrant ssh"
    echo ""
    
    # Check if home-manager appears to be configured
    if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      echo "Home Manager has been successfully configured!"
    else
      echo "NOTE: Home Manager setup didn't complete successfully."
      echo "To manually run the home-manager setup:"
      echo "  nix run home-manager/master -- switch -b backup.$(date +%s) --flake ~/.config/nix#vagrant --impure"
      echo ""
    fi
  SHELL
end