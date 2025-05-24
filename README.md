# 🛠️ YTP Devcontainer · GHCR: `ghcr.io/effortlesssteven/ytp-devcontainer`

[![Open in Dev Container](https://img.shields.io/badge/open%20in-devcontainer-blue?logo=visualstudiocode)](https://github.dev/effortlesssteven/ytp-devcontainer)
[![Platform Support](https://img.shields.io/badge/platform-amd64%20|%20arm64-blue)](https://github.com/EffortlessSteven/ytp-devcontainer)

A prebuilt development container image for building and testing the `ytp` CLI tool.

This image is tuned for fast local iteration, reproducible CI environments, and consistent toolchain behavior **with full platform equivalency** between x86_64 and ARM64.

---

## ✨ Latest (v0.1.6)

**🎯 Platform Equivalency Achieved**: All cargo tools work identically on x86_64 and ARM64  
**🛡️ Robust Error Handling**: Graceful degradation ensures builds always succeed  
**⚡ Performance Optimized**: Pre-compiled binaries with intelligent fallbacks  
**🏷️ Comprehensive Versioning**: Both semantic versioning and automatic date-based tags  

## 🎯 Goals

- ⚡ **Fast dev loop** for `ytp` CLI tool (pre-warmed Cargo caches)
- 📦 **Pinned toolchain** using `rust-toolchain.toml` and Devbox scripts
- 🧪 **CI-ready** container with preinstalled testing and formatting tools
- 🧼 **Isolated from host setup** via Nix + Direnv
- 🔄 **True multi-platform support** with platform equivalency
- 🚫 **Not intended for unrelated Rust projects**, please fork if needed

---

## 🐳 Image Tags

### Recommended for Production
```bash
ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86  # Latest stable with platform equivalency
ghcr.io/effortlesssteven/ytp-devcontainer:0.1-rust1.86    # Major.minor tracking
```

### Development & Testing
```bash
ghcr.io/effortlesssteven/ytp-devcontainer:latest          # Latest features (bleeding edge)
ghcr.io/effortlesssteven/ytp-devcontainer:25.05.24-rust1.86  # Date-based pinned builds
```

Pull the image:

```bash
# Recommended for production
docker pull ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86

# For latest features
docker pull ghcr.io/effortlesssteven/ytp-devcontainer:latest
```

> **Platform Support**: All images provide **identical tooling** on `linux/amd64` and `linux/arm64`  
> **Performance**: x86_64 optimized with pre-compiled binaries, ARM64 with intelligent source compilation  
> **Reliability**: Robust error handling ensures builds succeed even with partial tool failures

---

## 🧰 Included Tooling

### 🔧 Pre-installed (via Dockerfile)

| Tool       | Version Source                     | Platform Support |
| ---------- | ---------------------------------- | ----------------- |
| **Nix**    | Flakes-enabled multi-user          | ✅ amd64 + arm64 |
| **Devbox** | Installed via `nix-env`            | ✅ amd64 + arm64 |
| **Direnv** | Shell automation with `.envrc`     | ✅ amd64 + arm64 |
| **Rustup** | Standard installer via Devbox      | ✅ amd64 + arm64 |
| **Rust**   | `1.86.0` via `rust-toolchain.toml` | ✅ amd64 + arm64 |
| **Cargo**  | Pre-warmed with `cargo fetch`      | ✅ amd64 + arm64 |

### 🛠 Cargo Tools (Platform Equivalent)

**All tools available on both x86_64 and ARM64 with robust error handling:**

| Tool            | Description                      | Installation Method |
| --------------- | -------------------------------- | ------------------- |
| `cargo-nextest` | High-performance test runner     | Pre-compiled (x86_64) / Source (ARM64) |
| `cargo-watch`   | File watcher for auto-rebuilds   | Source compilation (all platforms) |
| `cargo-expand`  | Macro expansion utility          | Source compilation (all platforms) |
| `cargo-clippy`  | Linting (via rustup)             | Rustup component |
| `cargo-fmt`     | Code formatting (via rustup)     | Rustup component |

**🛡️ Reliability Features:**
- **Graceful degradation**: Container builds succeed even if individual tools fail
- **Detailed logging**: Each tool installation reports success/failure with emoji indicators
- **Performance optimization**: Pre-compiled binaries where available, intelligent fallbacks

### 🛠 Runtime via Devbox Scripts

| Script                            | Description                               |
| --------------------------------- | ----------------------------------------- |
| `test`                            | `cargo nextest run --all-targets --all-features` |
| `test-e2e`                        | Integration tests with `--include-ignored` |
| `test-e2e-real`                   | Real E2E tests with `yt-dlp` (requires `real-e2e` feature) |
| `test-release`                    | `cargo nextest run --all-targets --all-features --release` |
| `build`                           | `cargo build --release`                   |
| `build-debug`                     | `cargo build`                            |
| `install`                         | `cargo install --path . --force` (install YTP locally) |
| `config-validate`                 | Run `ytp_config_validate` binary          |
| `schema`                          | Generate JSON schema (with `schema` feature) |
| `clippy`                          | `cargo clippy --all-targets --all-features -- -D warnings` |
| `fmt`                             | `cargo fmt --all`                        |
| `fmt_check`                       | `cargo fmt --all -- --check`              |
| `bench`                           | `cargo bench`                            |
| `doc`                             | `cargo doc --no-deps --open`             |
| `clean`                           | `cargo clean`                            |
| `ytp`                             | `cargo run --` (run YTP from source)     |
| `ytp-dry`                         | `cargo run -- --dry-run` (test YTP commands) |
| `ci`                              | Complete CI pipeline (fmt + clippy + test + build) |
| `perform_initial_project_setup`   | `cargo fetch` to prewarm YTP dependencies |

### 🎨 VS Code Integration

| Category | Extensions |
| -------- | ---------- |
| **Rust Development** | `rust-lang.rust-analyzer`, `tamasfe.even-better-toml`, `serayuzgur.crates` |
| **Debugging** | `vadimcn.vscode-lldb`, `ms-vscode.test-adapter-converter`, `hbenl.vscode-test-explorer` |
| **Code Quality** | `usernamehw.errorlens` |
| **Git & Docker** | `eamodio.gitlens`, `ms-azuretools.vscode-docker` |

**Optimized Settings:**
- Format on save enabled
- Clippy as default check command  
- rust-analyzer with full feature support
- Smart file exclusions for performance

---

## 🚀 Usage

### In VS Code

> Requirements:
>
> * Docker
> * [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

```jsonc
// .devcontainer/devcontainer.json
{
  // Recommended: Use stable versioned releases for production
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86"
  
  // Alternative: Use latest for bleeding-edge features
  // "image": "ghcr.io/effortlesssteven/ytp-devcontainer:latest"
}
```

1. Clone your `ytp` repo
2. Open in VS Code
3. Select **"Reopen in Container"**
4. Devbox + Direnv will activate automatically

---

### In GitHub Actions

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      // Use stable versioned images for CI consistency
      image: ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86
    steps:
      - uses: actions/checkout@v4
      - run: devbox run test
```

---

### (Optional) In Codespaces

```jsonc
{
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86",
  "customizations": {
    "vscode": {
      "extensions": [
        "matklad.rust-analyzer",
        "tamasfe.even-better-toml"
      ]
    }
  }
}
```

---

## 🔄 Upgrading & Versioning

### Version Selection

| Use Case | Recommended Tag | Description |
| -------- | --------------- | ----------- |
| **Production/CI** | `0.1.6-rust1.86` | Latest stable with platform equivalency |
| **Team Development** | `0.1-rust1.86` | Major.minor tracking for consistency |
| **Latest Features** | `latest` | Bleeding-edge features and fixes |
| **Reproducible Builds** | `25.05.24-rust1.86` | Date-based pinned builds |

### Upgrade Process

| Change            | What to do                                      |
| ----------------- | ----------------------------------------------- |
| New Rust version  | Change `rust-toolchain.toml`, rebuild, re-push  |
| Add tools         | Update `devbox.json`, rebuild, re-push          |
| New image version | Use semantic versioning tags (e.g., `0.1.7-rust1.86`) |

---

## 📂 File Reference

| Path                                   | Purpose                               |
| -------------------------------------- | ------------------------------------- |
| `.devcontainer/Dockerfile`             | Multi-stage build with platform optimization |
| `.github/workflows/build-dev-image.yml` | GHCR publish with automatic versioning |
| `devbox.json`                          | Tools and Devbox scripts              |
| `rust-toolchain.toml`                  | Canonical Rust version and components |
| `.envrc`                               | Direnv auto-activation                |
| `.devcontainer/postCreate-prebuilt.sh` | Final adjustments on container attach |

---

## 🔄 Using This for Other Projects?

This image is scoped to the **`ytp` CLI tool**. If you're building a different Rust project:

* Fork this image
* Replace `cargo fetch` and `rust-toolchain.toml`
* Adjust `devbox.json` to match your toolchain needs
* Update the cargo tools installation to match your requirements

This ensures your devcontainer remains purpose-built, reproducible, and optimized for your specific use case.

---

## 📝 License

Dual-licensed under:

* [Apache License 2.0](LICENSE-APACHE)
* [MIT License](LICENSE-MIT)