#!/bin/bash
# .devcontainer/postCreate.sh
# Runs as the 'vscode' user.

set -euxo pipefail

echo "--- [postCreate.sh] start (user: $(id -un), group: $(id -gn), uid: $(id -u), gid: $(id -g), pwd: $PWD) ---"
echo "HOME directory: $HOME"

# Ensure Git uses container tools, not host Windows paths
unset GIT_SSH 2>/dev/null || true
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

#
# STEP 0: Force-fix ownership of essential user-specific directories
# This is crucial because features or volume mounts might have created/altered
# these with root ownership before this script (running as vscode) executes.
# The vscode user uses its passwordless sudo to claim/ensure ownership.
#
echo "[postCreate.sh] Ensuring vscode user owns its critical home subdirectories..."
sudo mkdir -p \
  "$HOME/.config" \
  "$HOME/.cache" \
  "$HOME/.local/share" \
  "$HOME/.cargo" \
  "$HOME/.rustup"

sudo chown -R "$(id -u):$(id -g)" \
  "$HOME/.config" \
  "$HOME/.cache" \
  "$HOME/.local" \
  "$HOME/.cargo" \
  "$HOME/.rustup"

# Explicitly ensure .gitconfig is owned by vscode user if it exists
# This is important if it was created by root earlier or by a different mechanism
if [ -f "$HOME/.gitconfig" ]; then
    echo "[postCreate.sh] Ensuring $HOME/.gitconfig is owned by vscode user..."
    sudo chown "$(id -u):$(id -g)" "$HOME/.gitconfig"
fi

echo "[postCreate.sh] Ensuring specific subdirectories for direnv and devbox..."
sudo mkdir -p "$HOME/.local/share/direnv" "$HOME/.cache/devbox" "$HOME/.local/share/devbox/global"
sudo chown -R "$(id -u):$(id -g)" "$HOME/.local/share/direnv" "$HOME/.cache/devbox" "$HOME/.local/share/devbox"

# The Nix store itself (/nix) should be handled by initializeCommand or the Nix feature
# to be writable by nixbld group or via Nix daemon permissions.

echo "[postCreate.sh] Ownership of user directories fixed/ensured."

#
# STEP 1: Ensure Nix environment is sourced for this script
#
echo "[postCreate.sh] Sourcing Nix profile scripts if available..."
if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then # System-wide Nix
    # shellcheck source=/dev/null
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then # User-specific Nix
    # shellcheck source=/dev/null
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
else
    echo "[Warning][postCreate.sh] Standard Nix profile scripts not found. Nix commands might rely on PATH set by features."
fi
echo "[postCreate.sh] PATH after attempting Nix profile source: $PATH"

#
# STEP 2: Verify essential dev tools are available
#
echo "[postCreate.sh] Verifying Devbox is available (installed at build-time)..."
if ! command -v devbox &> /dev/null; then
    echo "[Error][postCreate.sh] Devbox not found in PATH! Build-time installation failed." >&2
    exit 1
else
    echo "[postCreate.sh] Devbox available: $(command -v devbox)"
fi

echo "[postCreate.sh] Confirming Devbox version..."
devbox version

echo "[postCreate.sh] Verifying direnv is available..."
if ! command -v direnv &> /dev/null; then
    echo "[Error][postCreate.sh] Direnv not found in PATH! Build-time installation failed." >&2
    exit 1
else
    echo "[postCreate.sh] Direnv available: $(command -v direnv)"
fi

#
# STEP 3: Project-specific setup
#
WORKSPACE_FOLDER="${1:-$PWD}" # Passed from devcontainer.json or default to current dir
echo "[postCreate.sh] Changing to workspace: ${WORKSPACE_FOLDER}"
cd "${WORKSPACE_FOLDER}"

echo "[postCreate.sh] Ensuring .envrc exists and contains 'use devbox'..."
if [ ! -f ".envrc" ]; then
  echo "use devbox" > .envrc
  echo "[postCreate.sh] .envrc created."
elif ! grep -q "use devbox" ".envrc"; then
  echo -e "\nuse devbox" >> .envrc
  echo "[postCreate.sh] 'use devbox' added to existing .envrc."
fi

# Idempotency Check for project setup (devbox run perform_initial_project_setup)
STATE_FILE_DIR=".devcontainer"
STATE_FILE="${STATE_FILE_DIR}/.project.bootstrap.hash"
mkdir -p "${STATE_FILE_DIR}" # Ensure .devcontainer dir exists in workspace for the hash file

FILES_TO_HASH="devbox.json Cargo.toml Cargo.lock rust-toolchain.toml" # Added rust-toolchain.toml
CURRENT_HASH=""
EXISTING_FILES_TO_HASH=""
for f in $FILES_TO_HASH; do if [ -f "$f" ]; then EXISTING_FILES_TO_HASH="$EXISTING_FILES_TO_HASH $f"; fi; done

if [ -n "$EXISTING_FILES_TO_HASH" ]; then
    if command -v sha256sum &> /dev/null; then
        CURRENT_HASH=$(cat $EXISTING_FILES_TO_HASH | sha256sum | awk '{print $1}')
    else
        CURRENT_HASH=$(cat $EXISTING_FILES_TO_HASH | md5sum | awk '{print $1}') # Fallback
    fi
fi

if [[ -f "$STATE_FILE" && "$(cat "$STATE_FILE")" == "$CURRENT_HASH" && -n "$CURRENT_HASH" ]]; then
  echo "[postCreate.sh] Project setup (perform_initial_project_setup) appears up-to-date (hash match)."
else
  echo "[postCreate.sh] Running 'direnv allow .' to ensure environment is loaded for devbox run..."
  direnv allow . # Allow direnv to hook and load Devbox env with packages
  echo "[postCreate.sh] Running 'cargo fetch' to fetch YTP dependencies (bypassing devbox due to Nix permissions)..."
  cargo fetch # Run directly since Rust is pre-installed
  if [ -n "$CURRENT_HASH" ]; then
      echo "$CURRENT_HASH" > "$STATE_FILE"
      echo "[postCreate.sh] Project setup complete. Hash updated."
  else
      echo "[postCreate.sh] Project setup complete. No hash updated as key files were missing."
  fi
fi

echo "[postCreate.sh] Final 'direnv allow .' to ensure env is active for VS Code."
direnv allow .

# Git safe.directory configuration moved to postAttach.sh to avoid race conditions with VS Code

echo "--- [postCreate.sh] Finished successfully ---" 