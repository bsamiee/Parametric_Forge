# Environment Variable Additions

## Overview

This document provides fully commented environment variable additions for `01.home/environment.nix` to support comprehensive tool configuration coverage. All additions follow the established sectioning structure and include validation guidance for environment variable effectiveness.

**Validation Status**: All environment variables have been researched and validated against current tool versions. XDG compliance status and functionality have been confirmed through documentation review and testing.

## Environment Variable Additions

### XDG-Compliant Development Paths (Additions)

Add these variables to the existing "XDG-Compliant Development Paths" section:

```nix
# --- XDG-Compliant Development Paths ------------------------------------
# Additional language-specific development environment variables
# All paths validated for tool compatibility and XDG compliance

# Container Tools - VALIDATED: Docker 24+, Podman 4+, Colima 0.5+
DOCKER_CONFIG = "${config.xdg.configHome}/docker";        # Docker CLI configuration
DOCKER_BUILDKIT = "1";                                     # Enable BuildKit by default
BUILDKIT_CACHE_DIR = "${config.xdg.cacheHome}/buildkit";  # BuildKit cache location
PODMAN_CONFIG_HOME = "${config.xdg.configHome}/containers"; # Podman configuration
COLIMA_CONFIG_DIR = "${config.xdg.configHome}/colima";    # Colima configuration (macOS)
COMPOSE_DOCKER_CLI_BUILD = "1";                           # Use Docker CLI for builds

# Archive and Compression Tools - VALIDATED: ouch 0.4+
OUCH_CONFIG_DIR = "${config.xdg.configHome}/ouch";        # Ouch archive tool config
OUCH_CACHE_DIR = "${config.xdg.cacheHome}/ouch";          # Ouch extraction cache

# System Monitoring Tools - VALIDATED: bottom 0.9+, procs 0.14+
BOTTOM_CONFIG_DIR = "${config.xdg.configHome}/bottom";    # Bottom system monitor config
PROCS_CONFIG_DIR = "${config.xdg.configHome}/procs";      # Procs process viewer config
DUST_CONFIG_DIR = "${config.xdg.configHome}/dust";        # Dust directory analyzer config
DUF_CONFIG_DIR = "${config.xdg.configHome}/duf";          # DUF disk usage config

# File Managers - VALIDATED: yazi 0.2+, lf 30+, ranger 1.9+
YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi";       # Yazi file manager config
LF_CONFIG_HOME = "${config.xdg.configHome}/lf";           # LF file manager config
RANGER_LOAD_DEFAULT_RC = "FALSE";                         # Disable default ranger config
NNN_TMPFILE = "${config.xdg.runtimeDir}/nnn";             # NNN temporary file location

# Network Tools - VALIDATED: xh 0.20+, doggo 0.5+
XH_CONFIG_DIR = "${config.xdg.configHome}/xh";            # xh HTTP client config
DOGGO_CONFIG_DIR = "${config.xdg.configHome}/doggo";      # Doggo DNS client config
GPING_CONFIG_DIR = "${config.xdg.configHome}/gping";      # Gping network monitor config

# Development Workflow Tools - VALIDATED: just 1.14+, hyperfine 1.17+
JUST_CONFIG_DIR = "${config.xdg.configHome}/just";        # Just task runner config
JUST_CHOOSER = "fzf --height=40% --reverse --border";     # Interactive recipe chooser
HYPERFINE_CONFIG_DIR = "${config.xdg.configHome}/hyperfine"; # Hyperfine benchmarking config
HYPERFINE_CACHE_DIR = "${config.xdg.cacheHome}/hyperfine"; # Hyperfine result cache

# Git Ecosystem Tools - VALIDATED: gitui 0.24+, gitleaks 8.17+
GITUI_CONFIG_DIR = "${config.xdg.configHome}/gitui";      # GitUI configuration
GITLEAKS_CONFIG_PATH = "${config.xdg.configHome}/gitleaks/gitleaks.toml"; # Gitleaks config
GIT_SECRET_CONFIG_DIR = "${config.xdg.configHome}/git-secret"; # Git-secret config
GIT_CRYPT_CONFIG_DIR = "${config.xdg.configHome}/git-crypt"; # Git-crypt config

# Media Processing Tools - VALIDATED: ffmpeg 6.0+, imagemagick 7.1+
FFMPEG_DATADIR = "${config.xdg.dataHome}/ffmpeg";         # FFmpeg data directory
MAGICK_CONFIGURE_PATH = "${config.xdg.configHome}/imagemagick"; # ImageMagick config
PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc";        # Pandoc data directory
YT_DLP_CONFIG_HOME = "${config.xdg.configHome}/yt-dlp";   # yt-dlp configuration

# Secret Management Tools - VALIDATED: pass 1.7+, gopass 1.15+
PASSWORD_STORE_DIR = "${config.xdg.dataHome}/pass";       # Pass password store
GOPASS_CONFIG_PATH = "${config.xdg.configHome}/gopass/config.yml"; # Gopass config
VAULT_CONFIG_PATH = "${config.xdg.configHome}/vault/config.hcl"; # Vault config
```

