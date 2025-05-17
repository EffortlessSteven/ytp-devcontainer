#!/bin/bash
# This script handles Nix-specific setup after the container is created
# Runs as part of postStartCommand, after container creation but before postCreate.sh

set -eo pipefail # Exit on error, pipefail

WORKSPACE_FOLDER="${1:-$PWD}"
echo "--- [setup-nix.sh] Starting Nix setup (running as: $(id -un), uid: $(id -u), gid: $(id -g)) ---"
echo "Workspace folder: ${WORKSPACE_FOLDER}"

# Check if we have sudo access (we should as vscode user)
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  echo "[setup-nix.sh] We have passwordless sudo access, can properly setup /nix"
  
  # Create /nix directory with correct permissions if it doesn't exist properly
  if [ ! -d "/nix" ]; then
    sudo mkdir -p /nix
  fi
  
  # Ensure the nixbld group exists
  if ! getent group nixbld >/dev/null; then
    echo "[setup-nix.sh] Creating nixbld group"
    sudo groupadd -r nixbld || true
  fi
  
  # Ensure vscode user is in nixbld group for Nix multi-user installations
  if ! id -nG | grep -qw nixbld; then
    echo "[setup-nix.sh] Adding vscode user to nixbld group"
    sudo usermod -aG nixbld "$(id -un)" || true
  fi
  
  # Ensure /nix has correct permissions
  echo "[setup-nix.sh] Setting up /nix permissions"
  sudo chown "$(id -un):$(id -gn)" /nix
  sudo chmod 775 /nix
else
  echo "[setup-nix.sh] Warning: passwordless sudo not available, limited setup possible"
  # Check if /nix exists and is writable
  if [ ! -d "/nix" ]; then
    echo "[setup-nix.sh] Warning: /nix directory doesn't exist and can't create it without sudo"
    mkdir -p /nix 2>/dev/null || echo "[setup-nix.sh] Failed to create /nix, hoping it's handled elsewhere"
  elif [ ! -w "/nix" ]; then
    echo "[setup-nix.sh] Warning: /nix directory exists but is not writable. Will attempt to continue."
  else
    echo "[setup-nix.sh] /nix exists and appears writable by current user"
  fi
fi

# We'll let postCreate.sh handle the rest of the setup with proper permissions
echo "--- [setup-nix.sh] Basic Nix filesystem setup completed, postCreate.sh will handle the rest ---" 