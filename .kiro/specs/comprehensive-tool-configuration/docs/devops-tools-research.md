# Container and DevOps Tools Configuration Research

## Research Overview

This document provides comprehensive research on container and DevOps tools configuration capabilities, environment variables, XDG Base Directory support, and file management requirements. All information has been validated against current tool versions and official documentation.

## Docker Ecosystem

### docker-client (Docker CLI)

**Configuration Method**: `configs/` (config.json) + environment variables

**Environment Variables**:
- `DOCKER_CONFIG` - Docker config directory location (XDG compliant)
- `DOCKER_HOST` - Docker daemon socket
- `DOCKER_TLS_VERIFY` - Enable TLS verification
- `DOCKER_CERT_PATH` - TLS certificate path
- `DOCKER_API_VERSION` - API version to use
- `DOCKER_CLI_EXPERIMENTAL` - Enable experimental features
- `DOCKER_BUILDKIT` - Enable BuildKit
- `DOCKER_DEFAULT_PLATFORM` - Default platform for builds

**XDG Support**: 
- Native XDG support via `DOCKER_CONFIG`
- Config: `$XDG_CONFIG_HOME/docker` (default: `~/.docker`)
- Config file: `config.json` in config directory

**File Management Requirements**:
- Config file: `config.json` in config directory
- TLS certificates in config directory
- Plugin configurations in config directory
- JSON format configuration

**Current Configuration Status**: ❌ Not configured - needs config file + environment variables

---

### docker-compose (Multi-container Docker Applications)

**Configuration Method**: Project-specific compose files + environment variables

**Environment Variables**:
- `COMPOSE_FILE` - Compose file location(s)
- `COMPOSE_PROJECT_NAME` - Project name override
- `COMPOSE_API_VERSION` - Compose API version
- `COMPOSE_HTTP_TIMEOUT` - HTTP timeout for API calls
- `COMPOSE_TLS_VERSION` - TLS version for API calls
- `COMPOSE_CONVERT_WINDOWS_PATHS` - Convert Windows paths
- `COMPOSE_PATH_SEPARATOR` - Path separator for COMPOSE_FILE
- `COMPOSE_IGNORE_ORPHANS` - Ignore orphaned containers

**XDG Support**: 
- No user configuration files
- Project-specific compose files only
- Uses Docker client configuration for daemon connection

**File Management Requirements**:
- Project files: `docker-compose.yml`, `docker-compose.override.yml`
- Environment files: `.env` in project directory
- No user-specific configuration files
- YAML format configuration

**Current Configuration Status**: ❌ Not configured - could benefit from templates

---

### colima (Container Runtime for macOS/Linux)

**Configuration Method**: `configs/` (colima.yaml) + environment variables

**Environment Variables**:
- `COLIMA_HOME` - Colima data directory
- `DOCKER_HOST` - Docker socket (set by colima)
- `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE` - Testcontainers socket override

**XDG Support**: 
- No native XDG support
- Data directory: `~/.colima` by default
- Can be redirected via `COLIMA_HOME`

**File Management Requirements**:
- Config file: `colima.yaml` in data directory
- VM data and logs in data directory
- SSH keys and certificates in data directory
- YAML format configuration

**Current Configuration Status**: ❌ Not configured - needs config file + environment variables

---

### podman (Daemonless Container Engine)

**Configuration Method**: `configs/` (containers.conf, storage.conf) + environment variables

