# YTP CLI → ytp-devcontainer Migration Guide

## ✨ Latest Improvements (v0.1.6)

**🎯 Platform Equivalency Achieved**: All cargo tools now work identically on x86_64 and ARM64  
**🛡️ Robust Error Handling**: Graceful degradation ensures builds always succeed  
**⚡ Performance Optimized**: Pre-compiled binaries with intelligent fallbacks  
**🏷️ Comprehensive Versioning**: Both semantic versioning and automatic date-based tags  
**🔄 Multi-Platform Builds**: Consistent experience across all architectures  

---

## 1. Minimal Devcontainer Setup

### `.devcontainer/devcontainer.json` (Complete setup)
```jsonc
{
  "name": "YTP CLI Development",
  // Recommended: Use stable versioned releases for production
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86",
  
  // Alternative: Use latest for bleeding-edge features
  // "image": "ghcr.io/effortlesssteven/ytp-devcontainer:latest",
  
  // Optional: Project-specific environment variables
  "containerEnv": {
    "PROJECT_NAME": "ytp"
  },
  
  // Optional: Project-specific port forwarding
  "forwardPorts": []
}
```

**That's it!** The base image includes:
- ✅ All Rust development VS Code extensions
- ✅ Optimized rust-analyzer settings  
- ✅ Complete Devbox script library
- ✅ Pre-configured Git environment
- ✅ Persistent volume mounts for caches
- ✅ **Full multi-platform support** (x86_64 + ARM64 with complete platform equivalency)
- ✅ **Robust cargo tools** (nextest, watch, expand) with graceful error handling
- ✅ **Performance optimized** with pre-compiled binaries and intelligent fallbacks

## 2. Image Versioning & Selection

### Recommended Tags

| Use Case | Image Tag | Description |
|----------|-----------|-------------|
| **Production/Stable** | `0.1.6-rust1.86` | Latest stable release with full platform equivalency |
| **Team Development** | `0.1-rust1.86` | Major.minor version for consistent team environments |
| **Bleeding Edge** | `latest` | Latest features and fixes (may include experimental changes) |
| **Date-based** | `25.05.24-rust1.86` | Specific daily builds for reproducible environments |

### Version Selection Guidelines

```jsonc
// Production/CI environments (recommended)
"image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86"

// Team consistency (major.minor tracking)
"image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1-rust1.86"

// Latest features (development)
"image": "ghcr.io/effortlesssteven/ytp-devcontainer:latest"

// Pinned daily build (maximum reproducibility)
"image": "ghcr.io/effortlesssteven/ytp-devcontainer:25.05.24-rust1.86"
```

### Platform Equivalency

All image versions provide **identical tooling** across architectures:

| Architecture | Tools Available | Performance |
|-------------|----------------|-------------|
| **x86_64** | All 6 tools ✅ | Optimized with pre-compiled binaries |
| **ARM64** | All 6 tools ✅ | Source compilation with build caching |

### Optional: Project-specific scripts

Only create `devbox.json` if you need **additional** scripts beyond the base set:

```json
{
  "include": ["devbox.json"],
  "shell": {
    "scripts": {
      "install": "cargo install --path .",
      "integration-test": "cargo test --test integration",
      "custom-command": "echo 'Project-specific command'"
    }
  }
}
```

## 3. Available Commands (Pre-configured)

All of these work immediately:

```bash
# Development
devbox run build          # Release build
devbox run build-debug    # Debug build  
devbox run test           # All tests
devbox run test-release   # Tests in release mode

# Code Quality  
devbox run clippy         # Linting
devbox run fmt            # Format code
devbox run fmt_check      # Check formatting

# Documentation & Utilities
devbox run doc            # Generate and open docs
devbox run bench          # Run benchmarks
devbox run clean          # Clean build artifacts

# CI Pipeline
devbox run ci             # Complete CI check (fmt + clippy + test + build)
```

## 4. Project Files Required

### `rust-toolchain.toml` (Must match base image)
```toml
[toolchain]
channel = "1.86.0"
components = ["rustfmt", "clippy", "rust-analyzer"]
targets = ["x86_64-unknown-linux-gnu"]
```

### `.envrc` (Direnv integration)
```bash
use devbox
```

## 5. CI/CD Configuration

### `.github/workflows/ci.yml` (Minimal)
```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      # Use stable versioned images for CI consistency
      image: ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86
    steps:
      - uses: actions/checkout@v4
      - name: Run CI pipeline
        run: devbox run ci
```

