# YTP Devcontainer

[![Platform Support](https://img.shields.io/badge/platform-amd64%20|%20arm64-blue)](https://github.com/EffortlessSteven/ytp-devcontainer)

Prebuilt development container for the `ytp` CLI tool.

Provides reproducible Rust 1.86.0 environment with pre-configured toolchain, testing framework, and VS Code integration.

---

## Technical Status (v0.1.6)

Platform equivalency: All cargo tools operational on x86_64 and ARM64  
Error handling: Graceful degradation, builds complete regardless of tool failures  
Performance: Pre-compiled binaries with source compilation fallbacks  
Versioning: Semantic + date-based + SHA tagging  

## Architecture

- Fast iteration via pre-warmed Cargo caches
- Pinned toolchain using `rust-toolchain.toml` and Devbox
- CI-ready with preinstalled testing and formatting tools
- Isolated environment via Nix + Direnv
- Multi-platform support with platform equivalency

---

## Image Tags

### Production
```bash
ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86  # Stable release
ghcr.io/effortlesssteven/ytp-devcontainer:0.1-rust1.86    # Major.minor tracking
```

### Development
```bash
ghcr.io/effortlesssteven/ytp-devcontainer:latest          # Current main branch
ghcr.io/effortlesssteven/ytp-devcontainer:25.05.24-rust1.86  # Date-pinned build
```

Platform support: All images provide identical tooling on `linux/amd64` and `linux/arm64`  
Performance: x86_64 optimized with pre-compiled binaries, ARM64 with source compilation  
Reliability: Robust error handling ensures builds succeed with partial tool failures

---

## Tooling

### Core Environment

| Component | Version | Platform Support |
| --------- | ------- | ----------------- |
| Nix | Flakes-enabled | amd64 + arm64 |
| Devbox | Latest | amd64 + arm64 |
| Direnv | Latest | amd64 + arm64 |
| Rust | 1.86.0 | amd64 + arm64 |
| Cargo | Pre-warmed | amd64 + arm64 |

### Cargo Tools

| Tool | Description | Installation |
| ---- | ----------- | ------------ |
| `cargo-nextest` | Test runner | Pre-compiled (x86_64) / Source (ARM64) |
| `cargo-watch` | File watcher | Source compilation |
| `cargo-expand` | Macro expansion | Source compilation |
| `cargo-clippy` | Linting | Rustup component |
| `cargo-fmt` | Code formatting | Rustup component |

Error handling: Container builds succeed even if individual tools fail  
Performance: Pre-compiled binaries where available, intelligent fallbacks

### Devbox Scripts

| Command | Operation |
| ------- | --------- |
| `test` | `cargo nextest run --all-targets --all-features` |
| `test-e2e` | Integration tests with `--include-ignored` |
| `test-release` | Release mode testing |
| `build` | `cargo build --release` |
| `build-debug` | `cargo build` |
| `install` | `cargo install --path . --force` |
| `clippy` | `cargo clippy --all-targets --all-features -- -D warnings` |
| `fmt` | `cargo fmt --all` |
| `fmt_check` | `cargo fmt --all -- --check` |
| `bench` | `cargo bench` |
| `doc` | `cargo doc --no-deps --open` |
| `clean` | `cargo clean` |
| `ci` | Complete validation pipeline |

### VS Code Integration

| Category | Extensions |
| -------- | ---------- |
| Rust | `rust-lang.rust-analyzer`, `tamasfe.even-better-toml`, `serayuzgur.crates` |
| Debug | `vadimcn.vscode-lldb`, `ms-vscode.test-adapter-converter`, `hbenl.vscode-test-explorer` |
| Quality | `usernamehw.errorlens` |
| Git | `eamodio.gitlens`, `ms-azuretools.vscode-docker` |

Configuration: Format on save, Clippy as check command, rust-analyzer optimization, file exclusions

---

## Usage

### VS Code

Requirements: Docker + [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

```jsonc
// .devcontainer/devcontainer.json
{
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86"
}
```

1. Clone repository
2. Open in VS Code
3. Select "Reopen in Container"
4. Devbox + Direnv activate automatically

### GitHub Actions

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86
    steps:
      - uses: actions/checkout@v4
      - run: devbox run test
```

### Codespaces

```jsonc
{
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86",
  "customizations": {
    "vscode": {
      "extensions": [
        "rust-lang.rust-analyzer",
        "tamasfe.even-better-toml"
      ]
    }
  }
}
```

---

## Version Management

### Selection Criteria

| Environment | Tag | Rationale |
| ----------- | --- | --------- |
| Production/CI | `0.1.6-rust1.86` | Stable release with platform equivalency |
| Team development | `0.1-rust1.86` | Major.minor consistency |
| Development | `latest` | Current features |
| Reproducible | `25.05.24-rust1.86` | Date-pinned builds |

### Upgrade Process

| Change | Action |
| ------ | ------ |
| Rust version | Update `rust-toolchain.toml`, rebuild, publish |
| Tool additions | Update `devbox.json`, rebuild, publish |
| Image version | Use semantic versioning tags |

---

## File Structure

| Path | Purpose |
| ---- | ------- |
| `.devcontainer/Dockerfile` | Multi-stage build with platform optimization |
| `.github/workflows/build-dev-image.yml` | GHCR publish with automatic versioning |
| `devbox.json` | Tools and scripts |
| `rust-toolchain.toml` | Rust version specification |
| `.envrc` | Direnv activation |
| `.devcontainer/postCreate-prebuilt.sh` | Container finalization |

---

## Project Scope

This image targets the `ytp` CLI tool specifically. For other Rust projects:

1. Fork this repository
2. Replace `cargo fetch` and `rust-toolchain.toml`
3. Adjust `devbox.json` for your toolchain
4. Update cargo tools installation

This ensures purpose-built, reproducible environments optimized for specific use cases.

---

## License

Dual-licensed: [Apache License 2.0](LICENSE-APACHE) | [MIT License](LICENSE-MIT)