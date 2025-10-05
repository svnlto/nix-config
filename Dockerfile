FROM ubuntu:24.04@sha256:b359f1067efa76f37863778f7b6d0e8d911e3ee8efa807ad01fbf5dc1ef9006b

# Install dependencies (versions locked by base image digest)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    sudo \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Use existing ubuntu user and grant sudo access
ARG USERNAME=ubuntu
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install Nix (pinned version)
ENV NIX_VERSION=2.24.10
RUN curl -L https://releases.nixos.org/nix/nix-${NIX_VERSION}/install -o /tmp/nix-install.sh && \
    sh /tmp/nix-install.sh --no-daemon && \
    rm /tmp/nix-install.sh

# Set up Nix in PATH
ENV PATH="/home/${USERNAME}/.nix-profile/bin:${PATH}"
RUN printf '. %s/.nix-profile/etc/profile.d/nix.sh\n' "${HOME}" >> /home/${USERNAME}/.bashrc

# Configure Nix for flakes
RUN mkdir -p /home/${USERNAME}/.config/nix && \
    printf 'experimental-features = nix-command flakes\n' > /home/${USERNAME}/.config/nix/nix.conf

# Copy the Nix configuration
COPY --chown=${USERNAME}:${USERNAME} . /home/${USERNAME}/.config/nix/

# Apply home-manager configuration (pinned to release-24.05)
WORKDIR /home/${USERNAME}/.config/nix
ENV HOME_MANAGER_VERSION=release-24.05
ENV USER=${USERNAME}
RUN . /home/${USERNAME}/.nix-profile/etc/profile.d/nix.sh && \
    nix run home-manager/${HOME_MANAGER_VERSION} -- switch --flake .#ubuntu -b backup

# Set working directory to home
WORKDIR /home/${USERNAME}

# Default to bash with Nix environment loaded
CMD ["/bin/bash", "-l"]