### Advanced CI Configuration

For maximum reliability, pin to specific versions:

```yaml
jobs:
  test:
    strategy:
      matrix:
        image-tag:
          - "0.1.6-rust1.86"  # Current stable
          # - "latest"        # Uncomment for bleeding-edge testing
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/effortlesssteven/ytp-devcontainer:${{ matrix.image-tag }}
    steps:
      - uses: actions/checkout@v4
      - name: Run CI pipeline
        run: devbox run ci
```

## 6. Migration Checklist

### Required Steps
- [ ] Create `.devcontainer/devcontainer.json` with minimal config above
- [ ] Ensure `rust-toolchain.toml` specifies `channel = "1.86.0"`
- [ ] Add `.envrc` with `use devbox`
- [ ] Update CI workflows to use the container image
- [ ] Test: Open in VS Code devcontainer

### Optional Enhancements
- [ ] Add project-specific environment variables to `containerEnv`
- [ ] Create additional devbox scripts for project-specific commands
- [ ] Configure port forwarding if needed
- [ ] Add project-specific VS Code workspace settings

## 7. Development Workflow

### Getting Started
1. Clone YTP repository
2. Open in VS Code  
3. Click "Reopen in Container"
4. Start coding - everything is pre-configured!

### Daily Development
```bash
# Run tests during development
devbox run test

# Check code quality before commit
devbox run ci

# Build release version
devbox run build
```

### Debugging
- **Breakpoints**: Work automatically with `vadimcn.vscode-lldb`
- **Test explorer**: Integrated via pre-installed extensions
- **Error highlighting**: Real-time via `errorlens` extension

## 8. Troubleshooting

### Common Issues

**"devbox not found":**
- The base image includes devbox - restart the container

**"Extensions not loading":**
- Extensions are pre-configured in base image - check VS Code logs

**"Rust analyzer not working":**
- Settings are optimized in base image - ensure `rust-toolchain.toml` matches

### Performance Notes
- **First startup**: ~30 seconds (one-time dependency fetch)
- **Subsequent startups**: <10 seconds (cached)
- **Hot reload**: Immediate (rust-analyzer pre-configured)

## 9. Base Image Contents

For reference, the base image (e.g., `ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86`) includes:

**Pre-installed Tools:**
- Rust 1.86.0 toolchain with clippy, rustfmt, rust-analyzer
- Nix package manager with Devbox
- Git with container-optimized configuration
- **Multi-platform cargo tools** with robust error handling and graceful degradation

**Cargo Tools (Platform Equivalent):**
- `cargo-nextest` - High-performance test runner
- `cargo-watch` - File watcher for automatic rebuilds
- `cargo-expand` - Macro expansion utility
- `cargo-clippy` - Linting (via rustup)
- `cargo-fmt` - Code formatting (via rustup)

**VS Code Extensions:**
- `rust-lang.rust-analyzer` (Rust language support)
- `tamasfe.even-better-toml` (TOML editing)
- `serayuzgur.crates` (Cargo.toml assistance)
- `vadimcn.vscode-lldb` (Debugging)
- `usernamehw.errorlens` (Inline error display)
- `eamodio.gitlens` (Git integration)
- Testing and Docker extensions

**Optimized Settings:**
- Format on save enabled
- Clippy as default check command
- Optimized rust-analyzer configuration
- Git autofetch and proper exclusions

**Platform Support & Performance:**
- **x86_64**: Optimized with pre-compiled binaries where available
- **ARM64**: Full platform equivalency with intelligent source compilation
- **Consistent tooling** across all architectures with graceful fallbacks
- **Robust error handling** ensures builds complete even if individual tools fail

**Build Features:**
- **Multi-stage builds** for optimal image size and caching
- **Graceful degradation** - container builds succeed even with partial tool failures
- **Performance optimization** - pre-compiled binaries with source compilation fallbacks
- **Comprehensive caching** - warm Cargo caches and pre-configured environments

This provides a complete, batteries-included Rust development environment with guaranteed platform equivalency and maximum reliability.

### Getting Help
1. Check container logs: `docker logs <container-id>`
2. Verify devcontainer configuration syntax
3. Use stable versioned images for production: `0.1.6-rust1.86`
4. Check GitHub Actions logs for CI issues
5. Review platform-specific tool installation logs in container build output