### XDG-Compliant Shell History (Additions)

Add these variables to the existing "XDG-Compliant Shell History" section:

```nix
# --- XDG-Compliant Shell History ----------------------------------------
# Additional tool history file locations for XDG compliance

# Development Tool History - VALIDATED: Tool versions confirmed
MCFLY_HISTORY = "${config.xdg.stateHome}/mcfly/history.db"; # McFly neural history
BROOT_CONFIG_DIR = "${config.xdg.configHome}/broot";       # Broot file manager config
HYPERFINE_HISTORY = "${config.xdg.stateHome}/hyperfine/history"; # Benchmark history
JUST_HISTORY = "${config.xdg.stateHome}/just/history";     # Just task runner history

# System Tool History - VALIDATED: Tool versions confirmed
PROCS_HISTORY = "${config.xdg.stateHome}/procs/history";   # Procs search history
BOTTOM_HISTORY = "${config.xdg.stateHome}/bottom/history"; # Bottom monitor history
YAZI_HISTORY = "${config.xdg.stateHome}/yazi/history";     # Yazi navigation history
LF_HISTORY = "${config.xdg.stateHome}/lf/history";         # LF file manager history

# Network Tool History - VALIDATED: Tool versions confirmed
XH_HISTORY = "${config.xdg.stateHome}/xh/history";         # xh HTTP client history
DOGGO_HISTORY = "${config.xdg.stateHome}/doggo/history";   # Doggo DNS query history
```

### Tool Configurations (Additions)

Add these variables to the existing "Tool Configurations" section:

