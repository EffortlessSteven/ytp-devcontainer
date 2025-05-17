# Dev Container Setup for YTP Project

This directory contains the configuration for the VS Code Dev Container used for YTP development. The container provides a consistent development environment with Rust, Nix, and Devbox pre-configured.

## Container Lifecycle Overview

Understanding the execution order helps troubleshoot issues:

1. **initializeCommand** (.devcontainer/initialize.sh)
   - Runs on host before container creation
   - Creates minimal /nix directory structure

2. **Features Installation**
   - Installs Nix and direnv via the Dev Container features system

3. **onCreateCommand**
   - Initial setup after container creation

4. **postStartCommand** (.devcontainer/setup-nix.sh)
   - Sets up basic /nix permissions
   - Ensures nixbld group exists and vscode user is a member

5. **postCreateCommand** (.devcontainer/postCreate.sh)
   - Critical ownership fixes for user directories
   - Sources Nix environment
   - Sets up user-specific Nix channels
   - Installs devbox if needed
   - Runs project-specific setup via `devbox run perform_initial_project_setup`

6. **postAttachCommand**
   - Ensures direnv is allowed and activated for the current workspace

## Permission Strategy

The core challenge in this dev container is managing permissions correctly across different execution contexts:

1. **Early Root Context**: Certain directories (like /nix) initially created by root
2. **User Context**: Most development tools run as the vscode user
3. **Volume Mounts**: Docker volumes can have specific ownership issues

Our solution uses two key approaches:
- **Early in postCreate.sh**: The vscode user leverages passwordless sudo to claim ownership of its home directories
- **Explicit Chown**: Critical directories under $HOME are explicitly owned by the vscode user

### Handling direnv Permissions

The direnv permission strategy employs multiple safeguards:

1. **Dockerfile stage**: Creates `/home/vscode/.local/share/direnv` with proper ownership as root
2. **postCreate-prebuilt.sh**: Performs additional permission fixes after container initialization 
3. **Fallback mechanisms**: Uses conditional sudo to ensure directory creation works even without elevated permissions
4. **Lifecycle-aware commands**: updateContentCommand is simplified to only perform direnv allow after directories are created

This multi-layered approach ensures that volume mounts or feature installations don't interfere with direnv's ability to create and manage its allow directory.

## Troubleshooting

Common issues and solutions:

### Permission Errors

If you see permission errors like:
```
direnv: error ~/.local/share/direnv/allow/... permission denied
```

Run the troubleshooting script to diagnose:
```bash
bash .devcontainer/troubleshoot.sh
```

Verify the vscode user has sudo access:
```bash
sudo -n true && echo "Passwordless sudo works" || echo "No passwordless sudo"
```

### Missing Tools or Commands

If nix, direnv or devbox commands are not found:
1. Check that Nix is properly sourced:
   ```bash
   . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
   ```
2. Verify user's Nix profile:
   ```bash
   ls -la ~/.nix-profile/bin/
   ```

### Rust/Cargo Issues

1. Check Rust installation:
   ```bash
   devbox list
   rustc --version
   cargo --version
   ```

2. Verify cargo cache is properly mounted:
   ```bash
   ls -la ~/.cargo
   ```

## Container Rebuild

If you need to completely rebuild the container:

1. VS Code Command Palette: "Dev Containers: Rebuild Container"
2. If issues persist, try a full rebuild without cache:
   - VS Code Command Palette: "Dev Containers: Rebuild Container Without Cache"

## Volume Management

This container uses several Docker volumes to persist data:
- ytp-devbox-global-cache: For devbox global packages
- ytp-cargo-home-cache: For cargo registry and dependencies
- ytp-rustup-home-cache: For Rust toolchains

To reset these volumes if they become corrupted:
```bash
docker volume rm ytp-devbox-global-cache ytp-cargo-home-cache ytp-rustup-home-cache
``` 