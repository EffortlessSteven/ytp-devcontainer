# .devcontainer/Dockerfile
# Builds the ghcr.io/effortlesssteven/ytp-devcontainer base image

# --- Stage 0: Base OS & Essential System Packages ---
FROM mcr.microsoft.com/devcontainers/base:bookworm-slim AS base_os
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

# --- Stage 2: Global Dev Tools Installation (via Nix, as USER vscode) ---
# This ensures direnv and devbox are in vscode's Nix profile.
FROM nix_installer AS global_tools
ARG USERNAME=vscode
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Source the Nix profile script to make 'nix-env' available for this user context
# Then install direnv and devbox into the user's Nix profile.
RUN bash -ic ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    echo 'Installing direnv and devbox into user Nix profile...' && \
    nix-env -iA nixpkgs.direnv nixpkgs.devbox && \
    echo 'direnv and devbox installed.'"

# --- Stage 3: Rust Toolchain & Cargo Cache Warming (as USER vscode) ---
# This stage pre-fetches Rust and common dependencies based on YOUR project.
FROM global_tools AS cache_warmer
ARG USERNAME=vscode
ARG RUST_TOOLCHAIN_VERSION="1.86.0" # Use consistent ARG name for Rust toolchain version
USER ${USERNAME}
WORKDIR /tmp/project_bootstrap_cache_warm

# Copy project files needed for dependency resolution and fetching
COPY --chown=${USERNAME}:${USERNAME} devbox.json ./
COPY --chown=${USERNAME}:${USERNAME} Cargo.toml ./
COPY --chown=${USERNAME}:${USERNAME} Cargo.lock ./
# Copy src if 'cargo fetch' needs to parse it (less common for just fetch)
COPY --chown=${USERNAME}:${USERNAME} src/ ./src/

# Activate Devbox environment (which installs Rust from devbox.json)
# and then fetch dependencies for multiple targets.
# The 'direnv allow .' and 'use devbox' combo is more for interactive;
# for scripting, 'devbox shell -c' or 'devbox run' is better.
RUN echo "Warming Rust toolchain (target: ${RUST_TOOLCHAIN_VERSION}) and Cargo caches..." && \
    bash -ic "\
    set -euxo pipefail; \
    echo \"User: $(id -un)\"; \
    echo \"Devbox version:\"; devbox version; \
    echo \"Installing Devbox packages (init_hook will install Rust ${RUST_TOOLCHAIN_VERSION})...\"; \
    devbox install; \
    echo \"Running Devbox shell for cache warming and init_hook trigger...\"; \
    devbox shell -c '\\
        echo \"[Cache Warming] init_hook ran\"; \
        echo \"Active Rust:\"; rustc --version; \
        echo \"Active Cargo:\"; cargo --version; \
        echo \"Fetching Cargo deps (default target)...\"; cargo fetch; \
        echo \"Fetching for x86_64-unknown-linux-gnu...\"; cargo fetch --target x86_64-unknown-linux-gnu; \
        echo \"Adding and fetching for aarch64-unknown-linux-gnu...\"; \
        rustup target add aarch64-unknown-linux-gnu || true; \
        cargo fetch --target aarch64-unknown-linux-gnu || true; \
        echo \"Cache warming complete.\"' \
    "

# --- Stage 4: Final Production Image ---
# Start from a clean slim base to reduce size, then copy artifacts.
FROM mcr.microsoft.com/devcontainers/base:bookworm-slim AS final_image
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

# Copy the vscode user's Nix profile (contains direnv, devbox)
COPY --from=global_tools --chown=${USERNAME}:${USERNAME} /home/${USERNAME}/.nix-profile /home/${USERNAME}/.nix-profile

# Copy pre-warmed Cargo caches and Rustup installation
COPY --from=cache_warmer --chown=${USERNAME}:${USERNAME} /home/${USERNAME}/.cargo /home/${USERNAME}/.cargo
COPY --from=cache_warmer --chown=${USERNAME}:${USERNAME} /home/${USERNAME}/.rustup /home/${USERNAME}/.rustup

# Set up vscode user and environment (ensure this matches base image or is correctly set)
# The base:bookworm-slim should already have vscode user.
# Ensure sudoers setup if not present in base_os layer or inherited correctly.
RUN echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
ENV PATH="/home/${USERNAME}/.nix-profile/bin:/home/${USERNAME}/.cargo/bin:${PATH}"
ENV CARGO_HOME="/home/${USERNAME}/.cargo"
ENV RUSTUP_HOME="/home/${USERNAME}/.rustup"

WORKDIR /workspaces

# Removed static OCI labels; labels will be injected via CI metadata

CMD ["bash"] 