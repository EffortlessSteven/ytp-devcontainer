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
RUN echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

# --- Stage 1: Nix Installation ---
FROM base_os AS nix_installer
ARG NIXPKGS_CHANNEL
ARG USERNAME=vscode

# Install Nix (using Determinate Systems installer for robustness)
# This runs as root
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm
ENV PATH="/nix/var/nix/profiles/default/bin:${PATH}"

# Basic Nix configuration (as root)
# Ensure /etc/nix exists before trying to write to nix.conf
RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
    echo "trusted-users = root ${USERNAME}" >> /etc/nix/nix.conf

# Ensure nixbld group exists and USERNAME is part of it
# This should run after USERNAME is defined and before it's used in trusted-users or usermod
RUN if ! getent group nixbld >/dev/null; then groupadd -r nixbld; fi && \
    usermod -aG nixbld "${USERNAME}"

# Add NixOS channel for legacy nix-env package installation
RUN nix-channel --add https://nixos.org/channels/nixos-${NIXPKGS_CHANNEL} nixpkgs && \
    nix-channel --update

# --- Stage 2: Global Dev Tools Installation (via Nix, as USER root) ---
# This ensures direnv and devbox are in the system's Nix profile.
FROM nix_installer AS global_tools
ARG USERNAME=vscode
# USER root (already root from nix_installer stage)

# Source Nix environment for root before running nix-env
# and ensure nix-daemon is running or simulated for this command.
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    echo 'Installing direnv and devbox into system Nix profile...' && \
    nix-env -iA nixpkgs.direnv nixpkgs.devbox && \
    echo 'direnv and devbox installed.'

# --- Stage 3: Rust Toolchain & Cargo Cache Warming (as USER vscode) ---
# This stage is responsible for setting up Rust for the vscode user and warming caches.
FROM global_tools AS cache_warmer
ARG USERNAME=vscode
ARG RUST_TOOLCHAIN_VERSION="1.86.0" # Ensure this matches the rust-toolchain.toml in your project

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Set up user-specific environment variables for Rust
ENV RUSTUP_HOME="/home/${USERNAME}/.rustup"
ENV CARGO_HOME="/home/${USERNAME}/.cargo"
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"

# Install rustup and the specified Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain none && \
    rustup default "${RUST_TOOLCHAIN_VERSION}" && \
    rustup component add clippy rustfmt

# Create a temporary dummy project to warm up common caches
WORKDIR /tmp/project_bootstrap_cache_warm
COPY --chown=${USERNAME}:${USERNAME} rust-toolchain.toml ./
# Copy project files needed for dependency resolution and fetching
COPY --chown=${USERNAME}:${USERNAME} Cargo.toml ./
COPY --chown=${USERNAME}:${USERNAME} Cargo.lock ./
# Copy src if 'cargo fetch' needs to parse it
COPY --chown=${USERNAME}:${USERNAME} src/ ./src/

# Copy the cache warmup script into this build stage and execute it
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/cache-warmup.sh /usr/local/bin/cache-warmup.sh
RUN chmod +x /usr/local/bin/cache-warmup.sh && \
    /usr/local/bin/cache-warmup.sh

# Clean up dummy project
WORKDIR /home/${USERNAME}
RUN rm -rf /tmp/project_bootstrap_cache_warm

# --- Stage 4: Final Production Image ---
FROM mcr.microsoft.com/devcontainers/base:1-bookworm AS final_image
ARG USERNAME=vscode

ENV DEBIAN_FRONTEND=noninteractive
# Install only absolutely essential runtime deps if any (git, curl, sudo, procps are good for dev image)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    sudo \
    procps \
    # Add lld if you plan to use it via RUSTFLAGS
    # lld \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Copy the entire Nix store (contains all dependencies like devbox, direnv installed by root)
COPY --from=nix_installer /nix /nix

# Copy pre-installed Rust toolchain and Cargo caches from the cache_warmer stage
COPY --from=cache_warmer --chown=${USERNAME}:${USERNAME} /home/${USERNAME}/.rustup /home/${USERNAME}/.rustup
COPY --from=cache_warmer --chown=${USERNAME}:${USERNAME} /home/${USERNAME}/.cargo /home/${USERNAME}/.cargo

# Setup vscode user and sudoers (ensure this matches base image or is correctly set)
RUN echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Configure Git system-wide to trust the workspace directory
# This prevents "dubious ownership" errors when Git operations run in VS Code
RUN git config --system --add safe.directory /workspaces/ytp-devcontainer-public

# Additional Git configuration for container environment
RUN git config --system core.autocrlf input && \
    git config --system init.defaultBranch main && \
    git config --system pull.rebase false && \
    git config --system core.sshCommand "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# Create user directories with proper ownership as root first, THEN switch to user
# This ensures these base directories are correctly owned by vscode FROM THE IMAGE ITSELF.
RUN mkdir -p \
    "/home/${USERNAME}/.config" \
    "/home/${USERNAME}/.cache" \
    "/home/${USERNAME}/.local/bin" \
    "/home/${USERNAME}/.local/share" \
    "/home/${USERNAME}/.local/share/devbox/global" \
    "/home/${USERNAME}/.local/share/direnv" \
    "/home/${USERNAME}/.ssh" \
    "/home/${USERNAME}/.gnupg" \
    # Note: .cargo and .rustup are copied from cache_warmer, so they'll exist.
    # Just ensure their parent .home/$USERNAME is owned by vscode.
    && chown -R "${USERNAME}:${USERNAME}" \
       "/home/${USERNAME}" # Chown the entire home directory after creating subdirs

USER ${USERNAME}

# Set up environment variables for the vscode user
# Path order: User's Nix profile, System Nix profile, User's Cargo, original PATH
ENV PATH="/home/${USERNAME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/home/${USERNAME}/.cargo/bin:${PATH}"
ENV CARGO_HOME="/home/${USERNAME}/.cargo"
ENV RUSTUP_HOME="/home/${USERNAME}/.rustup"
# DEVBOX_GLOBAL_PROFILE might be set by Devbox automatically, but explicitly setting it can help
ENV DEVBOX_GLOBAL_PROFILE="/home/${USERNAME}/.local/share/devbox/global/default"
# Ensure direnv can find its data dir if it doesn't default to XDG_DATA_HOME
ENV XDG_DATA_HOME="/home/${USERNAME}/.local/share"

WORKDIR /workspaces

# Default command
CMD ["bash"] 