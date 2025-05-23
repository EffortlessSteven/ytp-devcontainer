#!/bin/bash
# .devcontainer/postAttach.sh
# Runs every time VS Code attaches to the container, after postCreateCommand
# This ensures Git safe.directory is configured after VS Code initialization is complete

set -euo pipefail

echo "--- [postAttach.sh] start ---"
WORKSPACE_DIR="${containerWorkspaceFolder:-${1:-$PWD}}" # Use env var or arg or PWD

if [ -z "$WORKSPACE_DIR" ]; then
    echo "[postAttach.sh] WORKSPACE_DIR is not set. Exiting."
    exit 1
fi

echo "[postAttach.sh] Ensuring Git safe.directory for workspace: $WORKSPACE_DIR"

# Check if already configured to avoid duplicates
if git config --global --get-all safe.directory 2>/dev/null | grep -q -F -x "$WORKSPACE_DIR"; then
    echo "[postAttach.sh] Workspace '$WORKSPACE_DIR' is already in Git's safe.directory list."
else
    echo "[postAttach.sh] Adding workspace '$WORKSPACE_DIR' to Git's safe.directory list."
    
    # Attempt to add with retry logic for race conditions
    if git config --global --add safe.directory "$WORKSPACE_DIR" 2>/dev/null; then
        echo "[postAttach.sh] Successfully added '$WORKSPACE_DIR' to safe.directory."
    else
        echo "[postAttach.sh] First attempt failed. Waiting and retrying..."
        sleep 2
        if git config --global --add safe.directory "$WORKSPACE_DIR" 2>/dev/null; then
            echo "[postAttach.sh] Successfully added '$WORKSPACE_DIR' to safe.directory on retry."
        else
            echo "[postAttach.sh] ERROR: Failed to add '$WORKSPACE_DIR' to safe.directory after retry."
            echo "[postAttach.sh] Checking file status:"
            ls -la ~/.gitconfig 2>/dev/null || echo "[postAttach.sh] ~/.gitconfig does not exist."
            
            # Check for processes holding the file
            echo "[postAttach.sh] Checking for processes using ~/.gitconfig:"
            lsof ~/.gitconfig 2>/dev/null || echo "[postAttach.sh] No processes found using ~/.gitconfig"
        fi
    fi
fi

echo "--- [postAttach.sh] end ---" 