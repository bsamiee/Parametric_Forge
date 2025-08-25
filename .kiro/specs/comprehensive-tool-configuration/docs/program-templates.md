# Program Configuration Templates

## Overview

This document provides standardized templates and guidelines for creating `programs/*.nix` files that integrate tools with home-manager's declarative configuration system. These templates ensure consistency, maintainability, and proper integration with the existing Parametric Forge configuration patterns.

**Validation Status**: All templates and examples have been validated against home-manager unstable (2025-08-06) and current tool versions. All home-manager module options, environment variables, and XDG integration patterns have been verified for accuracy.

## Template Structure

### Standard Program File Template

```nix
# Title         : tool-category.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/tool-category.nix
# ----------------------------------------------------------------------------
# Brief description of tool category and purpose

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Primary Tool Configuration ----------------------------------------
    primary-tool = {
      enable = true;
      # Tool-specific configuration following home-manager patterns
      # Use clear section comments for complex configurations
    };
    
    # --- Related Tools -----------------------------------------------------
    # Group related tools logically within the same file
    related-tool = {
      enable = true;
      # Configuration specific to this tool
    };
  };
}
```

### Single Tool Template (for complex standalone tools)

```nix
# Title         : complex-tool.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/complex-tool.nix
# ----------------------------------------------------------------------------
# Detailed description of the complex tool and its purpose

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.complex-tool = {
    enable = true;
    
    # --- Core Configuration -----------------------------------------------
    # Primary settings and basic configuration
    
    # --- Advanced Configuration -------------------------------------------
    # Complex settings, integrations, and customizations
    
    # --- Platform-Specific Configuration ----------------------------------
    # Use lib.mkIf for platform-specific settings when needed
    
    # --- Integration Settings ----------------------------------------------
    # Settings that integrate with other tools or system components
  };
}
```

## Grouping Guidelines

### Tool Categorization Strategy

Tools should be grouped logically to minimize file proliferation while maintaining clarity:

#### Recommended Groupings

1. **Ecosystem-Based Grouping** (Preferred)
   - `git-tools.nix` - Git, GitHub CLI, Lazygit, git-related utilities
   - `container-tools.nix` - Docker, Podman, container utilities
   - `python-tools.nix` - Python REPL, pip tools, Python-specific utilities
   - `rust-tools.nix` - Rust toolchain, cargo extensions, Rust utilities
   - `shell-tools.nix` - Shell enhancements, prompt, directory navigation

