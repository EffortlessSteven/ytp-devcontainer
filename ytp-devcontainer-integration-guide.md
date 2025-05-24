# YTP CLI → ytp-devcontainer Migration Guide

## 1. Minimal Devcontainer Setup

### `.devcontainer/devcontainer.json` (Complete setup)
```jsonc
{
  "name": "YTP CLI Development",
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.5",
  
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

## 2. Available Commands (Pre-configured)

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

## 3. Project Files Required

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

## 4. CI/CD Configuration

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
      image: ghcr.io/effortlesssteven/ytp-devcontainer:0.1.5
    steps:
      - uses: actions/checkout@v4
      - name: Run CI pipeline
        run: devbox run ci
```

## 5. Migration Checklist

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

## 6. Development Workflow

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

## 7. Troubleshooting

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

## 8. Base Image Contents

For reference, the base image (`ghcr.io/effortlesssteven/ytp-devcontainer:0.1.5`) includes:

**Pre-installed Tools:**
- Rust 1.86.0 toolchain with clippy, rustfmt, rust-analyzer
- Nix package manager with Devbox
- Git with container-optimized configuration

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

This provides a complete, batteries-included Rust development environment with minimal consumer-side configuration required.

### Getting Help
1. Check container logs: `docker logs <container-id>`
2. Verify devcontainer configuration syntax
3. Ensure you're using the latest stable image: `0.1.3`
4. Check GitHub Actions logs for CI issues
