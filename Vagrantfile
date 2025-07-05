# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use minimal ARM64 Ubuntu 24.04 box
  config.vm.box = "cloud-image/ubuntu-24.04"
  
  # Increase boot timeout for QEMU
  config.vm.boot_timeout = 600
  config.vm.hostname = "nix-dev"

  # Port forwarding will be handled by QEMU provider settings

  # SSH configuration
  config.ssh.insert_key = true
  config.ssh.forward_agent = true
  
  # Forward a reasonable port range for development (20 ports)
   (3000..3019).each do |port|
     config.vm.network "forwarded_port", guest: port, host: port
   end
   
   # Forward Playwright port
   config.vm.network "forwarded_port", guest: 9222, host: 9222

   # QEMU Provider Configuration
  config.vm.provider "qemu" do |qemu|
    qemu.name = "nix-dev-vm"
    qemu.memory = "8192"
    qemu.arch = "aarch64"
    qemu.machine = "virt,accel=hvf"
    qemu.cpu = "host"
    qemu.net_device = "virtio-net-pci"
    qemu.cpus = 6
    qemu.extra_qemu_args = %w(-display none -smp 6,cores=6,threads=1,sockets=1)
    qemu.disk_size = "80G"
  end

  # System provisioning script
  config.vm.provision "shell", inline: <<-SHELL
    # System dependencies and settings
    echo "=== Setting up system ==="
    apt-get update
    apt-get install -y locales sudo build-essential curl file git unzip zsh

    # Install Docker
    echo "=== Installing and configuring Docker ==="
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    usermod -aG docker vagrant

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
    sudo mkdir -p /etc/nix
    sudo bash -c 'cat > /etc/nix/nix.conf << EOL
experimental-features = nix-command flakes
trusted-users = root vagrant
EOL'
    sudo chown root:root /etc/nix/nix.conf
    sudo chmod 644 /etc/nix/nix.conf

    # Make sure ~/.config/nix directory exists
    mkdir -p $HOME/.config/nix

    # Restart the Nix daemon to apply settings
    sudo systemctl restart nix-daemon

    # Source Nix environment
    if [ -e /etc/profile.d/nix.sh ]; then
      . /etc/profile.d/nix.sh
    fi

    # Verify Nix is working
    echo "Checking Nix version and features..."
    nix --version

    # Basic Git configuration
    git config --global init.defaultBranch main
    git config --global core.editor "vim"

    # Clone your Nix configuration
    echo "=== Setting up Nix configuration ==="
    if [ -d "$HOME/.config/nix" ]; then
      echo "Found existing nix config directory, backing it up..."
      mv $HOME/.config/nix $HOME/.config/nix.bak.$(date +%s)
    fi

    git clone --depth=1 https://github.com/svnlto/nix-config.git $HOME/.config/nix

    # Set proper permissions
    sudo chown -R vagrant:vagrant $HOME/.config/nix
    find $HOME/.config/nix -type d -exec chmod 755 {} \\;
    find $HOME/.config/nix -type f -exec chmod 644 {} \\;

    # Setup minimal ZSH environment
    echo "Setting up minimal ZSH environment..."
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

    # Create minimal .zshrc
    rm -f $HOME/.zshrc
    cat > $HOME/.zshrc <<EOL
# Temporary .zshrc - will be replaced by home-manager
export PS1="%B%F{green}%n@%m%f:%F{blue}%~%f%(!.#.$)%b "
export PATH=\$PATH:\$HOME/.nix-profile/bin
EOL
    chmod 644 $HOME/.zshrc

    echo "=== Initial setup completed ==="
  SHELL

  # Git cleanup provision
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    if [ -L "$HOME/.config/nix/nix.conf" ] && [ -d "$HOME/.config/nix/.git" ]; then
      echo "=== Cleaning up git conflicts ==="
      cd "$HOME/.config/nix"
      git reset --hard HEAD
    fi
  SHELL

  # RAM disk setup
  config.vm.provision "shell", run: "always", privileged: true, inline: <<-SHELL
    echo "=== Setting up RAM disk ==="

    # Unmount if already mounted
    if mount | grep -q "/ramdisk"; then
      echo "Unmounting existing RAM disk..."
      umount /ramdisk 2>/dev/null || true
    fi

    # Create mount point
    rm -rf /ramdisk 2>/dev/null || true
    mkdir -p /ramdisk
    chmod 1777 /ramdisk

    # Mount RAM disk
    echo "Mounting RAM disk..."
    mount -t tmpfs -o size=4G,mode=1777 none /ramdisk

    # Create directories
    mkdir -p /ramdisk/.npm /ramdisk/tmp /ramdisk/.terraform.d/plugin-cache /ramdisk/.pnpm/store
    chmod 1777 /ramdisk/tmp
    chmod 777 /ramdisk/.npm /ramdisk/.terraform.d /ramdisk/.pnpm

    # Set ownership
    chown -R vagrant:vagrant /ramdisk

    echo "RAM disk setup complete"
  SHELL

  # Home Manager setup
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    echo "=== Running home-manager setup ==="

    # Source Nix environment
    if [ -e /etc/profile.d/nix.sh ]; then
      . /etc/profile.d/nix.sh
    fi

    # Run home-manager
    echo "Running home-manager switch command..."
    NIXPKGS_ALLOW_UNFREE=1 nix run home-manager/master -- switch -b backup.$RANDOM --flake ~/.config/nix#vagrant --impure || {
      echo "Home Manager switch failed. See above for errors."
    }
  SHELL

  # Final status
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    echo ""
    echo "=== Development environment ready ==="
    echo "Connect to the VM using: vagrant ssh"
    echo ""

    if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      echo "✅ Home Manager configured successfully!"
    else
      echo "⚠️  Home Manager setup incomplete. To retry manually:"
      echo "  nix run home-manager/master -- switch --flake ~/.config/nix#vagrant --impure"
    fi
  SHELL
end