# 🛠️ YTP Devcontainer · GHCR: `ghcr.io/effortlesssteven/ytp-devcontainer`

[![Open in Dev Container](https://img.shields.io/badge/open%20in-devcontainer-blue?logo=visualstudiocode)](https://github.dev/effortlesssteven/ytp-devcontainer)

A prebuilt development container image for building and testing the `ytp` CLI tool.

This image is tuned for fast local iteration, reproducible CI environments, and consistent toolchain behavior.

---

## 🎯 Goals

- ⚡ **Fast dev loop** for `ytp` CLI tool (pre-warmed Cargo caches)
- 📦 **Pinned toolchain** using `rust-toolchain.toml` and Devbox scripts
- 🧪 **CI-ready** container with preinstalled testing and formatting tools
- 🧼 **Isolated from host setup** via Nix + Direnv
- 🚫 **Not intended for unrelated Rust projects**, please fork if needed

---

## 🐳 Image Tags

```bash
ghcr.io/effortlesssteven/ytp-devcontainer:0.1.3   # Stable (Rust 1.86, batteries-included)
ghcr.io/effortlesssteven/ytp-devcontainer:latest  # Mutable dev
```

Pull the image:

```bash
docker pull ghcr.io/effortlesssteven/ytp-devcontainer:0.1.3
```

> All images run as non-root (`vscode` user) and are built for Dev Containers and CI.
> Compatible with both `linux/amd64` and `linux/arm64` platforms.

---

## 🧰 Included Tooling

### 🔧 Pre-installed (via Dockerfile)

| Tool       | Version Source                     |
| ---------- | ---------------------------------- |
| **Nix**    | Flakes-enabled multi-user          |
| **Devbox** | Installed via `nix-env`            |
| **Direnv** | Shell automation with `.envrc`     |
| **Rustup** | Standard installer via Devbox      |
| **Rust**   | `1.86.0` via `rust-toolchain.toml` |
| **Cargo**  | Pre-warmed with `cargo fetch`      |

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
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.3"
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
      image: ghcr.io/effortlesssteven/ytp-devcontainer:0.1.3
    steps:
      - uses: actions/checkout@v4
      - run: devbox run test
```

---

### (Optional) In Codespaces

```jsonc
{
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.3",
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

## 🔄 Upgrading

| Change            | What to do                                      |
| ----------------- | ----------------------------------------------- |
| New Rust version  | Change `rust-toolchain.toml`, rebuild, re-push  |
| Add tools         | Update `devbox.json`, rebuild, re-push          |
| New image version | Push `:0.1.1`, update consumers to use that tag |

---

## 📂 File Reference

| Path                                   | Purpose                               |
| -------------------------------------- | ------------------------------------- |
| `.devcontainer/Dockerfile`             | Prebuilds full environment with cache |
| `.github/workflows/build-dev-image.yml` | GHCR publish via GitHub Actions       |
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

This ensures your devcontainer remains purpose-built and reproducible.

---

## 📝 License

Dual-licensed under:

* [Apache License 2.0](LICENSE-APACHE)
* [MIT License](LICENSE-MIT)