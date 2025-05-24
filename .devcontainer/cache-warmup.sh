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
cargo fetch

echo "[cache-warmup.sh] Adding cross-compilation targets..."
rustup target add x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu || echo "[cache-warmup.sh] targets already added or add failed (continuing)."

echo "[cache-warmup.sh] Pre-compiling dependency caches..."
cargo check --all-targets --all-features || echo "[cache-warmup.sh] check failed, continuing..."

echo "[cache-warmup.sh] Pre-building dev dependencies for test performance..."
cargo check --tests --all-features || echo "[cache-warmup.sh] test check failed, continuing..."

echo "[cache-warmup.sh] Pre-warming rust-analyzer with YTP-specific caches..."
timeout 45s cargo check --message-format=json --all-features > /dev/null 2>&1 || echo "[cache-warmup.sh] rust-analyzer cache warm timeout (expected)"

echo "[cache-warmup.sh] Testing YTP binary compilation for sccache warming..."
timeout 60s cargo build --bin ytp-devcontainer || echo "[cache-warmup.sh] binary build timeout (expected, cache warmed)"

echo "[cache-warmup.sh] YTP-specific cache warming complete."