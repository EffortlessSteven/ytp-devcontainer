#!/bin/bash
# .devcontainer/postCreate-prebuilt.sh
# Simplified version for pre-built images where Nix, Devbox and Rust are already installed

set -euo pipefail

echo "--- [postCreate-prebuilt.sh] start (user: $(id -un), pwd: $PWD) ---"

# Essential safety check for permissions on mounted volumes and home directories
echo "[postCreate-prebuilt.sh] Ensuring vscode user owns critical directories..."
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  # Use sudo to forcefully fix permissions if available
  sudo mkdir -p \
    "$HOME/.config" \
    "$HOME/.cache" \
    "$HOME/.local/share" \
    "$HOME/.local/share/direnv" \
    "$HOME/.cargo" \
    "$HOME/.rustup"
  
  sudo chown -R "$(id -u):$(id -g)" \
    "$HOME/.config" \
    "$HOME/.cache" \
    "$HOME/.local" \
    "$HOME/.cargo" \
    "$HOME/.rustup"
  
  echo "[postCreate-prebuilt.sh] Fixed permissions with sudo."
else
  # Try to fix permissions without sudo as a fallback
  mkdir -p \
    "$HOME/.config" \
    "$HOME/.cache" \
    "$HOME/.local/share" \
    "$HOME/.local/share/direnv" \
    "$HOME/.cargo" \
    "$HOME/.rustup" 2>/dev/null || true
  
  echo "[postCreate-prebuilt.sh] Attempted to fix permissions without sudo."
fi

# Setup workspace
WORKSPACE_FOLDER="${1:-$PWD}"
cd "${WORKSPACE_FOLDER}"

echo "[postCreate-prebuilt.sh] Ensuring .envrc exists with 'use devbox'..."
if [ ! -f ".envrc" ]; then
  echo "use devbox" > .envrc
  echo "[postCreate-prebuilt.sh] .envrc created."
elif ! grep -q "use devbox" ".envrc"; then
  echo -e "\nuse devbox" >> .envrc
  echo "[postCreate-prebuilt.sh] 'use devbox' added to existing .envrc."
fi

# Idempotency check for project setup
STATE_FILE_DIR=".devcontainer"
STATE_FILE="${STATE_FILE_DIR}/.project.bootstrap.hash"
mkdir -p "${STATE_FILE_DIR}"

FILES_TO_HASH="devbox.json Cargo.toml Cargo.lock rust-toolchain.toml"
CURRENT_HASH=""
EXISTING_FILES_TO_HASH=""
for f in $FILES_TO_HASH; do if [ -f "$f" ]; then EXISTING_FILES_TO_HASH="$EXISTING_FILES_TO_HASH $f"; fi; done

if [ -n "$EXISTING_FILES_TO_HASH" ]; then
    if command -v sha256sum &> /dev/null; then
        CURRENT_HASH=$(cat $EXISTING_FILES_TO_HASH | sha256sum | awk '{print $1}')
    else
        CURRENT_HASH=$(cat $EXISTING_FILES_TO_HASH | md5sum | awk '{print $1}')
    fi
fi

if [[ -f "$STATE_FILE" && "$(cat "$STATE_FILE")" == "$CURRENT_HASH" && -n "$CURRENT_HASH" ]]; then
  echo "[postCreate-prebuilt.sh] Project setup appears up-to-date (hash match)."
else
  echo "[postCreate-prebuilt.sh] Activating direnv and running project setup..."
  direnv allow .
  echo "[postCreate-prebuilt.sh] Running 'devbox run perform_initial_project_setup'..."
  devbox run perform_initial_project_setup
  if [ -n "$CURRENT_HASH" ]; then
      echo "$CURRENT_HASH" > "$STATE_FILE"
      echo "[postCreate-prebuilt.sh] Project setup complete. Hash updated."
  fi
fi

echo "[postCreate-prebuilt.sh] Final direnv allow to ensure environment is active."
direnv allow .

# Report versions
rustc --version
cargo --version
devbox version

echo "--- [postCreate-prebuilt.sh] Finished successfully ---" 