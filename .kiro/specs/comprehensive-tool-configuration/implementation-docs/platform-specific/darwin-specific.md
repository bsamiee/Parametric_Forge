# macOS-Specific Configuration Requirements

## Overview

This document provides comprehensive documentation for macOS-specific configuration requirements, including tools that require Darwin-specific handling, macOS-specific file paths and environment variables, and integration patterns with existing Darwin configuration structures.

## macOS-Specific Tools Analysis

### Tools Requiring Darwin-Specific Configuration

Based on the tool inventory and research, the following tools require macOS-specific configuration handling:

#### macOS-Only Tools (5 tools)
1. **mas** - Mac App Store CLI
2. **_1password-cli** - 1Password command-line tool (cross-platform but macOS-optimized)
3. **dockutil** - macOS Dock management
4. **pngpaste** - PNG clipboard tool
5. **duti** - Default applications manager

#### Cross-Platform Tools with macOS-Specific Requirements (3 tools)
1. **neovim** - Text editor (macOS-specific paths and integrations)
2. **ffmpeg** - Media processing (macOS-specific codecs and frameworks)
3. **imagemagick** - Image processing (macOS-specific delegates and policies)

## macOS-Specific File Paths and Environment Variables

### System-Level Paths

#### macOS System Directories
```bash
# System configuration directories
/System/Library/          # System frameworks and resources
/Library/                 # System-wide application support
/Applications/            # System applications
/usr/local/               # Homebrew installation directory (Intel Macs)
/opt/homebrew/            # Homebrew installation directory (Apple Silicon)

# User-specific macOS directories
~/Library/                # User application support and preferences
~/Library/Application Support/  # Application data
~/Library/Preferences/    # Application preferences (plist files)
~/Library/Caches/         # Application caches
~/Library/Logs/           # Application logs
~/Library/LaunchAgents/   # User launch agents
```

#### XDG Base Directory Mapping for macOS
```bash
# XDG to macOS mapping (current implementation)
XDG_CONFIG_HOME="$HOME/.config"           # Standard XDG
XDG_DATA_HOME="$HOME/.local/share"        # Standard XDG
XDG_CACHE_HOME="$HOME/.cache"             # Standard XDG
XDG_STATE_HOME="$HOME/.local/state"       # Standard XDG
XDG_RUNTIME_DIR="$HOME/Library/Caches/TemporaryItems"  # macOS-specific

# Alternative macOS-native mapping (for consideration)
# XDG_CONFIG_HOME="$HOME/Library/Application Support"
# XDG_DATA_HOME="$HOME/Library/Application Support"
# XDG_CACHE_HOME="$HOME/Library/Caches"
# XDG_STATE_HOME="$HOME/Library/Application Support"
```

### Tool-Specific macOS Environment Variables

#### 1Password CLI
```bash
# macOS-specific 1Password paths
OP_CONFIG_DIR="$XDG_CONFIG_HOME/op"
OP_CACHE_DIR="$XDG_CACHE_HOME/op"
OP_DATA_DIR="$XDG_DATA_HOME/op"
OP_BIOMETRIC_UNLOCK_ENABLED="true"        # macOS Touch ID support
OP_SESSION_<account>="session_token"      # Account-specific sessions
```

#### Neovim (macOS Integration)
```bash
# macOS-specific Neovim environment
EDITOR="nvim"
VISUAL="nvim"
NVIM_APPNAME="nvim"                       # Application name for config isolation
# macOS clipboard integration (automatic)
# macOS notification integration (via terminal-notifier if available)
```

#### Media Tools (macOS-Specific)
```bash
# FFmpeg macOS-specific
FFMPEG_DATADIR="$XDG_DATA_HOME/ffmpeg"
# macOS-specific codec paths
FFMPEG_AVFOUNDATION_ENABLED="1"          # AVFoundation support
FFMPEG_VIDEOTOOLBOX_ENABLED="1"          # VideoToolbox hardware acceleration

# ImageMagick macOS-specific
MAGICK_CONFIGURE_PATH="$XDG_CONFIG_HOME/ImageMagick"
MAGICK_HOME="/opt/homebrew"               # Homebrew installation path (Apple Silicon)
# MAGICK_HOME="/usr/local"                # Homebrew installation path (Intel)
```