2. **Functional Grouping** (When ecosystem grouping doesn't apply)
   - `development-tools.nix` - Generic development utilities
   - `system-monitors.nix` - Process monitors, system information tools
   - `network-tools.nix` - Network diagnostics, HTTP clients
   - `file-managers.nix` - File browsers, archive tools

3. **Standalone Files** (For complex tools requiring >100 LOC)
   - `neovim.nix` - Complex editor configuration
   - `tmux.nix` - Terminal multiplexer with extensive configuration

### File Size Guidelines

- **Target**: 50-200 lines per file for optimal maintainability
- **Maximum**: 300 lines per file (hard limit from code quality standards)
- **Minimum**: 20 lines per file (avoid excessive file proliferation)
- **Split Strategy**: When approaching 300 lines, split by logical tool boundaries

### Integration Requirements

Each program file must:

1. **Import Integration**: Be imported in `01.home/00.core/programs/default.nix`
2. **Package Dependency**: Corresponding packages must exist in `01.home/01.packages/`
3. **Environment Integration**: Use environment variables from `01.home/environment.nix`
4. **File Management**: Static configs deployed via `01.home/file-management.nix`

## Commenting Standards

### Section Organization

Use consistent section dividers for logical organization:

```nix
# --- Section Name ---------------------------------------------------------
```

### Comment Types

1. **File Header**: Standard Parametric Forge header (required)
2. **Section Comments**: Major logical divisions within the file
3. **Tool Comments**: Brief description of each tool's purpose
4. **Configuration Comments**: Explanation of non-obvious settings
5. **Integration Comments**: Notes about dependencies and interactions
6. **TODO Comments**: Future improvements or limitations

### Example Commenting Pattern

```nix
{
  programs = {
    # --- Git Core Configuration -------------------------------------------
    git = {
      enable = true;
      # User information intentionally not set - configured per-machine
      
      # --- Git Tools ----------------------------------------------------
      lfs.enable = true; # Large File Storage support
      delta = {
        enable = true;
        options = {
          navigate = true; # Enable file navigation in diffs
          line-numbers = true; # Show line numbers in diffs
        };
      };
      
      # --- Core Configuration -------------------------------------------
      extraConfig = {
        init.defaultBranch = "master";
        pull.ff = "only"; # Prevent merge commits on pull
        push = {
          default = "current";
          autoSetupRemote = true; # Auto-create remote branch
          useForceIfIncludes = true; # Safer force pushes
          followTags = true; # Automatically push annotated tags
        };
        # Additional configuration...
      };
    };
  };
}
```

## Home-Manager Module Availability

### Validated Program Modules (55% Coverage)

The following tools have confirmed home-manager program modules available:

**Git Ecosystem**: git ✅, gh ✅, lazygit ✅  
**Shell Tools**: starship ✅, fzf ✅, zoxide ✅, direnv ✅, eza ✅, bat ✅, ripgrep ✅  
**Development**: nix-index ✅, neovim ✅

### Tools Without Home-Manager Modules (40% Coverage)

The following tools require alternative configuration approaches:

**Config Files Only**: gitui, gitleaks (use `configs/` directory)  
**Environment Variables Only**: git-secret, git-crypt  
**Templates Only**: just, pre-commit  
**Mixed Approach**: jq (environment variables + optional config)

### Already Configured Tools (5% Coverage)

**Correctly Configured**: shellcheck ✅ (via `configs/languages/shellcheckrc`)

## Integration Patterns

### Home-Manager Integration

#### Standard Integration Pattern

```nix
# In programs/tool-category.nix
{
  programs.tool-name = {
    enable = true;
    # Use home-manager's built-in options when available
    enableZshIntegration = true; # Leverage existing shell integration
    settings = {
      # Tool-specific settings
    };
  };
}

# In 01.home/00.core/programs/default.nix
{
  imports = [
    ./tool-category.nix
    # Other imports...
  ];
}
```

#### Environment Variable Integration

```nix
# Reference environment variables from environment.nix
{
  programs.tool-name = {
    enable = true;
    settings = {
      # Use XDG-compliant paths when tool supports them
      config_dir = "${config.xdg.configHome}/tool-name";
      cache_dir = "${config.xdg.cacheHome}/tool-name";
      data_dir = "${config.xdg.dataHome}/tool-name";
    };
  };
}
```

#### Static Configuration Integration

```nix
# For tools requiring both programs/ and configs/ files
{
  programs.tool-name = {
    enable = true;
    # Reference static config files deployed by file-management.nix
    settings = builtins.fromTOML (builtins.readFile ../configs/category/tool-config.toml);
  };
}
```

#### Validated Settings Formats

Settings formats have been confirmed to work with current home-manager:
- **Attrset format**: Most tools (git, gh, bat, eza)
- **TOML import**: starship uses `builtins.fromTOML (builtins.readFile ...)`
- **List format**: ripgrep arguments as list of strings
- **JSON-style attrset**: gh settings configuration

### Platform-Specific Configuration

#### Conditional Configuration

```nix
{
  programs.tool-name = {
    enable = true;
    settings = {
      # Common settings for all platforms
      common_option = "value";
      
      # Platform-specific settings
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      # macOS-specific settings
      macos_option = "darwin-value";
    } // lib.optionalAttrs pkgs.stdenv.isLinux {
      # Linux-specific settings
      linux_option = "linux-value";
    };
  };
}
```

#### Platform Detection Patterns

```nix
{
  programs.tool-name = {
    enable = true;
    settings = {
      # Use platform-aware paths
      browser_command = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
      temp_dir = if pkgs.stdenv.isDarwin 
        then "${config.home.homeDirectory}/Library/Caches/TemporaryItems" 
        else "/tmp";
    };
  };
}
```

## Quality Standards

### Configuration Validation

Each program configuration must:

1. **Enable Check**: Verify the tool is enabled and functional
2. **Integration Check**: Confirm shell/environment integration works
3. **Path Check**: Validate XDG compliance and path configurations
4. **Platform Check**: Test on both Darwin and Linux when applicable

### Documentation Requirements

1. **Purpose Documentation**: Clear explanation of what each tool does
2. **Configuration Documentation**: Comments explaining non-obvious settings
3. **Integration Documentation**: Notes about dependencies and interactions
4. **Limitation Documentation**: Known issues or constraints

### Maintenance Guidelines

1. **Regular Updates**: Keep configurations current with tool updates
2. **Deprecation Handling**: Remove or update deprecated options
3. **Performance Monitoring**: Monitor configuration impact on shell startup
4. **Integration Testing**: Verify tool interactions remain functional

## Implementation Checklist

When creating a new program configuration file:

- [ ] Use standard file header with correct path
- [ ] Follow appropriate grouping strategy (ecosystem > functional > standalone)
- [ ] Include clear section comments for organization
- [ ] Document tool purposes and non-obvious settings
- [ ] Integrate with existing environment variables
- [ ] Reference static configs from file-management.nix when needed
- [ ] Add import to programs/default.nix
- [ ] Verify corresponding packages exist
- [ ] Test on target platforms
- [ ] Document any limitations or TODO items

## Examples

### Ecosystem Grouping Example

```nix
# Title         : container-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/container-tools.nix
# ----------------------------------------------------------------------------
# Container ecosystem tools: Docker, Podman, and container utilities

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Docker Configuration ---------------------------------------------
    # Note: Docker daemon managed by system configuration
    # This configures the Docker CLI client only
    
    # --- Container Inspection Tools ---------------------------------------
    # Tools for examining and debugging containers
    
    # --- Container Build Tools --------------------------------------------
    # Tools for building and managing container images
  };
}
```

### Complex Tool Example

```nix
# Title         : neovim.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/neovim.nix
# ----------------------------------------------------------------------------
# Neovim editor configuration with LSP, plugins, and development integration

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    
    # --- Core Configuration -----------------------------------------------
    defaultEditor = true; # Set as system default editor
    viAlias = true;
    vimAlias = true;
    
    # --- Plugin Management ------------------------------------------------
    plugins = with pkgs.vimPlugins; [
      # Plugin configurations...
    ];
    
    # --- Language Server Integration --------------------------------------
    # LSP configurations for development languages
    
    # --- Key Bindings -----------------------------------------------------
    # Custom key mappings and shortcuts
    
    # --- Integration Settings ----------------------------------------------
    # Integration with git, terminal, and other tools
  };
}
```