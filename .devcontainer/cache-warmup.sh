#!/bin/bash
# .devcontainer/cache-warmup.sh
# This script is executed inside 'devbox shell -c' during Docker image build.
# It assumes the Devbox environment (including Rustup) is already active.

set -euxo pipefail # Exit on error, print commands, error on unset var, pipefail

echo "[cache-warmup.sh] Devbox init_hook should have run, setting up Rust toolchain."
echo "[cache-warmup.sh] Active Rust version:"
rustc --version
echo "[cache-warmup.sh] Active Cargo version:"
cargo --version

echo "[cache-warmup.sh] Fetching Cargo dependencies for default target (x86_64-unknown-linux-gnu)..."
cargo fetch --target x86_64-unknown-linux-gnu # Be explicit for clarity

echo "[cache-warmup.sh] Adding and fetching for aarch64-unknown-linux-gnu..."
rustup target add aarch64-unknown-linux-gnu || echo "[cache-warmup.sh] aarch64 target already added or add failed (continuing)."
cargo fetch --target aarch64-unknown-linux-gnu || echo "[cache-warmup.sh] cargo fetch for aarch64 failed (continuing)."

echo "[cache-warmup.sh] Cache warming attempts complete."