#### System Integration Tools
```bash
# macOS system integration
BROWSER="open"                            # macOS-specific browser command
TMPDIR="$HOME/Library/Caches/TemporaryItems"  # macOS secure temp directory

# macOS-specific utilities (no config needed but available)
# mas, dockutil, pngpaste, switchaudio-osx, osx-cpu-temp, m-cli
```

## Conditional Configuration Examples

### Programs Configuration (Darwin-Specific)

#### Example: macOS-Specific Program Configuration
```nix
# Title         : darwin-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/darwin-tools.nix
# ----------------------------------------------------------------------------
# macOS-specific tool configurations using home-manager programs

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  # --- 1Password CLI Configuration ------------------------------------------
  programs._1password-cli = {
    enable = true;
    # Note: 1Password CLI doesn't have a home-manager module yet
    # Configuration handled via environment variables and config files
  };

  # --- macOS-Specific Aliases -----------------------------------------------
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    # Mac App Store management
    "mas-search" = "mas search";
    "mas-install" = "mas install";
    "mas-list" = "mas list";
    "mas-outdated" = "mas outdated";
    "mas-upgrade" = "mas upgrade";
    
    # Dock management
    "dock-add" = "dockutil --add";
    "dock-remove" = "dockutil --remove";
    "dock-list" = "dockutil --list";
    "dock-reset" = "dockutil --remove all && dockutil --add /Applications/Safari.app";
    
    # Clipboard utilities
    "png-paste" = "pngpaste";
    "png-copy" = "pngpaste -";
    
    # Audio switching
    "audio-list" = "SwitchAudioSource -a";
    "audio-current" = "SwitchAudioSource -c";
    "audio-switch" = "SwitchAudioSource -s";
    
    # System monitoring
    "cpu-temp" = "osx-cpu-temp";
    "system-info" = "m info";
    "system-update" = "m update";
  };

  # --- macOS-Specific Environment Variables ---------------------------------
  home.sessionVariables = {
    # 1Password CLI
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    
    # macOS system integration
    BROWSER = "open";
    TMPDIR = "${config.home.homeDirectory}/Library/Caches/TemporaryItems";
    
    # Media tools (macOS-specific features)
    FFMPEG_AVFOUNDATION_ENABLED = "1";
    FFMPEG_VIDEOTOOLBOX_ENABLED = "1";
  };
}
```

### Static Configuration Files (Darwin-Specific)

#### 1Password CLI Configuration
```json
# Title         : config.json
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/00.core/configs/apps/1password-config.json
# ----------------------------------------------------------------------------
# 1Password CLI configuration for macOS integration

{
  "version": "1.0",
  "accounts": [
    {
      "shorthand": "personal",
      "url": "https://my.1password.com",
      "email": "user@example.com"
    }
  ],
  "biometric_unlock": true,
  "auto_update": true,
  "telemetry": false,
  "format": "json",
  "cache": {
    "enabled": true,
    "ttl": 3600
  },
  "security": {
    "require_touch_id": true,
    "session_timeout": 3600
  }
}
```

#### duti Configuration (Default Applications)
```bash
# Title         : duti-settings
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/00.core/configs/apps/duti-settings
# ----------------------------------------------------------------------------
# macOS default application settings using duti

# Text files
com.microsoft.VSCode public.plain-text all
com.microsoft.VSCode public.unix-executable all
com.microsoft.VSCode public.shell-script all

# Source code files
com.microsoft.VSCode public.source-code all
com.microsoft.VSCode public.c-source all
com.microsoft.VSCode public.c-plus-plus-source all
com.microsoft.VSCode public.objective-c-source all
com.microsoft.VSCode public.python-script all
com.microsoft.VSCode public.ruby-script all
com.microsoft.VSCode public.perl-script all

# Configuration files
com.microsoft.VSCode public.json all
com.microsoft.VSCode public.xml all
com.microsoft.VSCode public.yaml all
com.microsoft.VSCode org.yaml.yaml all

# Web files
com.microsoft.VSCode public.html all
com.microsoft.VSCode public.css all
com.microsoft.VSCode com.netscape.javascript-source all

# Archive files (use The Unarchiver if available)
# cx.c3.theunarchiver public.zip-archive all
# cx.c3.theunarchiver public.tar-archive all
# cx.c3.theunarchiver org.gnu.gnu-zip-archive all

# Media files (use default macOS apps)
com.apple.QuickTimePlayerX public.movie all
com.apple.Preview public.image all
com.apple.Preview com.adobe.pdf all
```