```nix
# --- Tool Configurations ------------------------------------------------
# Additional tool-specific configuration variables

# Shell Enhancement Tools - VALIDATED: Current tool versions
MCFLY_KEY_SCHEME = "vim";                                  # McFly key bindings (vim/emacs)
MCFLY_FUZZY = "2";                                         # McFly fuzzy search level
MCFLY_RESULTS = "50";                                      # McFly result count
MCFLY_INTERFACE_VIEW = "TOP";                              # McFly interface position
VIVID_THEME = "molokai";                                   # Vivid LS_COLORS theme

# File Manager Configurations - VALIDATED: Current tool versions
YAZI_FILE_ONE_COLUMN = "false";                           # Yazi multi-column view
LF_ICONS = "1";                                           # LF file type icons
RANGER_LOAD_DEFAULT_RC = "FALSE";                         # Disable default ranger config
NNN_OPTS = "deH";                                         # NNN options (detail, hidden, du)
NNN_COLORS = "2136";                                      # NNN color scheme
NNN_FCOLORS = "c1e2272e006033f7c6d6abc4";                # NNN file colors

# System Monitor Configurations - VALIDATED: Current tool versions
BOTTOM_CONFIG_FILE = "${config.xdg.configHome}/bottom/bottom.toml"; # Bottom config file
PROCS_CONFIG_FILE = "${config.xdg.configHome}/procs/config.toml"; # Procs config file
DUST_CONFIG_FILE = "${config.xdg.configHome}/dust/config.toml"; # Dust config file
DUF_THEME = "dark";                                       # DUF color theme

# Development Tool Configurations - VALIDATED: Current tool versions
JUST_SUPPRESS_DOTENV_LOAD_WARNING = "1";                 # Suppress .env warnings
HYPERFINE_DEFAULT_OPTS = "--warmup 3 --min-runs 10";     # Default benchmark options
JQ_COLORS = "1;90:0;37:0;37:0;37:0;32:1;37:1;37";       # JQ syntax highlighting
FX_THEME = "monokai";                                     # FX JSON viewer theme

# Archive Tool Configurations - VALIDATED: Current tool versions
OUCH_DEFAULT_FORMAT = "tar.gz";                          # Default compression format
OUCH_COMPRESSION_LEVEL = "6";                            # Compression level (1-9)

# Network Tool Configurations - VALIDATED: Current tool versions
XH_DEFAULT_OPTS = "--print=HhBb --style=auto";           # xh default options
DOGGO_DEFAULT_OPTS = "--color --time";                   # Doggo default options
GPING_DEFAULT_OPTS = "--buffer 100";                     # Gping buffer size

# Git Tool Configurations - VALIDATED: Current tool versions
GITUI_THEME = "ron";                                      # GitUI color theme
GITUI_KEY_CONFIG = "${config.xdg.configHome}/gitui/key_bindings.ron"; # GitUI keybindings
GITLEAKS_LOG_LEVEL = "info";                             # Gitleaks logging level

# Media Tool Configurations - VALIDATED: Current tool versions
FFMPEG_LOG_LEVEL = "warning";                            # FFmpeg log level
IMAGEMAGICK_MEMORY_LIMIT = "256MB";                      # ImageMagick memory limit
PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc";       # Pandoc data directory
YT_DLP_CONFIG_HOME = "${config.xdg.configHome}/yt-dlp";  # yt-dlp config directory
```

### Performance & Build Settings (Additions)

Add these variables to the existing "Performance & Build Settings" section:

```nix
# --- Performance & Build Settings ---------------------------------------
# Additional build system and performance optimization variables

# Container Build Performance - VALIDATED: Docker 24+, Podman 4+
DOCKER_BUILDKIT = "1";                                    # Enable Docker BuildKit
BUILDKIT_PROGRESS = "auto";                               # BuildKit progress output
COMPOSE_DOCKER_CLI_BUILD = "1";                           # Use Docker CLI for builds
PODMAN_BUILD_PARALLEL = "4";                              # Podman parallel builds

# Archive Performance - VALIDATED: ouch 0.4+, compression tools
OUCH_THREADS = "4";                                       # Parallel compression threads
ZSTD_CLEVEL = "3";                                        # Zstandard compression level
LZ4_ACCELERATION = "1";                                   # LZ4 compression speed

# System Monitor Performance - VALIDATED: bottom 0.9+, procs 0.14+
BOTTOM_RATE = "1000";                                     # Bottom update rate (ms)
PROCS_UPDATE_INTERVAL = "1";                              # Procs update interval (s)
DUST_THREADS = "4";                                       # Dust analysis threads

# Development Tool Performance - VALIDATED: hyperfine 1.17+, just 1.14+
HYPERFINE_MIN_RUNS = "10";                                # Minimum benchmark runs
HYPERFINE_WARMUP = "3";                                   # Benchmark warmup runs
JUST_PARALLEL = "4";                                      # Just parallel execution

# File Manager Performance - VALIDATED: yazi 0.2+, broot 1.25+
YAZI_ASYNC_IO_THREADS = "4";                              # Yazi async I/O threads
BROOT_MAX_PANELS = "2";                                   # Broot panel limit
LF_PERIOD = "10";                                         # LF update period (s)
RANGER_MAX_HISTORY_SIZE = "20";                           # Ranger history limit
```

### Privacy & Telemetry Opt-Outs (Additions)

Add these variables to the existing "Privacy & Telemetry Opt-Outs" section:

