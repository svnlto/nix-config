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
    utm.name = "nix-dev-vm"
    utm.memory = "8192"
    utm.cpus = 4
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
    
    # Set proper permissions for the config directory
    sudo chown -R vagrant:vagrant $HOME/.config/nix

    find $HOME/.config/nix -type d -exec chmod 755 {} \\;
    find $HOME/.config/nix -type f -exec chmod 644 {} \\;
    
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
    
    echo "Setting ZSH as default shell..."
    sudo chsh -s $(which zsh) vagrant
    
    # Create a minimal .zshrc to ensure the shell works
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

    # Home Manager will be run AFTER the RAM disk setup in a separate provision step
    echo "=== Initial setup completed ==="
    echo "RAM disk and configuration will be set up next"
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
  
  # Initial RAM disk setup - handle everything here
  config.vm.provision "shell", run: "always", privileged: true, inline: <<-SHELL
    echo "=== Setting up RAM disk ==="
    
    # Unmount if already mounted but with issues
    if mount | grep -q "/ramdisk"; then
      echo "Unmounting existing RAM disk to ensure clean setup..."
      umount /ramdisk 2>/dev/null || true
    fi
    
    # Ensure base directory exists with correct permissions
    echo "Creating RAM disk mount point..."
    rm -rf /ramdisk 2>/dev/null || true
    mkdir -p /ramdisk
    chmod 1777 /ramdisk
    
    # Mount fresh RAM disk
    echo "Mounting RAM disk..."
    mount -t tmpfs -o size=2G,mode=1777 none /ramdisk
    if mount | grep -q "/ramdisk"; then
      echo "RAM disk successfully mounted"
    else
      echo "ERROR: Failed to mount RAM disk"
      exit 1
    fi
    
    # Create the necessary directories and set permissions
    echo "Setting up RAM disk directories and permissions..."
    mkdir -p /ramdisk/.npm /ramdisk/tmp /ramdisk/.terraform.d/plugin-cache /ramdisk/.pnpm/store
    chmod 1777 /ramdisk/tmp
    chmod 1777 /ramdisk  # Ensure the base directory is writable by all
    chmod 777 /ramdisk/.npm /ramdisk/.terraform.d /ramdisk/.pnpm
    
    # Make sure everything is owned by the vagrant user
    chown -R vagrant:vagrant /ramdisk
    
    # Verify permissions
    echo "Verifying permissions..."
    ls -la /ramdisk
    
    echo "RAM disk setup complete"
  SHELL

  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    echo "=== Running home-manager setup ==="
    
    # Source Nix environment
    if [ -e /etc/profile.d/nix.sh ]; then
      . /etc/profile.d/nix.sh
    fi
    
    echo "Checking RAM disk status..."
    ls -la /ramdisk
    
    # Now run home-manager with RAM disk available
    echo "Running home-manager switch command..."
    NIXPKGS_ALLOW_UNFREE=1 nix run home-manager/master -- switch -b backup.$RANDOM --flake ~/.config/nix#vagrant --impure || {
      echo "Home Manager switch failed. See above for errors."
    }
  SHELL

  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    echo ""
    echo "=== Development environment ready ==="
    echo "The VM has been set up with Nix and tools."
    echo ""
    echo "Connect to the VM using:"
    echo "  vagrant ssh"
    echo ""
    
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