#### ImageMagick Policy (macOS-Specific)
```xml
<!-- Title         : policy.xml -->
<!-- Author        : Bardia Samiee -->
<!-- Project       : Parametric Forge -->
<!-- License       : MIT -->
<!-- Path          : 01.home/00.core/configs/apps/imagemagick-policy.xml -->
<!-- -------------------------------------------------------------------------- -->
<!-- ImageMagick security policy for macOS -->

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policymap [
<!ELEMENT policymap (policy)+>
<!ELEMENT policy (#PCDATA)>
<!ATTLIST policy domain (delegate|coder|filter|path|resource) #IMPLIED>
<!ATTLIST policy name CDATA #IMPLIED>
<!ATTLIST policy pattern CDATA #IMPLIED>
<!ATTLIST policy rights CDATA #IMPLIED>
<!ATTLIST policy stealth (True|False) #IMPLIED>
<!ATTLIST policy value CDATA #IMPLIED>
]>
<policymap>
  <!-- Resource limits (macOS-optimized) -->
  <policy domain="resource" name="temporary-path" value="/tmp"/>
  <policy domain="resource" name="memory" value="2GiB"/>
  <policy domain="resource" name="map" value="4GiB"/>
  <policy domain="resource" name="width" value="32KP"/>
  <policy domain="resource" name="height" value="32KP"/>
  <policy domain="resource" name="area" value="1GP"/>
  <policy domain="resource" name="disk" value="8GiB"/>
  <policy domain="resource" name="file" value="768"/>
  <policy domain="resource" name="thread" value="4"/>
  <policy domain="resource" name="throttle" value="0"/>
  <policy domain="resource" name="time" value="3600"/>
  
  <!-- macOS-specific coder policies -->
  <policy domain="coder" rights="read|write" pattern="PNG" />
  <policy domain="coder" rights="read|write" pattern="JPEG" />
  <policy domain="coder" rights="read|write" pattern="GIF" />
  <policy domain="coder" rights="read|write" pattern="WEBP" />
  <policy domain="coder" rights="read|write" pattern="TIFF" />
  <policy domain="coder" rights="read|write" pattern="BMP" />
  <policy domain="coder" rights="read|write" pattern="ICO" />
  <policy domain="coder" rights="read|write" pattern="ICNS" />  <!-- macOS icons -->
  
  <!-- Security restrictions -->
  <policy domain="coder" rights="none" pattern="PS" />
  <policy domain="coder" rights="none" pattern="EPS" />
  <policy domain="coder" rights="none" pattern="PDF" />
  <policy domain="coder" rights="none" pattern="XPS" />
  
  <!-- Path restrictions for security -->
  <policy domain="path" rights="none" pattern="@*"/>
</policymap>
```

### File Management Integration (Darwin-Specific)

#### Darwin-Specific File Deployment
```nix
# Addition to 01.home/file-management.nix for Darwin-specific files

# --- Darwin-Specific XDG Configuration Files ------------------------------
xdg.configFile = lib.mkIf pkgs.stdenv.isDarwin {
  # 1Password CLI configuration
  "op/config.json".source = ./00.core/configs/apps/1password-config.json;
  
  # ImageMagick configuration (macOS-specific policies)
  "ImageMagick/policy.xml".source = ./00.core/configs/apps/imagemagick-policy.xml;
  "ImageMagick/delegates.xml".source = ./00.core/configs/apps/imagemagick-delegates.xml;
  
  # Neovim macOS-specific configuration
  "nvim/lua/config/darwin.lua".source = ./00.core/configs/apps/nvim-darwin.lua;
};

# --- Darwin-Specific Home Files -------------------------------------------
home.file = lib.mkIf pkgs.stdenv.isDarwin {
  # duti configuration (must be in home directory for duti to find it)
  ".duti".source = ./00.core/configs/apps/duti-settings;
  
  # macOS-specific shell scripts
  ".local/bin/dock-setup".source = ./00.core/configs/apps/dock-setup.sh;
  ".local/bin/macos-defaults".source = ./00.core/configs/apps/macos-defaults.sh;
};
```

