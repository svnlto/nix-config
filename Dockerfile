# Stage 1: Builder — install Nix, run home-manager switch
FROM ubuntu:24.04 AS builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG USERNAME
ARG UID=1000
ARG GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
  curl=8.5.0-2ubuntu10.7 \
  ca-certificates=20240203 \
  xz-utils=5.6.1+really5.4.5-1ubuntu0.2 \
  git=1:2.43.0-1ubuntu7.3 \
  && rm -rf /var/lib/apt/lists/*

RUN userdel -r ubuntu 2>/dev/null; groupdel ubuntu 2>/dev/null; \
  groupadd -g ${GID} ${USERNAME} \
  && useradd -l -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}

RUN curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install linux \
  --extra-conf "trusted-users = root ${USERNAME}" \
  --init none --no-confirm

ENV PATH="/nix/var/nix/profiles/default/bin:${PATH}"
RUN mkdir -p /etc/nix \
  && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# Prepare home directory structure for home-manager activation
RUN mkdir -p /home/${USERNAME}/.config/nix \
  /home/${USERNAME}/.local/state/nix/profiles \
  /home/${USERNAME}/.local/state/home-manager \
  /nix/var/nix/profiles/per-user/${USERNAME} \
  && chown -R ${UID}:${GID} /home/${USERNAME}

# Layer cache: flake lock changes rarely, so fetch deps first
COPY flake.nix flake.lock /home/${USERNAME}/.config/nix/
RUN chown -R ${UID}:${GID} /home/${USERNAME}/.config/nix

ENV USER=${USERNAME} HOME=/home/${USERNAME}

# Pre-fetch flake deps (cached until flake.lock changes)
RUN nix-daemon & sleep 1 \
  && su -s /bin/sh ${USERNAME} -c " \
  export PATH=/nix/var/nix/profiles/default/bin:\$PATH USER=${USERNAME} HOME=/home/${USERNAME} \
  && cd /home/${USERNAME}/.config/nix \
  && nix flake archive"

# Now copy full config and build
COPY . /home/${USERNAME}/.config/nix/
RUN chown -R ${UID}:${GID} /home/${USERNAME}/.config/nix

WORKDIR /home/${USERNAME}/.config/nix
RUN set -e; \
  export PROFILE; \
  PROFILE=$(if [ "$(uname -m)" = "aarch64" ]; then echo minimal-arm; else echo minimal-x86; fi); \
  nix-daemon & sleep 1; \
  su -s /bin/sh ${USERNAME} -c " \
  export PATH=/nix/var/nix/profiles/default/bin:\$PATH USER=${USERNAME} HOME=/home/${USERNAME} \
  && cd /home/${USERNAME}/.config/nix \
  && nix run home-manager -- switch --flake .#\$PROFILE -b backup"

# Prune build-only deps from the store
RUN nix-daemon & sleep 1 \
  && nix-collect-garbage -d \
  && rm -rf /nix/var/nix/temproots/* /nix/var/log/nix/*

# -----------------------------------------------------------
# Stage 2: Runtime — slim glibc base, everything useful comes from Nix
FROM debian:bookworm-slim
ARG USERNAME
ARG UID=1000
ARG GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates=20230311+deb12u1 \
  locales=2.36-9+deb12u13 \
  && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
  && locale-gen \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g ${GID} ${USERNAME} \
  && useradd -l -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}

ENV LANG=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8

# Copy pruned Nix store and user profile (ownership preserved from builder)
COPY --from=builder /nix /nix
COPY --from=builder /home/${USERNAME} /home/${USERNAME}

ENV USER=${USERNAME} \
  HOME=/home/${USERNAME} \
  PATH="/home/${USERNAME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:${PATH}" \
  NIX_PROFILES="/nix/var/nix/profiles/default /home/${USERNAME}/.nix-profile" \
  NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
  GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt

USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["zsh", "-l"]
