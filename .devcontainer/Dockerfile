# .devcontainer/Dockerfile
# Builds the ghcr.io/effortlesssteven/ytp-devcontainer base image

ARG NIXPKGS_CHANNEL=24.11

# --- Stage 0: Base OS & Essential System Packages ---
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/base:1-bookworm AS base_os
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    sudo \
    procps \
    # Add any other absolutely essential system tools needed *before* Nix
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Setup vscode user with passwordless sudo (base image usually does this, but good to be explicit)
RUN echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# --- Stage 1: Nix Installation ---
FROM base_os AS nix_installer
ARG NIXPKGS_CHANNEL
ARG USERNAME=vscode

# Install Nix (using Determinate Systems installer for robustness)
# This runs as root
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm
ENV PATH="/nix/var/nix/profiles/default/bin:${PATH}"

# Basic Nix configuration (as root)
RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
    echo "trusted-users = root ${USERNAME}" >> /etc/nix/nix.conf && \
    (getent group nixbld >/dev/null || groupadd nixbld) && \
    usermod -aG nixbld ${USERNAME}

# Add NixOS channel for legacy nix-env package installation
RUN nix-channel --add https://nixos.org/channels/nixos-${NIXPKGS_CHANNEL} nixpkgs && \
    nix-channel --update

# --- Stage 2: Global Dev Tools Installation (via Nix, as USER root) ---
# This ensures direnv and devbox are in vscode's Nix profile.
FROM nix_installer AS global_tools
ARG USERNAME=vscode
USER root
WORKDIR /home/${USERNAME}

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    echo 'Installing direnv and devbox into system Nix profile...' && \
    nix-env -iA nixpkgs.direnv nixpkgs.devbox && \
    echo 'direnv and devbox installed.'

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# --- Stage 3: Rust Toolchain & Cargo Cache Warming (as USER vscode) ---
# This stage pre-fetches Rust and common dependencies based on YOUR project.
FROM global_tools AS cache_warmer
ARG USERNAME=vscode
ARG RUST_TOOLCHAIN_VERSION="1.86.0"
USER ${USERNAME}
WORKDIR /tmp/project_bootstrap_cache_warm

# Copy project files needed for dependency resolution and fetching
COPY --chown=${USERNAME}:${USERNAME} devbox.json ./
COPY --chown=${USERNAME}:${USERNAME} Cargo.toml ./
COPY --chown=${USERNAME}:${USERNAME} Cargo.lock ./
# Copy src if 'cargo fetch' needs to parse it (less common for just fetch)
COPY --chown=${USERNAME}:${USERNAME} src/ ./src/

# Copy the cache warmup script into this build stage
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/cache-warmup.sh /usr/local/bin/cache-warmup.sh
RUN chmod +x /usr/local/bin/cache-warmup.sh

# Skipping Devbox install and Rust cache warming during Docker build.
# Devbox environment and cache-warmup will be handled at container runtime via postCreateCommand.

# --- Stage 4: Final Production Image ---
# Start from a clean slim base to reduce size, then copy artifacts.
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/base:1-bookworm AS final_image
ARG USERNAME=vscode

ENV DEBIAN_FRONTEND=noninteractive
# Install only absolutely essential runtime deps if any (git, curl are good for dev image)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    sudo \
    procps \
    # Add lld if you plan to use it via RUSTFLAGS and it's not provided by Nix/Devbox
    # lld \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Copy the entire Nix store (contains all dependencies)
COPY --from=nix_installer /nix /nix

# Set up vscode user and environment (ensure this matches base image or is correctly set)
# The base:bookworm should already have vscode user.
# Ensure sudoers setup if not present in base_os layer or inherited correctly.
RUN echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Create user directories with proper ownership as root first
RUN mkdir -p \
    /home/${USERNAME}/.config \
    /home/${USERNAME}/.cache \
    /home/${USERNAME}/.local/share \
    /home/${USERNAME}/.local/share/direnv \
    /home/${USERNAME}/.cargo \
    /home/${USERNAME}/.rustup \
    && chown -R ${USERNAME}:${USERNAME} \
       /home/${USERNAME}/.config \
       /home/${USERNAME}/.cache \
       /home/${USERNAME}/.local \
       /home/${USERNAME}/.cargo \
       /home/${USERNAME}/.rustup

USER ${USERNAME}
ENV PATH="/home/${USERNAME}/.nix-profile/bin:/home/${USERNAME}/.cargo/bin:${PATH}"
ENV CARGO_HOME="/home/${USERNAME}/.cargo"
ENV RUSTUP_HOME="/home/${USERNAME}/.rustup"

WORKDIR /workspaces

# Removed static OCI labels; labels will be injected via CI metadata

CMD ["bash"] 