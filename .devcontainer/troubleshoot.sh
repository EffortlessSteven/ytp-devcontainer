#!/bin/bash
# Troubleshooting script to diagnose common Dev Container issues
# Run this script inside the container if you're having problems

set -e

echo "=== YTP Dev Container Troubleshooting ==="
echo "Running as: $(id -un):$(id -gn) ($(id -u):$(id -g))"
echo "Current directory: $(pwd)"
echo "Current date: $(date)"
echo

echo "=== System Information ==="
uname -a
echo

echo "=== Environment Variables ==="
echo "HOME: $HOME"
echo "PATH: $PATH"
echo "SHELL: $SHELL"
echo

echo "=== Directory Permissions ==="
echo "/nix directory:"
ls -ld /nix 2>/dev/null || echo "/nix does not exist"
echo

echo "Home directory structure:"
ls -la $HOME
echo

echo "=== Tool Availability ==="
echo "bash: $(which bash 2>/dev/null || echo 'Not found')"
echo "sudo: $(which sudo 2>/dev/null || echo 'Not found')"
echo "nix: $(which nix 2>/dev/null || echo 'Not found')"
echo "nix-env: $(which nix-env 2>/dev/null || echo 'Not found')"
echo "nix-channel: $(which nix-channel 2>/dev/null || echo 'Not found')"
echo "direnv: $(which direnv 2>/dev/null || echo 'Not found')"
echo "devbox: $(which devbox 2>/dev/null || echo 'Not found')"
echo "rustc: $(which rustc 2>/dev/null || echo 'Not found')"
echo "cargo: $(which cargo 2>/dev/null || echo 'Not found')"
echo

if command -v nix-env &>/dev/null; then
  echo "=== Nix Packages ==="
  nix-env -q
  echo
fi

if command -v nix-channel &>/dev/null; then
  echo "=== Nix Channels ==="
  nix-channel --list
  echo
fi

if command -v devbox &>/dev/null; then
  echo "=== Devbox Information ==="
  devbox version
  echo

  if [ -f "./devbox.json" ]; then
    echo "Found devbox.json in current directory:"
    cat ./devbox.json
    echo
  else
    echo "No devbox.json found in current directory."
    echo
  fi
fi

if [ -f "./.envrc" ]; then
  echo "=== .envrc Content ==="
  cat ./.envrc
  echo
else
  echo "No .envrc found in current directory."
  echo
fi

echo "=== Container Filesystem Usage ==="
df -h
echo

echo "=== Container Process List ==="
ps aux
echo

echo "=== Container Memory Usage ==="
free -h
echo

echo "=== Troubleshooting complete ==="
echo "To further diagnose issues, check the logs in .devcontainer/logs/ if they exist"
echo "You can also try running 'bash .devcontainer/setup-nix.sh' to fix Nix-related issues" 