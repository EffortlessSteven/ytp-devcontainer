# YTP CLI → ytp-devcontainer Migration Guide

## Technical Status (v0.1.6)

Platform equivalency: All cargo tools operational on x86_64 and ARM64  
Error handling: Graceful degradation, builds complete regardless of tool failures  
Performance: Pre-compiled binaries with source compilation fallbacks  
Versioning: Semantic + date-based + SHA tagging  
Architecture support: Multi-platform builds with consistent tooling  

---

## 1. Minimal Configuration

### `.devcontainer/devcontainer.json`
```jsonc
{
  "name": "YTP CLI Development",
  "image": "ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86",
  "containerEnv": {
    "PROJECT_NAME": "ytp"
  },
  "forwardPorts": []
}
```

Base image provides:
- Rust development VS Code extensions
- rust-analyzer configuration  
- Devbox script library
- Git environment
- Persistent volume mounts
- Multi-platform cargo tools (nextest, watch, expand, clippy, fmt, miri)

## 2. Image Selection

### Production Tags

| Environment | Tag | Stability |
|-------------|-----|-----------|
| Production/CI | `0.1.6-rust1.86` | Stable release |
| Team consistency | `0.1-rust1.86` | Major.minor tracking |
| Development | `latest` | Current main branch |
| Reproducible | `25.05.24-rust1.86` | Date-pinned build |

### Platform Support

| Architecture | Tooling | Implementation |
|-------------|---------|----------------|
| x86_64 | All 6 tools | Pre-compiled binaries + fallbacks |
| ARM64 | All 6 tools | Source compilation + caching |

## 3. Pre-configured Commands

```bash
# Build operations
devbox run build          # Release build
devbox run build-debug    # Debug build  
devbox run test           # Test execution
devbox run test-release   # Release mode tests

# Code quality
devbox run clippy         # Linting
devbox run fmt            # Format code
devbox run fmt_check      # Format validation

# Utilities
devbox run doc            # Documentation generation
devbox run bench          # Benchmark execution
devbox run clean          # Artifact cleanup
devbox run ci             # Complete validation pipeline
```

## 4. Required Project Files

### `rust-toolchain.toml`
```toml
[toolchain]
channel = "1.86.0"
components = ["rustfmt", "clippy", "rust-analyzer"]
targets = ["x86_64-unknown-linux-gnu"]
```

### `.envrc`
```bash
use devbox
```

## 5. CI Integration

### Basic Configuration
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
      image: ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86
    steps:
      - uses: actions/checkout@v4
      - run: devbox run ci
```

### Matrix Testing
```yaml
jobs:
  test:
    strategy:
      matrix:
        image-tag: ["0.1.6-rust1.86"]
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/effortlesssteven/ytp-devcontainer:${{ matrix.image-tag }}
    steps:
      - uses: actions/checkout@v4
      - run: devbox run ci
```

## 6. Migration Steps

### Required
- [ ] Create `.devcontainer/devcontainer.json` 
- [ ] Set `rust-toolchain.toml` to `channel = "1.86.0"`
- [ ] Add `.envrc` with `use devbox`
- [ ] Update CI to use container image
- [ ] Verify: Open in VS Code devcontainer

### Optional Extensions
- [ ] Project-specific environment variables in `containerEnv`
- [ ] Additional devbox scripts for project commands
- [ ] Port forwarding configuration
- [ ] VS Code workspace settings

## 7. Development Process

### Initial Setup
1. Clone repository
2. Open in VS Code  
3. Select "Reopen in Container"
4. Begin development

### Daily Operations
```bash
devbox run test     # Development testing
devbox run ci       # Pre-commit validation
devbox run build    # Release compilation
```

### Debugging
- Breakpoints: `vadimcn.vscode-lldb` integration
- Test explorer: Pre-configured extensions
- Error highlighting: `errorlens` extension

## 8. Issue Resolution

### Command Not Found
- `devbox not found`: Container restart required
- Extensions not loading: Check VS Code logs
- rust-analyzer failure: Verify `rust-toolchain.toml` version match

### Performance Characteristics
- Initial startup: ~30 seconds (dependency fetch)
- Subsequent startups: <10 seconds (cached)
- Hot reload: Immediate (pre-configured rust-analyzer)

## 9. Base Image Specification

Image `ghcr.io/effortlesssteven/ytp-devcontainer:0.1.6-rust1.86` contains:

**Core Tools:**
- Rust 1.86.0 + clippy + rustfmt + rust-analyzer
- Nix package manager + Devbox
- Git with container configuration

**Cargo Tools:**
- `cargo-nextest` - Test runner
- `cargo-watch` - File watcher
- `cargo-expand` - Macro expansion
- `cargo-clippy` - Linting
- `cargo-fmt` - Code formatting

**VS Code Extensions:**
- `rust-lang.rust-analyzer` - Language support
- `tamasfe.even-better-toml` - TOML editing
- `serayuzgur.crates` - Cargo assistance
- `vadimcn.vscode-lldb` - Debugging
- `usernamehw.errorlens` - Error display
- `eamodio.gitlens` - Git integration

**Configuration:**
- Format on save enabled
- Clippy as check command
- rust-analyzer optimization
- Git autofetch and exclusions

**Build Architecture:**
- Multi-stage builds for size optimization
- Graceful tool installation with error handling
- Performance optimization: pre-compiled binaries + source fallbacks
- Cargo cache warming

## 10. Error Diagnostics

1. Container logs: `docker logs <container-id>`
2. Devcontainer configuration validation
3. Stable versioned images for production environments
4. GitHub Actions logs for CI troubleshooting
5. Container build logs for tool installation status

This provides complete Rust development infrastructure with platform equivalency and maximum reliability.