## Integration with Existing Darwin Configuration Patterns

### Current Darwin Configuration Structure

The existing system has a well-organized Darwin configuration structure:

```
00.system/darwin/          # System-level Darwin configuration
├── darwin.nix            # Core Darwin system configuration
├── homebrew.nix           # Homebrew package management
├── settings/              # macOS system settings
│   ├── input.nix         # Keyboard, mouse, trackpad settings
│   ├── interface.nix     # UI, dock, finder settings
│   ├── security.nix      # Security and privacy settings
│   └── system.nix        # General system settings
└── services/              # System-level services
    └── maintenance-daemon.nix

01.home/darwin/            # User-level Darwin configuration
├── default.nix           # Darwin-specific home-manager config
├── activation.nix        # User activation scripts
└── services/              # User-level launchd agents
    ├── exclusion-daemons.nix
    ├── op-daemons.nix
    ├── temp-daemon.nix
    └── xdg-daemons.nix
```

### Integration Patterns

#### 1. Platform Detection Integration
```nix
# Use existing platform detection from lib/detection.nix
{ lib, pkgs, context, ... }:

lib.mkIf context.isDarwin {
  # Darwin-specific configuration here
}

# Alternative using pkgs.stdenv
lib.mkIf pkgs.stdenv.isDarwin {
  # Darwin-specific configuration here
}
```

#### 2. Environment Variable Integration
```nix
# Add to 01.home/environment.nix in platform-specific section
home.sessionVariables = {
  # Existing platform-aware variables
  TMPDIR = if (context != null && context.isDarwin) 
    then "${config.home.homeDirectory}/Library/Caches/TemporaryItems" 
    else "/tmp";
  BROWSER = if (context != null && context.isDarwin) 
    then "open" 
    else "xdg-open";
    
  # New Darwin-specific variables
} // lib.optionalAttrs (context != null && context.isDarwin) {
  # macOS-specific environment variables
  OP_BIOMETRIC_UNLOCK_ENABLED = "true";
  FFMPEG_AVFOUNDATION_ENABLED = "1";
  FFMPEG_VIDEOTOOLBOX_ENABLED = "1";
};
```

#### 3. Service Integration Pattern
```nix
# Example: 1Password CLI service integration
# File: 01.home/darwin/services/op-cli-daemon.nix

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  launchd.agents.op-cli-daemon = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs._1password-cli}/bin/op"
        "signin"
        "--account"
        "personal"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "${config.xdg.stateHome}/op/daemon.log";
      StandardErrorPath = "${config.xdg.stateHome}/op/daemon.log";
      EnvironmentVariables = {
        OP_CONFIG_DIR = "${config.xdg.configHome}/op";
        OP_CACHE_DIR = "${config.xdg.cacheHome}/op";
        OP_DATA_DIR = "${config.xdg.dataHome}/op";
      };
    };
  };
}
```

#### 4. Package Integration Pattern
```nix
# Integration with existing package structure
# File: 01.home/01.packages/macos-tools.nix (already exists)

# Current structure is appropriate:
[
  mas                    # Mac App Store CLI
  _1password-cli        # 1Password CLI
  dockutil             # Dock management
  pngpaste             # Clipboard utilities
  duti                 # Default applications
  switchaudio-osx      # Audio switching
  osx-cpu-temp         # System monitoring
  m-cli                # macOS utilities
]
```

### Activation Script Integration