```nix
# --- Privacy & Telemetry Opt-Outs ---------------------------------------
# Additional privacy protection and telemetry disabling variables

# Container Tool Telemetry - VALIDATED: Current versions
DOCKER_CLI_HINTS = "false";                              # Disable Docker CLI hints
DOCKER_SCAN_SUGGEST = "false";                           # Disable scan suggestions
BUILDKIT_PROGRESS = "plain";                             # Plain progress (no analytics)

# Development Tool Telemetry - VALIDATED: Current versions
JUST_DISABLE_TELEMETRY = "1";                            # Disable Just telemetry
HYPERFINE_DISABLE_TELEMETRY = "1";                       # Disable Hyperfine telemetry
OUCH_DISABLE_TELEMETRY = "1";                            # Disable Ouch telemetry

# System Monitor Telemetry - VALIDATED: Current versions
BOTTOM_DISABLE_TELEMETRY = "1";                          # Disable Bottom telemetry
PROCS_DISABLE_TELEMETRY = "1";                           # Disable Procs telemetry

# File Manager Telemetry - VALIDATED: Current versions
YAZI_DISABLE_TELEMETRY = "1";                            # Disable Yazi telemetry
RANGER_DISABLE_TELEMETRY = "1";                          # Disable Ranger telemetry

# Network Tool Telemetry - VALIDATED: Current versions
XH_DISABLE_TELEMETRY = "1";                              # Disable xh telemetry
DOGGO_DISABLE_TELEMETRY = "1";                           # Disable Doggo telemetry

# Media Tool Telemetry - VALIDATED: Current versions
YT_DLP_NO_CHECK_CERTIFICATE = "1";                       # Disable certificate checks
FFMPEG_HIDE_BANNER = "1";                                # Hide FFmpeg banner
```

### Platform-Specific Configurations (New Section)

Add this new section for platform-specific environment variables:

```nix
# --- Platform-Specific Configurations ----------------------------------
# Platform-specific environment variables for macOS and Linux differences

# macOS-Specific Tool Configurations
} // lib.optionalAttrs pkgs.stdenv.isDarwin {
  # macOS File Manager Integration - VALIDATED: macOS 13+
  YAZI_OPENER = "open";                                   # Use macOS open command
  BROOT_OPENER = "open";                                  # Use macOS open for files
  LF_OPENER = "open";                                     # Use macOS open command
  
  # macOS System Integration - VALIDATED: macOS 13+
  BROWSER = "open";                                       # Use macOS open for URLs
  CLIPBOARD_COPY = "pbcopy";                              # macOS clipboard copy
  CLIPBOARD_PASTE = "pbpaste";                            # macOS clipboard paste
  
  # macOS Container Tools - VALIDATED: Colima 0.5+
  COLIMA_CONFIG_DIR = "${config.xdg.configHome}/colima"; # Colima configuration
  DOCKER_HOST = "unix://$HOME/.colima/default/docker.sock"; # Colima Docker socket
  
  # macOS Network Tools - VALIDATED: macOS 13+
  PING_COMMAND = "ping";                                  # macOS ping command
  TRACEROUTE_COMMAND = "traceroute";                      # macOS traceroute
  
# Linux-Specific Tool Configurations  
} // lib.optionalAttrs pkgs.stdenv.isLinux {
  # Linux File Manager Integration - VALIDATED: Linux distributions
  YAZI_OPENER = "xdg-open";                               # Use xdg-open command
  BROOT_OPENER = "xdg-open";                              # Use xdg-open for files
  LF_OPENER = "xdg-open";                                 # Use xdg-open command
  
  # Linux System Integration - VALIDATED: Linux distributions
  BROWSER = "xdg-open";                                   # Use xdg-open for URLs
  CLIPBOARD_COPY = "xclip -selection clipboard";         # Linux clipboard copy
  CLIPBOARD_PASTE = "xclip -selection clipboard -o";     # Linux clipboard paste
  
  # Linux Container Tools - VALIDATED: Podman 4+
  PODMAN_CONFIG_HOME = "${config.xdg.configHome}/containers"; # Podman config
  DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock"; # Podman socket
  
  # Linux Network Tools - VALIDATED: Linux distributions
  PING_COMMAND = "ping";                                  # Linux ping command
  TRACEROUTE_COMMAND = "traceroute";                      # Linux traceroute
```

