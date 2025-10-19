FROM lopsided/archlinux-arm64v8:devel

# Install additional dependencies
RUN pacman -Syu --noconfirm && \
  pacman -S --noconfirm \
  curl \
  git \
  sudo \
  zsh && \
  pacman -Scc --noconfirm

# Create user
ARG USERNAME
RUN useradd -m -s /bin/zsh ${USERNAME} && \
  echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install Nix
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon

# Source Nix in shell
RUN echo ". $HOME/.nix-profile/etc/profile.d/nix.sh" >> "$HOME/.zshrc"

# Copy Nix configuration
COPY --chown=${USERNAME}:${USERNAME} . /home/${USERNAME}/.config/nix/

# Apply home-manager configuration
WORKDIR /home/${USERNAME}/.config/nix
ENV PATH="/home/${USERNAME}/.nix-profile/bin:${PATH}"
ARG USERNAME
ENV USER=${USERNAME}
RUN nix run home-manager -- switch --flake .#minimal-arm -b backup

WORKDIR /home/${USERNAME}

CMD ["/bin/zsh"]
