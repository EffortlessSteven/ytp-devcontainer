# .devcontainer/Dockerfile
# Builds the ghcr.io/effortlesssteven/ytp-devcontainer base image

ARG NIXPKGS_CHANNEL=24.11

# --- Stage 0: Base OS & Essential System Packages ---
FROM mcr.microsoft.com/devcontainers/base:1-bookworm AS base_os
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    sudo \
    procps \
    build-essential \
    pkg-config \
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
# Use --extra-conf to handle ARM64 seccomp issues in GitHub Actions
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
    --init none \
    --no-confirm \
    --extra-conf "filter-syscalls = false" \
    --extra-conf "sandbox = false"
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

# --- Stage 2: Global Dev Tools Installation ---
FROM nix_installer AS global_tools
ARG USERNAME=vscode

# Install direnv using official installer (more reliable than Nix for this use case)
RUN curl -sfL https://direnv.net/install.sh | bash

# Install devbox using official installer (more reliable than Nix)
RUN curl -fsSL https://get.jetpack.io/devbox | bash -s -- -f

# Verify installations
RUN which direnv && direnv --version
RUN which devbox && devbox version

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

# Configure Cargo for maximum operational speed
ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
ENV CARGO_TERM_COLOR=always

# Install rustup and the specified Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain none && \
    rustup default "${RUST_TOOLCHAIN_VERSION}" && \
    rustup component add clippy rustfmt

# Create optimized Cargo configuration for fast builds and operations
RUN mkdir -p "${CARGO_HOME}" && \
    echo '[build]' > "${CARGO_HOME}/config.toml" && \
    echo '# Use lld on x86_64, default linker on other architectures for compatibility' >> "${CARGO_HOME}/config.toml" && \
    echo '[target.x86_64-unknown-linux-gnu]' >> "${CARGO_HOME}/config.toml" && \
    echo 'linker = "clang"' >> "${CARGO_HOME}/config.toml" && \
    echo 'rustflags = ["-C", "link-arg=-fuse-ld=lld"]' >> "${CARGO_HOME}/config.toml" && \
    echo '' >> "${CARGO_HOME}/config.toml" && \
    echo '[profile.dev]' >> "${CARGO_HOME}/config.toml" && \
    echo 'incremental = true' >> "${CARGO_HOME}/config.toml" && \
    echo '' >> "${CARGO_HOME}/config.toml" && \
    echo '[registries.crates-io]' >> "${CARGO_HOME}/config.toml" && \
    echo 'protocol = "sparse"' >> "${CARGO_HOME}/config.toml"

# Pre-configure direnv for common workspace paths to reduce startup time
RUN mkdir -p /home/${USERNAME}/.local/share/direnv/allow && \
    echo "/workspaces" > /home/${USERNAME}/.local/share/direnv/allow/$(echo "/workspaces" | sha256sum | cut -d' ' -f1)

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

# Install performance-focused cargo extensions for runtime development speed
# Ensure platform equivalency - all tools available on all architectures
RUN set -e; \
    ARCH=$(uname -m); \
    echo "Installing cargo tools for $ARCH (ensuring platform equivalency)"; \
    # cargo-nextest - use pre-compiled binary on x86_64, compile on others
    if [ "$ARCH" = "x86_64" ]; then \
        echo "Using pre-compiled cargo-nextest for x86_64..."; \
        curl -LsSf https://get.nexte.st/latest/linux | tar zxf - -C ${CARGO_HOME}/bin || \
        { echo "Pre-compiled install failed, compiling from source..."; cargo install --locked cargo-nextest --quiet; }; \
    else \
        echo "Compiling cargo-nextest from source for $ARCH..."; \
        cargo install --locked cargo-nextest --quiet; \
    fi && \
    # cargo-watch and cargo-expand - compile from source (lightweight, fast on all platforms)
    echo "Installing cargo-watch and cargo-expand..." && \
    cargo install --locked cargo-watch --quiet && \
    cargo install --locked cargo-expand --quiet && \
    echo "All cargo tools installed successfully for $ARCH"

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
    build-essential \
    clang \
    lld \
    hyperfine \
    fd-find \
    ripgrep \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && PATH="/root/.local/bin:$PATH" uv tool install yt-dlp \
    && curl -sfL https://direnv.net/install.sh | bash \
    && mv /usr/local/sbin/direnv /usr/local/bin/direnv \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Copy the entire Nix store (contains all dependencies like direnv installed by root)
COPY --from=nix_installer /nix /nix

# Copy devbox binary from global_tools stage
COPY --from=global_tools /usr/local/bin/devbox /usr/local/bin/devbox
RUN chmod 755 /usr/local/bin/devbox && chown root:root /usr/local/bin/devbox

# Copy pre-installed Rust toolchain and Cargo caches from the cache_warmer stage
COPY --from=cache_warmer --chown=${USERNAME}:${USERNAME} /home/${USERNAME}/.rustup /home/${USERNAME}/.rustup
COPY --from=cache_warmer --chown=${USERNAME}:${USERNAME} /home/${USERNAME}/.cargo /home/${USERNAME}/.cargo

# Copy pre-configured direnv allowlist to reduce startup direnv operations
COPY --from=cache_warmer --chown=${USERNAME}:${USERNAME} /home/${USERNAME}/.local/share/direnv/allow /home/${USERNAME}/.local/share/direnv/allow

# Setup vscode user and sudoers (ensure this matches base image or is correctly set)
RUN echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Configure Nix store permissions for vscode user
RUN if ! getent group nixbld >/dev/null; then groupadd -r nixbld; fi && \
    chgrp -R nixbld /nix/var/nix/db && \
    chmod -R g+w /nix/var/nix/db && \
    usermod -aG nixbld "${USERNAME}"

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
ENV PATH="/home/${USERNAME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/home/${USERNAME}/.cargo/bin:/usr/local/bin:/root/.local/bin:${PATH}"
ENV CARGO_HOME="/home/${USERNAME}/.cargo"
ENV RUSTUP_HOME="/home/${USERNAME}/.rustup"
# DEVBOX_GLOBAL_PROFILE might be set by Devbox automatically, but explicitly setting it can help
ENV DEVBOX_GLOBAL_PROFILE="/home/${USERNAME}/.local/share/devbox/global/default"
# Ensure direnv can find its data dir if it doesn't default to XDG_DATA_HOME
ENV XDG_DATA_HOME="/home/${USERNAME}/.local/share"
# Configure sccache directory for when it's available
ENV SCCACHE_DIR="/home/${USERNAME}/.cache/sccache"

WORKDIR /workspaces

# Default command
CMD ["bash"] 