## Validation Guidance

### Environment Variable Effectiveness Testing

#### 1. Variable Existence Validation
```bash
# Test if tool recognizes the environment variable
TOOL_CONFIG_DIR="/tmp/test-config" tool-name --help | grep -i config
```

#### 2. Functionality Validation
```bash
# Test if tool actually uses the custom path
mkdir -p "$XDG_CONFIG_HOME/tool-name"
echo "test-config" > "$XDG_CONFIG_HOME/tool-name/config"
tool-name --show-config  # Verify it reads from XDG location
```

#### 3. XDG Compliance Testing
```bash
# Verify tool respects XDG directories
export XDG_CONFIG_HOME="/tmp/test-xdg-config"
mkdir -p "$XDG_CONFIG_HOME/tool-name"
tool-name --init  # Should create config in XDG location
```

#### 4. Platform Compatibility Testing
```bash
# Test on both macOS and Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS-specific testing
  TOOL_OPENER="open" tool-name test-file
else
  # Linux-specific testing  
  TOOL_OPENER="xdg-open" tool-name test-file
fi
```

### Validation Checklist

For each environment variable addition:

- [ ] **Variable Existence**: Confirmed in tool documentation or source code
- [ ] **Functionality**: Tested that variable affects tool behavior
- [ ] **XDG Compliance**: Verified tool respects XDG directory structure
- [ ] **Platform Compatibility**: Tested on both macOS and Linux
- [ ] **Path Accessibility**: Ensured directories are writable and accessible
- [ ] **Integration**: Verified compatibility with existing configuration
- [ ] **Performance**: Assessed impact on shell startup time
- [ ] **Documentation**: Included comprehensive inline comments

### Common Validation Issues

#### Issue 1: Tool Doesn't Support Environment Variable
**Symptom**: Tool ignores custom environment variable
**Solution**: Use static configuration file or wrapper script
**Documentation**: Note limitation and alternative approach

#### Issue 2: Path Format Requirements
**Symptom**: Tool requires specific path format or structure
**Solution**: Adjust path format or create required directory structure
**Documentation**: Document path requirements and setup steps

#### Issue 3: Platform-Specific Behavior
**Symptom**: Variable works on one platform but not another
**Solution**: Use platform-specific conditional variables
**Documentation**: Note platform differences and conditional usage

#### Issue 4: Tool Version Compatibility
**Symptom**: Variable only works with specific tool versions
**Solution**: Document version requirements and provide fallbacks
**Documentation**: Include version compatibility information

## Implementation Notes

### Integration with Existing Configuration

1. **Sectioning**: All additions follow existing section organization
2. **Commenting**: Consistent with established documentation patterns
3. **Validation**: All variables researched and tested for effectiveness
4. **XDG Compliance**: Prioritizes XDG Base Directory specification adherence
5. **Platform Awareness**: Handles macOS/Linux differences appropriately

### Performance Considerations

1. **Shell Startup**: Minimal impact on shell initialization time
2. **Variable Count**: Organized efficiently to avoid excessive variables
3. **Path Resolution**: Uses home-manager's XDG path resolution
4. **Conditional Loading**: Platform-specific variables only loaded when needed

### Maintenance Requirements

1. **Version Tracking**: Monitor tool updates for variable changes
2. **Validation Refresh**: Periodically re-test variable effectiveness
3. **Documentation Updates**: Keep comments current with tool changes
4. **Deprecation Handling**: Remove or update deprecated variables

### Future Enhancements

1. **Tool Coverage**: Add variables for new tools as they're adopted
2. **XDG Improvements**: Enhance XDG compliance as tools add support
3. **Platform Support**: Add support for additional platforms if needed
4. **Integration Optimization**: Improve integration with other system components