**Environment Variables**:
- `CONTAINERS_CONF` - Main config file location
- `CONTAINERS_STORAGE_CONF` - Storage config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory
- `XDG_DATA_HOME` - Respects XDG for data directory
- `XDG_RUNTIME_DIR` - Runtime directory for sockets
- `PODMAN_USERNS` - User namespace mode
- `BUILDAH_ISOLATION` - Container isolation mode

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/containers/` (default: `~/.config/containers/`)
- Data: `$XDG_DATA_HOME/containers/` (default: `~/.local/share/containers/`)
- Runtime: `$XDG_RUNTIME_DIR/containers/` (default: `/run/user/$UID/containers/`)

**File Management Requirements**:
- Config files: `containers.conf`, `storage.conf` in config directory
- Container images and data in data directory
- Runtime sockets and locks in runtime directory
- TOML format configuration

**Current Configuration Status**: ❌ Not configured - needs config files

## Container Tools

### dive (Docker Image Layer Explorer)

**Configuration Method**: `configs/` (.dive.yaml) + environment variables

**Environment Variables**:
- `DIVE_CONFIG` - Config file location
- `DOCKER_API_VERSION` - Docker API version
- `CI` - CI mode detection

**XDG Support**: 
- No native XDG support
- Config file: `~/.dive.yaml` by default
- Can be redirected via `DIVE_CONFIG` to XDG config directory

**File Management Requirements**:
- Config file: `.dive.yaml` (can be in XDG config directory)
- YAML format configuration
- Keybinding and UI customization

**Current Configuration Status**: ❌ Not configured - needs config file

---

### lazydocker (Terminal UI for Docker)

**Configuration Method**: `configs/` (config.yml) + environment variables

**Environment Variables**:
- `DOCKER_HOST` - Docker daemon socket
- `DOCKER_API_VERSION` - Docker API version
- `XDG_CONFIG_HOME` - Respects XDG for config directory

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/lazydocker/config.yml` (default: `~/.config/lazydocker/config.yml`)

**File Management Requirements**:
- Config file: `config.yml` in XDG config directory
- YAML format configuration
- UI customization and keybindings

**Current Configuration Status**: ❌ Not configured - needs config file

---

### buildkit (Docker Build Backend)

**Configuration Method**: `configs/` (buildkitd.toml) + environment variables

**Environment Variables**:
- `BUILDKIT_HOST` - BuildKit daemon socket
- `BUILDKIT_PROGRESS` - Progress output mode
- `BUILDKIT_COLORS` - Color output control
- `BUILDX_CONFIG` - Buildx config directory (XDG compliant)

**XDG Support**: 
- Partial XDG support via `BUILDX_CONFIG`
- Config: `$XDG_CONFIG_HOME/docker/buildx` (default: `~/.docker/buildx`)
- Daemon config: System-level `/etc/buildkit/buildkitd.toml`

**File Management Requirements**:
- Daemon config: `buildkitd.toml` (system-level)
- Buildx config: Builder configurations in XDG config directory
- Cache data in system directories
- TOML format configuration

**Current Configuration Status**: ❌ Not configured - needs config files

---

### hadolint (Dockerfile Linter)

**Configuration Method**: `configs/` (.hadolint.yaml) + environment variables

