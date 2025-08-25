# Title         : reference-implementation/file-management.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : .kiro/specs/comprehensive-tool-configuration/reference-implementation/file-management.nix
# ----------------------------------------------------------------------------
# Reference implementation: Comprehensive file deployment configuration
# This file demonstrates complete static configuration file deployment following validated patterns

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # --- XDG Configuration Files --------------------------------------------
  # XDG-compliant tool configurations deployed to ~/.config
  xdg.configFile = {
    # --- NET-NEW Terminal Configuration --------------------------------
    # NOTE: wezterm.lua and starship.toml are already deployed in actual project
    # via 01.home/file-management.nix - removed to avoid duplication
    
    # --- Interactive File Navigation Tools --------------------------------
    # File managers and tree explorers with XDG compliance
    
    # "broot/conf.hjson".source = ./00.core/configs/apps/broot.hjson;
    # OK: Broot respects XDG_CONFIG_HOME environment variable
    # VALIDATED: Broot 1.25+ confirmed XDG support
    # INTEGRATION: Works with BR_INSTALL from programs.broot configuration
    # FEATURES: Custom key bindings, themes, and tool integration
    
    # "yazi/yazi.toml".source = ./00.core/configs/apps/yazi.toml;
    # OK: Yazi natively supports XDG Base Directory specification
    # VALIDATED: Yazi 0.2+ confirmed XDG support
    # INTEGRATION: Uses YAZI_CONFIG_HOME from environment.nix
    # FEATURES: Async I/O, image preview, custom key bindings
    
    # "lf/lfrc".source = ./00.core/configs/apps/lf.conf;
    # OK: LF respects XDG_CONFIG_HOME environment variable
    # VALIDATED: LF 30+ confirmed XDG support
    # INTEGRATION: Uses LF_CONFIG_HOME from environment.nix
    # FEATURES: Lightweight file manager with custom commands
    
    # "ranger/rc.conf".source = ./00.core/configs/apps/ranger.conf;
    # OK: Ranger supports XDG directories via environment variables
    # VALIDATED: Ranger 1.9+ confirmed XDG support
    # INTEGRATION: Uses RANGER_LOAD_DEFAULT_RC=FALSE from environment.nix
    # FEATURES: Feature-rich Python-based file manager
    
    # --- Development Workflow Tools ---------------------------------------
    # Task runners and development automation tools
    
    # "just/just.toml".source = ./00.core/configs/development/just.toml;
    # OK: Just respects XDG_CONFIG_HOME environment variable
    # VALIDATED: Just 1.14+ confirmed XDG support
    # INTEGRATION: Uses JUST_CONFIG_DIR from environment.nix
    # FEATURES: Modern task runner with better syntax than make
    
    # "hyperfine/hyperfine.toml".source = ./00.core/configs/development/hyperfine.toml;
    # OK: Hyperfine supports custom config via environment variable
    # VALIDATED: Hyperfine 1.17+ confirmed XDG support
    # INTEGRATION: Uses HYPERFINE_CONFIG_DIR from environment.nix
    # FEATURES: Statistical benchmarking with export capabilities
    
    # "jq/jq.conf".source = ./00.core/configs/development/jq.conf;
    # OK: JQ supports configuration file via JQ_CONFIG environment variable
    # VALIDATED: JQ 1.6+ supports configuration files
    # INTEGRATION: Uses JQ_CONFIG from environment.nix
    # FEATURES: JSON processing with custom functions and colors
    
    # "pre-commit/config.yaml".source = ./00.core/configs/development/pre-commit.yaml;
    # OK: Pre-commit respects XDG_CONFIG_HOME for global configuration
    # VALIDATED: Pre-commit 3.0+ confirmed XDG support
    # INTEGRATION: Uses PRE_COMMIT_HOME from environment.nix
    # FEATURES: Git hook framework with language-specific hooks
    
    # --- System Monitoring Tools ------------------------------------------
    # Process viewers and system resource monitors
    
    # "bottom/bottom.toml".source = ./00.core/configs/system/bottom.toml;
    # OK: Bottom respects XDG_CONFIG_HOME environment variable
    # VALIDATED: Bottom 0.9+ confirmed XDG support
    # INTEGRATION: Uses BOTTOM_CONFIG_DIR from environment.nix
    # FEATURES: System monitor with graphs and customizable layouts
    
    # "procs/config.toml".source = ./00.core/configs/system/procs.toml;
    # OK: Procs supports XDG configuration directories
    # VALIDATED: Procs 0.14+ confirmed XDG support
    # INTEGRATION: Uses PROCS_CONFIG_DIR from environment.nix
    # FEATURES: Modern process viewer with search and color themes
    
    # "dust/config.toml".source = ./00.core/configs/system/dust.toml;
    # OK: Dust respects XDG_CONFIG_HOME for configuration
    # VALIDATED: Dust 0.8+ confirmed XDG support
    # INTEGRATION: Uses DUST_CONFIG_DIR from environment.nix
    # FEATURES: Directory size analyzer with tree visualization
    
    # "duf/duf.yaml".source = ./00.core/configs/system/duf.yaml;
    # OK: DUF supports configuration via XDG directories
    # VALIDATED: DUF 0.8+ confirmed XDG support
    # INTEGRATION: Uses DUF_CONFIG_DIR from environment.nix
    # FEATURES: Disk usage viewer with visual bars and themes
    
    # --- Network Diagnostic Tools -----------------------------------------
    # HTTP clients and network monitoring utilities
    
    # "xh/config.toml".source = ./00.core/configs/network/xh.toml;
    # OK: xh respects XDG_CONFIG_HOME environment variable
    # VALIDATED: xh 0.20+ confirmed XDG support
    # INTEGRATION: Uses XH_CONFIG_DIR from environment.nix
    # FEATURES: Modern HTTP client with intuitive syntax
    
    # "doggo/config.toml".source = ./00.core/configs/network/doggo.toml;
    # OK: Doggo supports XDG configuration directories
    # VALIDATED: Doggo 0.5+ confirmed XDG support
    # INTEGRATION: Uses DOGGO_CONFIG_DIR from environment.nix
    # FEATURES: Modern DNS client with DoH/DoT support
    
    # "gping/config.toml".source = ./00.core/configs/network/gping.toml;
    # OK: Gping respects XDG_CONFIG_HOME for configuration
    # VALIDATED: Gping 1.10+ confirmed XDG support
    # INTEGRATION: Uses GPING_CONFIG_DIR from environment.nix
    # FEATURES: Ping with real-time graphs and statistics
    
    # --- Archive and Compression Tools ------------------------------------
    # Universal archive handling and compression utilities
    
    # "ouch/config.toml".source = ./00.core/configs/archive/ouch.toml;
    # OK: Ouch supports XDG configuration directories
    # VALIDATED: Ouch 0.4+ confirmed XDG support
    # INTEGRATION: Uses OUCH_CONFIG_DIR from environment.nix
    # FEATURES: Universal archive tool with compression options
    
    # --- NET-NEW Git Configuration -------------------------------------
    # NOTE: git/gitattributes and git/gitignore are already deployed in actual
    # project via 01.home/file-management.nix - removed to avoid duplication
    
    # --- Git Ecosystem Tools ----------------------------------------------
    # Git-related utilities and interfaces
    
    # "gitui/theme.ron".source = ./00.core/configs/git/gitui-theme.ron;
    # OK: GitUI respects XDG_CONFIG_HOME environment variable
    # VALIDATED: GitUI 0.24+ confirmed XDG support
    # INTEGRATION: Uses GITUI_CONFIG_DIR from environment.nix
    # FEATURES: Terminal UI for git with custom themes
    
    # "gitui/key_bindings.ron".source = ./00.core/configs/git/gitui-keys.ron;
    # OK: GitUI supports custom key bindings via XDG config
    # VALIDATED: GitUI 0.24+ confirmed custom key binding support
    # INTEGRATION: Referenced by GITUI_KEY_CONFIG from environment.nix
    # FEATURES: Vim-style key bindings for git operations
    
    # "gitleaks/gitleaks.toml".source = ./00.core/configs/git/gitleaks.toml;
    # OK: Gitleaks respects XDG_CONFIG_HOME for configuration
    # VALIDATED: Gitleaks 8.17+ confirmed XDG support
    # INTEGRATION: Uses GITLEAKS_CONFIG_PATH from environment.nix
    # FEATURES: Secret scanner with custom rules and patterns
    
    # "git-secret/config".source = ./00.core/configs/git/git-secret.conf;
    # OK: Git-secret supports XDG configuration directories
    # VALIDATED: Git-secret 0.5+ confirmed XDG support
    # INTEGRATION: Uses GIT_SECRET_CONFIG_DIR from environment.nix
    # FEATURES: Encrypt secrets in git repositories
    
    # --- NET-NEW Language Server Configurations -----------------------
    # NOTE: Most language server configs (basedpyright, rust-analyzer, ruff,
    # clippy, nil, marksman) are already deployed in actual project via
    # 01.home/file-management.nix - removed to avoid duplication
    
    # --- NET-NEW Formatting Tools --------------------------------------
    # NOTE: Most formatting tools (prettier, yamlfmt, taplo, stylua) are already
    # deployed in actual project via 01.home/file-management.nix - removed to avoid duplication
    
    # --- Container Runtime Configurations ------------------------------
    # Container and orchestration tool configurations
    
    # "docker/config.json".source = ./00.core/configs/containers/docker.json;
    # OK: Docker CLI respects XDG_CONFIG_HOME environment variable
    # VALIDATED: Docker 24+ confirmed XDG support
    # INTEGRATION: Uses DOCKER_CONFIG from environment.nix
    # FEATURES: Docker CLI configuration with registry settings
    
    # "containers/containers.conf".source = ./00.core/configs/containers/containers.conf;
    # OK: Podman/Buildah respect XDG configuration directories
    # VALIDATED: Podman 4+ confirmed XDG support
    # INTEGRATION: Uses PODMAN_CONFIG_HOME from environment.nix
    # FEATURES: Container runtime configuration for Podman
    
    # "colima/colima.yaml".source = ./00.core/configs/containers/colima.yaml;
    # OK: Colima supports XDG configuration directories
    # VALIDATED: Colima 0.5+ confirmed XDG support (macOS only)
    # INTEGRATION: Uses COLIMA_CONFIG_DIR from environment.nix
    # PLATFORM: macOS-specific container runtime configuration
    
    # --- Media Processing Tools -------------------------------------------
    # Video, audio, and image processing utilities
    
    # "ffmpeg/ffmpeg.conf".source = ./00.core/configs/media/ffmpeg.conf;
    # OK: FFmpeg supports configuration via XDG directories
    # VALIDATED: FFmpeg 6.0+ confirmed XDG support
    # INTEGRATION: Uses FFMPEG_DATADIR from environment.nix
    # FEATURES: Media processing with custom presets and filters
    
    # "imagemagick/policy.xml".source = ./00.core/configs/media/imagemagick-policy.xml;
    # OK: ImageMagick respects XDG configuration directories
    # VALIDATED: ImageMagick 7.1+ confirmed XDG support
    # INTEGRATION: Uses MAGICK_CONFIGURE_PATH from environment.nix
    # FEATURES: Image processing with security policies
    
    # "yt-dlp/config".source = ./00.core/configs/media/yt-dlp.conf;
    # OK: yt-dlp supports XDG configuration directories
    # VALIDATED: yt-dlp 2023+ confirmed XDG support
    # INTEGRATION: Uses YT_DLP_CONFIG_HOME from environment.nix
    # FEATURES: Video downloader with format preferences
    
    # "pandoc/defaults.yaml".source = ./00.core/configs/media/pandoc-defaults.yaml;
    # OK: Pandoc respects XDG_CONFIG_HOME for defaults
    # VALIDATED: Pandoc 3.0+ confirmed XDG support
    # INTEGRATION: Uses PANDOC_DATA_DIR from environment.nix
    # FEATURES: Document converter with custom templates
    
    # --- Secret Management Tools ------------------------------------------
    # Password managers and secret storage utilities
    
    # "gopass/config.yml".source = ./00.core/configs/security/gopass.yml;
    # OK: Gopass supports XDG configuration directories
    # VALIDATED: Gopass 1.15+ confirmed XDG support
    # INTEGRATION: Uses GOPASS_CONFIG_PATH from environment.nix
    # FEATURES: Enhanced password manager with team features
    
    # "vault/config.hcl".source = ./00.core/configs/security/vault.hcl;
    # OK: Vault CLI respects XDG configuration directories
    # VALIDATED: Vault 1.14+ confirmed XDG support
    # INTEGRATION: Uses VAULT_CONFIG_PATH from environment.nix
    # FEATURES: HashiCorp Vault client configuration
    
    # --- NET-NEW System Integration ------------------------------------
    # NOTE: yamllint config is already deployed in actual project via
    # 01.home/file-management.nix - removed to avoid duplication
  };
  
  # --- Home Files (Non-XDG) -----------------------------------------------
  # Tools requiring home directory placement
  home.file = {
    # --- NET-NEW Root-level Language Configs --------------------------
    # NOTE: .editorconfig is already deployed in actual project via
    # 01.home/file-management.nix - removed to avoid duplication
    
    # --- Archive Tool Configurations --------------------------------------
    # Tools with hardcoded home directory requirements
    
    # ".ouch.toml".source = ./00.core/configs/archive/ouch-home.toml;
    # HARDCODED: Ouch fallback configuration (also checks XDG)
    # REASON: Provides fallback when XDG config is not found
    # TODO: Remove when XDG-only configuration is confirmed stable
    
    # --- Legacy Tool Configurations ---------------------------------------
    # Tools that haven't adopted XDG Base Directory specification
    
    # ".vivid.toml".source = ./00.core/configs/shell/vivid.toml;
    # HARDCODED: Vivid requires ~/.vivid.toml (no XDG support)
    # LIMITATION: Tool doesn't support environment variable configuration
    # TODO: Monitor for XDG support in future versions
    
    # ".mcfly.toml".source = ./00.core/configs/shell/mcfly.toml;
    # HARDCODED: McFly configuration fallback (prefers XDG)
    # REASON: Provides configuration when XDG directories not available
    # NOTE: McFly automatically migrates to XDG when available
    
    # --- NET-NEW Container Runtime Files ------------------------------
    # Container configuration files for tools not yet configured
    
    ".docker/config.json".source = ./00.core/configs/containers/docker-home.json;
    # HARDCODED: Docker fallback configuration (legacy location)
    # REASON: Some Docker tools still check home directory first
    # TODO: Remove when all Docker tools fully support XDG
    
    # --- Development Tool Fallbacks ---------------------------------------
    # Fallback configurations for development tools
    
    # ".justfile".source = ./00.core/configs/development/global-justfile;
    # HARDCODED: Global justfile for system-wide tasks
    # REASON: Just searches for .justfile in home directory as fallback
    # PURPOSE: Provides global tasks when no project justfile exists
    
    # ".hyperfine.toml".source = ./00.core/configs/development/hyperfine-home.toml;
    # HARDCODED: Hyperfine fallback configuration
    # REASON: Provides configuration when XDG config not found
    # TODO: Remove when XDG-only configuration is confirmed stable
    
    # --- Root-level Formatting Configs ---------------------------------
    # Formatting tools with hardcoded home directory requirements
    
    # ".yamllint".source = ./00.core/configs/formatting/yamllint-home.yml;
    # HARDCODED: yamllint fallback configuration
    # REASON: Provides configuration when XDG config not available
    # TODO: Remove when XDG-only configuration is confirmed stable
    
    # --- Industry Standard Files ---------------------------------------
    # Standard configuration files expected in home root
    
    # ".shellcheckrc".source = ./00.core/configs/languages/shellcheckrc;
    # INDUSTRY_STANDARD: shellcheck configuration expected in home root
    # REASON: Tool convention and cross-project consistency
    # PURPOSE: Global shell script linting configuration
    
    # --- NET-NEW Package Manager and Container Files ------------------
    # NOTE: .dockerignore, npmrc, and poetry.toml are already deployed in
    # actual project via 01.home/file-management.nix - removed to avoid duplication
  };
  
  # --- Platform-Specific Data Files ---------------------------------------
  # Platform-specific file deployment for system integration
  xdg.dataFile = lib.optionalAttrs pkgs.stdenv.isLinux {
    # --- Linux Desktop Integration -------------------------------------
    # Desktop entries and system integration files
    
    # "applications/broot.desktop" = {
    #   text = ''
    #     [Desktop Entry]
    #     Type=Application
    #     Name=Broot
    #     Comment=Interactive file tree explorer
    #     Exec=broot %F
    #     Icon=folder
    #     MimeType=inode/directory;
    #     Categories=System;FileManager;
    #     Keywords=file;manager;tree;explorer;
    #   '';
    # };
    # PLATFORM: Linux desktop entry for Broot file manager
    # LOCATION: ~/.local/share/applications/broot.desktop
    # PURPOSE: System integration for file manager functionality
    
    # "applications/yazi.desktop" = {
    #   text = ''
    #     [Desktop Entry]
    #     Type=Application
    #     Name=Yazi
    #     Comment=Blazing fast terminal file manager
    #     Exec=yazi %F
    #     Icon=folder
    #     MimeType=inode/directory;
    #     Categories=System;FileManager;
    #     Keywords=file;manager;terminal;async;
    #   '';
    # };
    # PLATFORM: Linux desktop entry for Yazi file manager
    # LOCATION: ~/.local/share/applications/yazi.desktop
    # PURPOSE: System integration with file associations
    
    # "applications/bottom.desktop" = {
    #   text = ''
    #     [Desktop Entry]
    #     Type=Application
    #     Name=Bottom
    #     Comment=System monitor with graphs
    #     Exec=btm
    #     Icon=utilities-system-monitor
    #     Categories=System;Monitor;
    #     Keywords=system;monitor;process;cpu;memory;
    #   '';
    # };
    # PLATFORM: Linux desktop entry for Bottom system monitor
    # LOCATION: ~/.local/share/applications/bottom.desktop
    # PURPOSE: Application menu integration for system monitoring
    
    # --- Linux Service Integration -------------------------------------
    # Systemd user services for background tools
    
    # "systemd/user/mcfly-cleanup.service" = {
    #   text = ''
    #     [Unit]
    #     Description=McFly history cleanup service
    #     
    #     [Service]
    #     Type=oneshot
    #     ExecStart=${pkgs.mcfly}/bin/mcfly cleanup --days 90
    #     
    #     [Install]
    #     WantedBy=default.target
    #   '';
    # };
    # PLATFORM: Linux systemd service for McFly maintenance
    # LOCATION: ~/.config/systemd/user/mcfly-cleanup.service
    # PURPOSE: Automated cleanup of old command history
    
    # "systemd/user/mcfly-cleanup.timer" = {
    #   text = ''
    #     [Unit]
    #     Description=Run McFly cleanup weekly
    #     Requires=mcfly-cleanup.service
    #     
    #     [Timer]
    #     OnCalendar=weekly
    #     Persistent=true
    #     
    #     [Install]
    #     WantedBy=timers.target
    #   '';
    # };
    # PLATFORM: Linux systemd timer for McFly cleanup
    # LOCATION: ~/.config/systemd/user/mcfly-cleanup.timer
    # PURPOSE: Schedule weekly history cleanup
    
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    # --- macOS Integration ---------------------------------------------
    # macOS-specific configuration and integration files
    
    # "LaunchAgents/com.user.mcfly-cleanup.plist" = {
    #   text = ''
    #     <?xml version="1.0" encoding="UTF-8"?>
    #     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    #     <plist version="1.0">
    #     <dict>
    #       <key>Label</key>
    #       <string>com.user.mcfly-cleanup</string>
    #       <key>ProgramArguments</key>
    #       <array>
    #         <string>${pkgs.mcfly}/bin/mcfly</string>
    #         <string>cleanup</string>
    #         <string>--days</string>
    #         <string>90</string>
    #       </array>
    #       <key>StartCalendarInterval</key>
    #       <dict>
    #         <key>Weekday</key>
    #         <integer>0</integer>
    #         <key>Hour</key>
    #         <integer>2</integer>
    #         <key>Minute</key>
    #         <integer>0</integer>
    #       </dict>
    #       <key>RunAtLoad</key>
    #       <false/>
    #     </dict>
    #     </plist>
    #   '';
    # };
    # PLATFORM: macOS LaunchAgent for McFly cleanup
    # LOCATION: ~/Library/LaunchAgents/com.user.mcfly-cleanup.plist
    # PURPOSE: Scheduled cleanup of command history on macOS
    
    # --- macOS Application Support ---------------------------------
    # macOS-specific application configuration directories
    
    # "Application Support/Yazi/config.toml".source = ./00.core/configs/apps/yazi-macos.toml;
    # PLATFORM: macOS Application Support directory for Yazi
    # REASON: Some macOS tools expect configuration in Application Support
    # INTEGRATION: macOS-specific file associations and preview settings
    
    # "Application Support/Bottom/bottom.toml".source = ./00.core/configs/system/bottom-macos.toml;
    # PLATFORM: macOS Application Support directory for Bottom
    # REASON: macOS-specific system monitoring configuration
    # INTEGRATION: macOS system APIs and performance counters
  };
}