#### Darwin-Specific Activation Scripts
```nix
# Addition to 01.home/darwin/activation.nix

home.activation = lib.mkIf pkgs.stdenv.isDarwin {
  # Set up default applications using duti
  setupDefaultApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -f "$HOME/.duti" ]]; then
      echo "Setting up default applications..."
      ${pkgs.duti}/bin/duti "$HOME/.duti"
    fi
  '';
  
  # Configure dock using dockutil
  setupDock = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v dockutil >/dev/null 2>&1; then
      echo "Configuring macOS Dock..."
      # Remove all items first
      dockutil --remove all --no-restart
      
      # Add essential applications
      dockutil --add /Applications/Safari.app --no-restart
      dockutil --add /Applications/Visual\ Studio\ Code.app --no-restart
      dockutil --add /Applications/WezTerm.app --no-restart
      
      # Restart Dock to apply changes
      killall Dock
    fi
  '';
  
  # Set up 1Password CLI
  setup1PasswordCLI = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v op >/dev/null 2>&1; then
      echo "Setting up 1Password CLI..."
      # Create necessary directories
      mkdir -p "${config.xdg.configHome}/op"
      mkdir -p "${config.xdg.cacheHome}/op"
      mkdir -p "${config.xdg.dataHome}/op"
      
      # Set up biometric unlock if not already configured
      if ! op account list >/dev/null 2>&1; then
        echo "Please run 'op account add' to set up your 1Password account"
      fi
    fi
  '';
};
```

## Implementation Recommendations

### High Priority Darwin-Specific Configurations

1. **1Password CLI** - Essential for password management and SSH key integration
   - Config file: `~/.config/op/config.json`
   - Environment variables for XDG compliance
   - Biometric unlock configuration

2. **duti** - Default application management for development workflow
   - Config file: `~/.duti`
   - Set VS Code as default for source files
   - Configure appropriate media handlers

3. **Neovim** - Primary text editor with macOS-specific features
   - macOS-specific configuration in `~/.config/nvim/lua/config/darwin.lua`
   - Clipboard integration
   - Terminal integration

### Medium Priority Darwin-Specific Configurations

1. **ImageMagick** - Image processing with macOS-specific security policies
   - Policy configuration for security
   - macOS-specific delegate configuration
   - ICNS format support for macOS icons

2. **FFmpeg** - Media processing with macOS hardware acceleration
   - AVFoundation support configuration
   - VideoToolbox hardware acceleration
   - macOS-specific codec paths

### Low Priority Darwin-Specific Configurations

1. **System Utilities** - Aliases and convenience functions
   - mas aliases for App Store management
   - dockutil aliases for dock management
   - System monitoring aliases

2. **Dock Setup Scripts** - Automated dock configuration
   - Remove default applications
   - Add development-focused applications
   - Configure dock preferences

### Integration Testing Strategy

1. **Platform Detection Testing**
   - Verify configurations only apply on Darwin systems
   - Test conditional logic with different system types
   - Validate environment variable platform detection

2. **XDG Compliance Testing**
   - Verify tools respect XDG environment variables
   - Test file placement in correct XDG directories
   - Validate fallback behavior for non-XDG tools

3. **Service Integration Testing**
   - Test launchd agent configuration
   - Verify service startup and logging
   - Test environment variable propagation to services

4. **Activation Script Testing**
   - Test activation script execution order
   - Verify error handling in activation scripts
   - Test idempotent activation behavior

## Security Considerations

### 1Password CLI Security
- Biometric unlock configuration
- Session timeout settings
- Secure storage of configuration files
- Environment variable security

### Default Application Security
- Restrict file type associations to trusted applications
- Avoid automatic execution of potentially dangerous file types
- Regular review of default application settings

### ImageMagick Security
- Restrictive security policies
- Disable potentially dangerous coders (PS, EPS, PDF)
- Resource limits to prevent DoS attacks
- Path restrictions for file access

### System Integration Security
- Validate activation script permissions
- Secure temporary file handling
- Environment variable sanitization
- Service configuration security

## Maintenance and Updates

### Regular Maintenance Tasks
1. Update 1Password CLI configuration for new features
2. Review and update default application associations
3. Update ImageMagick policies for new security requirements
4. Review and update dock configuration for new applications

### Version Compatibility
1. Monitor 1Password CLI API changes
2. Track macOS system setting changes across versions
3. Update ImageMagick policies for new versions
4. Maintain compatibility with home-manager updates

### Documentation Updates
1. Document new macOS-specific tools as they're added
2. Update configuration examples for tool updates
3. Maintain integration pattern documentation
4. Update security recommendations as needed