**Environment Variables**:
- `HADOLINT_CONFIG` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `HADOLINT_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Global config: `.hadolint.yaml` (can be in XDG config directory)
- Project config: `.hadolint.yaml` in project root
- YAML format configuration
- Rule configuration and ignores

**Current Configuration Status**: ❌ Not configured - needs config file

## Build Tools

### cmake (Cross-platform Build System)

**Configuration Method**: Environment variables + project files

**Environment Variables**:
- `CMAKE_PREFIX_PATH` - Package search paths
- `CMAKE_MODULE_PATH` - CMake module search paths
- `CMAKE_BUILD_TYPE` - Default build type
- `CMAKE_INSTALL_PREFIX` - Default install prefix
- `CMAKE_GENERATOR` - Default generator
- `CMAKE_TOOLCHAIN_FILE` - Toolchain file location
- `CMAKE_C_COMPILER` - C compiler
- `CMAKE_CXX_COMPILER` - C++ compiler

**XDG Support**: 
- No user configuration files
- Project-specific `CMakeLists.txt` and `cmake/` directories
- Build artifacts in project build directories

**File Management Requirements**:
- Project files: `CMakeLists.txt`, `cmake/` directory
- Build directory: Typically `build/` in project
- No user-specific configuration files
- CMake language configuration

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### pkg-config (Library Metadata Tool)

**Configuration Method**: Environment variables + .pc files

**Environment Variables**:
- `PKG_CONFIG_PATH` - Package config file search paths
- `PKG_CONFIG_LIBDIR` - Library directory search paths
- `PKG_CONFIG_SYSROOT_DIR` - Sysroot directory
- `PKG_CONFIG_TOP_BUILD_DIR` - Top build directory
- `PKG_CONFIG_DEBUG_SPEW` - Debug output
- `PKG_CONFIG_DISABLE_UNINSTALLED` - Disable uninstalled packages

**XDG Support**: 
- No user configuration files
- System and library-specific `.pc` files
- Search paths can include XDG directories

**File Management Requirements**:
- Package files: `.pc` files in library directories
- No user configuration files
- Search path configuration via environment variables

**Current Configuration Status**: ❌ Not configured - needs environment variables

## Secret Management

### vault (HashiCorp Vault CLI)

**Configuration Method**: `configs/` (config.hcl) + environment variables

**Environment Variables**:
- `VAULT_ADDR` - Vault server address
- `VAULT_TOKEN` - Authentication token
- `VAULT_CACERT` - CA certificate file
- `VAULT_CAPATH` - CA certificate directory
- `VAULT_CLIENT_CERT` - Client certificate file
- `VAULT_CLIENT_KEY` - Client private key file
- `VAULT_NAMESPACE` - Vault namespace
- `VAULT_CONFIG_PATH` - Config file location
- `VAULT_CLI_NO_COLOR` - Disable colored output

**XDG Support**: 
- No native XDG support
- Config file location configurable via `VAULT_CONFIG_PATH`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `config.hcl` (can be in XDG config directory)
- Token file: `.vault-token` in home directory
- Certificate files in specified locations
- HCL format configuration

**Current Configuration Status**: ❌ Not configured - needs config file + environment variables

---

### pass (Password Store)

**Configuration Method**: Environment variables + GPG integration

**Environment Variables**:
- `PASSWORD_STORE_DIR` - Password store directory (XDG compliant)
- `PASSWORD_STORE_KEY` - GPG key ID
- `PASSWORD_STORE_GIT` - Git repository URL
- `PASSWORD_STORE_CLIP_TIME` - Clipboard timeout
- `PASSWORD_STORE_UMASK` - File creation umask
- `PASSWORD_STORE_GENERATED_LENGTH` - Default password length
- `PASSWORD_STORE_CHARACTER_SET` - Character set for generation
- `PASSWORD_STORE_ENABLE_EXTENSIONS` - Enable extensions

**XDG Support**: 
- Partial XDG support via `PASSWORD_STORE_DIR`
- Store: `$XDG_DATA_HOME/pass` or `~/.password-store`
- No configuration files - all via environment variables

**File Management Requirements**:
- Password store directory in XDG data directory
- GPG-encrypted password files
- Git repository for synchronization
- No configuration files

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### gopass (Team Password Manager)

**Configuration Method**: `configs/` (config.yml) + environment variables

**Environment Variables**:
- `GOPASS_CONFIG` - Config file location
- `GOPASS_HOMEDIR` - Gopass home directory (XDG compliant)
- `GOPASS_GPG_OPTS` - GPG options
- `GOPASS_CLIPBOARD_TIMEOUT` - Clipboard timeout
- `GOPASS_NO_NOTIFY` - Disable notifications
- `GOPASS_DEBUG` - Debug mode

**XDG Support**: 
- Native XDG support via `GOPASS_HOMEDIR`
- Config: `$XDG_CONFIG_HOME/gopass/config.yml` (default: `~/.config/gopass/config.yml`)
- Data: `$XDG_DATA_HOME/gopass` (default: `~/.local/share/gopass`)

**File Management Requirements**:
- Config file: `config.yml` in XDG config directory
- Password stores in XDG data directory
- GPG keys and certificates
- YAML format configuration

**Current Configuration Status**: ❌ Not configured - needs config file + environment variables

## Summary

### Configuration Coverage Analysis

**Fully Configured Tools**: 0/12 (0%)
- No tools are currently configured

**Partially Configured Tools**: 0/12 (0%)

**Unconfigured Tools**: 12/12 (100%)
- docker-client (needs config + environment variables)
- docker-compose (could benefit from templates)
- colima (needs config + environment variables)
- podman (needs config files)
- dive (needs config file)
- lazydocker (needs config file)
- buildkit (needs config files)
- hadolint (needs config file)
- cmake (needs environment variables)
- pkg-config (needs environment variables)
- vault (needs config + environment variables)
- pass (needs environment variables)
- gopass (needs config + environment variables)

### Priority Implementation Recommendations

**High Priority** (Essential container tools):
1. docker-client - Docker CLI, needs config + environment variables
2. colima - Container runtime for macOS, needs config + environment variables
3. podman - Alternative container engine, needs config files
4. lazydocker - Docker TUI, needs config file
5. hadolint - Dockerfile linter, needs config file

**Medium Priority** (Development tools):
1. dive - Image layer explorer, needs config file
2. buildkit - Build backend, needs config files
3. cmake - Build system, needs environment variables
4. vault - Secret management, needs config + environment variables
5. gopass - Team password manager, needs config + environment variables

**Low Priority** (Specialized tools):
1. docker-compose - Could benefit from templates
2. pkg-config - Library metadata, needs environment variables
3. pass - Simple password store, needs environment variables

### XDG Compliance Status

**Native XDG Support**: 4/12 (33%)
- docker-client, podman, lazydocker, gopass

**Environment Variable XDG**: 4/12 (33%)
- colima, dive, hadolint, vault, pass

**No XDG Support**: 4/12 (33%)
- docker-compose, buildkit, cmake, pkg-config

### Environment Variable Requirements

**Tools Needing Environment Variables**: 11/12 (92%)
- All tools except docker-compose

**XDG-Related Variables Needed**:
- `DOCKER_CONFIG=$XDG_CONFIG_HOME/docker`
- `COLIMA_HOME=$XDG_DATA_HOME/colima`
- `DIVE_CONFIG=$XDG_CONFIG_HOME/dive/config.yaml`
- `HADOLINT_CONFIG=$XDG_CONFIG_HOME/hadolint/config.yaml`
- `VAULT_CONFIG_PATH=$XDG_CONFIG_HOME/vault/config.hcl`
- `PASSWORD_STORE_DIR=$XDG_DATA_HOME/pass`
- `GOPASS_HOMEDIR=$XDG_CONFIG_HOME/gopass`
- `BUILDX_CONFIG=$XDG_CONFIG_HOME/docker/buildx`

### Configuration File Requirements

**Tools Needing Config Files**: 8/12 (67%)
- docker-client (config.json)
- colima (colima.yaml)
- podman (containers.conf, storage.conf)
- dive (.dive.yaml)
- lazydocker (config.yml)
- buildkit (buildkitd.toml)
- hadolint (.hadolint.yaml)
- vault (config.hcl)
- gopass (config.yml)

**Tools Needing Only Environment Variables**: 3/12 (25%)
- cmake, pkg-config, pass

**Tools Needing Templates**: 1/12 (8%)
- docker-compose (compose file templates)

### Security Considerations

**Tools Handling Secrets**: 4/12 (33%)
- docker-client (registry credentials)
- vault (authentication tokens)
- pass (password store)
- gopass (password store)

**Certificate Management**: 3/12 (25%)
- docker-client (TLS certificates)
- vault (TLS certificates)
- buildkit (registry certificates)

### Platform-Specific Considerations

**macOS-Specific**: 1/12 (8%)
- colima (primary container runtime for macOS)

**Linux-Specific**: 1/12 (8%)
- podman (more common on Linux)

**Cross-Platform**: 10/12 (83%)
- Most tools work across platforms with same configuration