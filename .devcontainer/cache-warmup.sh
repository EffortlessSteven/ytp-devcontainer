#!/bin/bash
# .devcontainer/cache-warmup.sh
# YTP-specific cache warming for optimal runtime performance

set -euxo pipefail

echo "[cache-warmup.sh] YTP devcontainer cache warming starting..."
echo "[cache-warmup.sh] Active Rust version:"
rustc --version
echo "[cache-warmup.sh] Active Cargo version:"
cargo --version

echo "[cache-warmup.sh] Fetching YTP dependencies for default target..."
cargo fetch --target x86_64-unknown-linux-gnu

echo "[cache-warmup.sh] Adding ARM64 target for cross-compilation..."
rustup target add aarch64-unknown-linux-gnu || echo "[cache-warmup.sh] aarch64 target already added or add failed (continuing)."
cargo fetch --target aarch64-unknown-linux-gnu || echo "[cache-warmup.sh] cargo fetch for aarch64 failed (continuing)."

echo "[cache-warmup.sh] Pre-compiling YTP's specific dependencies for fastest runtime builds..."
# Build dependencies only (not the main binary) to warm caches
cargo build --release --dependencies-only || echo "[cache-warmup.sh] dependencies-only not supported, using alternative..."

# Alternative: check all targets to warm dependency caches
cargo check --all-targets --all-features || echo "[cache-warmup.sh] check failed, continuing..."

echo "[cache-warmup.sh] Pre-building dev dependencies for test performance..."
cargo check --tests --all-features || echo "[cache-warmup.sh] test check failed, continuing..."

echo "[cache-warmup.sh] Installing yt-dlp for YTP integration tests..."
# Install yt-dlp which ytp depends on for real functionality
if ! command -v yt-dlp &> /dev/null; then
    echo "[cache-warmup.sh] yt-dlp not found, installing..."
    # Try pip install first, fallback to system package manager
    if command -v pip3 &> /dev/null; then
        pip3 install --user yt-dlp || echo "[cache-warmup.sh] pip install failed, trying apt..."
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y yt-dlp || echo "[cache-warmup.sh] apt install failed, continuing..."
        fi
    fi
else
    echo "[cache-warmup.sh] yt-dlp already available: $(which yt-dlp)"
fi

echo "[cache-warmup.sh] Pre-warming rust-analyzer with YTP-specific caches..."
timeout 45s cargo check --message-format=json --all-features > /dev/null 2>&1 || echo "[cache-warmup.sh] rust-analyzer cache warm timeout (expected)"

echo "[cache-warmup.sh] Testing YTP binary compilation for sccache warming..."
timeout 60s cargo build --bin ytp || echo "[cache-warmup.sh] binary build timeout (expected, cache warmed)"

echo "[cache-warmup.sh] YTP-specific cache warming complete."