FROM ubuntu:24.04@sha256:b359f1067efa76f37863778f7b6d0e8d911e3ee8efa807ad01fbf5dc1ef9006b

RUN apt-get update && apt-get install -y --no-install-recommends \
  curl=8.5.0-2ubuntu10.6 \
  git=1:2.43.0-1ubuntu7.3 \
  sudo=1.9.15p5-3ubuntu5.24.04.1 \
  xz-utils=5.6.1+really5.4.5-1ubuntu0.2 \
  ca-certificates=20240203 \
  zsh=5.9-6ubuntu2 \
  && rm -rf /var/lib/apt/lists/*

ARG USERNAME=ubuntu
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENV NIX_VERSION=2.24.10
RUN curl -L https://releases.nixos.org/nix/nix-${NIX_VERSION}/install -o /tmp/nix-install.sh && \
  sh /tmp/nix-install.sh --no-daemon && \
  rm /tmp/nix-install.sh

ENV PATH="/home/${USERNAME}/.nix-profile/bin:${PATH}"
RUN printf '. %s/.nix-profile/etc/profile.d/nix.sh\n' "${HOME}" >> /home/${USERNAME}/.bashrc

RUN mkdir -p /home/${USERNAME}/.config/nix && \
  printf 'experimental-features = nix-command flakes\n' > /home/${USERNAME}/.config/nix/nix.conf

COPY --chown=${USERNAME}:${USERNAME} . /home/${USERNAME}/.config/nix/

WORKDIR /home/${USERNAME}/.config/nix
ENV HOME_MANAGER_VERSION=release-24.05
ENV USER=${USERNAME}
RUN . /home/${USERNAME}/.nix-profile/etc/profile.d/nix.sh && \
  nix run home-manager/${HOME_MANAGER_VERSION} -- switch --flake .#ubuntu -b backup

WORKDIR /home/${USERNAME}

CMD ["/bin/zsh", "-l"]
