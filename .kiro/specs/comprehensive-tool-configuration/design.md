# Design Document

## Overview

This design addresses the systematic configuration management for 100+ tools in the Parametric Forge system. The solution provides a comprehensive framework for organizing tool configurations through a dual approach: declarative Nix-managed configurations (`programs/`) and static configuration files (`configs/`), with complete XDG Base Directory compliance and environment variable management.

The design follows the established patterns in the existing system while extending them to cover all tools systematically. It emphasizes research-driven configuration, proper categorization, and maintainable organization.

## Architecture

### Configuration Dual-Track System

The system uses two complementary approaches for tool configuration:

1. **Programs Track** (`01.home/00.core/programs/`): Declarative Nix-managed configurations using home-manager program modules
2. **Configs Track** (`01.home/00.core/configs/`): Static configuration files for tools requiring complex or large configuration files

### Integration Layer

Three integration components ensure proper deployment and environment setup:

1. **Environment Management** (`01.home/environment.nix`): Centralized environment variable definitions with XDG compliance
2. **File Management** (`01.home/file-management.nix`): Deployment of static configuration files to appropriate locations
3. **Package Integration** (`01.home/01.packages/`): Tool installation with configuration awareness

## Components and Interfaces

### Tool Research and Classification System

#### Tool Inventory Component
- **Purpose**: Maintain comprehensive inventory of all tools across package categories
- **Input**: Package definition files (`*.nix` in `01.packages/`)
- **Output**: Structured tool database with classification metadata
- **Interface**: Tool classification API for determining configuration requirements

#### Documentation Research Component
- **Purpose**: Research each tool's configuration capabilities and requirements
- **Process**: 
  1. Read official documentation for each tool
  2. Identify and validate all supported environment variables (verify they exist and are current)
  3. Determine path customization capabilities (distinguish between configurable vs hardcoded paths)
  4. Assess XDG Base Directory support (native vs environment variable redirection)
  5. Document all files the tool creates, reads, or manages
  6. Identify configuration file formats and locations (fixed vs configurable)
  7. Document configuration limitations and hardcoded behaviors
- **Output**: Tool configuration profiles with detailed capability matrix
- **Validation Requirements**: 
  - Verify environment variables exist in current tool versions
  - Test path configuration capabilities
  - Document which files cannot be relocated
  - Identify tools with hardcoded home directory requirements

### Configuration Generation System

#### Programs Configuration Generator
- **Purpose**: Create declarative Nix configurations for tools supporting home-manager integration
- **Input**: Tool configuration profiles, existing program patterns
- **Output**: Structured `programs/*.nix` files following established templates
- **Grouping Strategy**:
  - Related tools grouped logically (e.g., `container-tools.nix`, `python-tools.nix`)
  - Individual files for complex standalone tools
  - Maximum 300 LOC per file with modular organization
- **Organization Approach**: Minimize file proliferation by grouping related tools while maintaining clarity

#### Static Configuration Generator
- **Purpose**: Create and organize static configuration files for tools requiring them
- **Input**: Tool configuration profiles, tool-specific requirements
- **Output**: Organized configuration files in appropriate `configs/` subdirectories
- **Existing Directory Assessment**: Current structure is well-organized and should be preserved:
  ```
  configs/
  ├── apps/           # Application configurations (wezterm, starship) - KEEP
  ├── containers/     # Container runtime configs (docker, podman, colima) - KEEP
  ├── formatting/     # Code formatting tools (prettier, yamlfmt, taplo) - KEEP
  ├── git/           # Git-related configs (gitignore, gitattributes) - KEEP
  ├── languages/     # Language-specific tools (rust-analyzer, basedpyright) - KEEP
  └── [root files]   # Package manager configs (npmrc, poetry.toml) - KEEP
  ```
- **New Directory Considerations**: Only add new directories if absolutely necessary to prevent file proliferation
- **Potential Additions** (only if significant tool volume justifies):
  - `shells/` - Shell-specific configs (if substantial shell tool configs emerge)
  - `security/` - Security tool configs (if gpg, pass, vault configs become substantial)

### Environment and File Management System

#### XDG Compliance Manager
- **Purpose**: Ensure all tools respect XDG Base Directory specifications
- **Strategy**:
  1. **Native XDG Support**: Configure tools that support XDG directories directly
  2. **Environment Variable Redirection**: Use validated env vars for tools supporting custom paths
  3. **Documented Limitations**: Clear documentation for tools with hardcoded paths (e.g., prettier requiring project-root configs)
- **Integration**: Updates `environment.nix` with appropriate XDG-compliant paths
- **Research Requirements**:
  - Identify all XDG-related environment variables each tool supports
  - Document which tools have hardcoded path requirements
  - Map tool file usage patterns (config, cache, data, state, runtime)
  - Validate environment variable effectiveness through testing

#### Environment Variable Manager
- **Purpose**: Centralized management of all tool-related environment variables
- **Organization**: Sectioned approach in `environment.nix`:
  - XDG Base Directory variables
  - Language-specific development paths
  - Performance and build settings
  - Privacy and telemetry opt-outs
  - Tool-specific configuration paths

#### File Deployment Manager
- **Purpose**: Deploy static configuration files to correct locations
- **Strategy**:
  - `xdg.configFile` for XDG-compliant tools
  - `home.file` for tools requiring home directory placement (document why)
  - `xdg.dataFile` for platform-specific data files
- **Platform Awareness**: Conditional deployment based on Darwin/NixOS detection
- **File Analysis Requirements**:
  - Catalog all files each tool creates, reads, or manages
  - Identify which files can be relocated vs hardcoded locations
  - Document file purposes (config, cache, data, logs, state)
  - Map file interdependencies and requirements
  - Identify tools that create multiple file types in different locations

## Data Models

### Tool Configuration Profile

```nix
{
  name = "tool-name";
  category = "core" | "dev-tools" | "devops" | "python-tools" | "rust-tools" | "lua-tools" | "node-tools" | "nix-tools" | "sysadmin" | "media-tools" | "macos-tools";
  
  # Configuration method requirements
  needsPrograms = true | false;
  needsConfigs = true | false;
  
  # XDG and environment support
  xdgSupport = {
    native = true | false;           # Tool supports XDG natively
    envVarRedirect = true | false;   # Can be redirected via env vars
    limitations = "string";          # Documentation of limitations
  };
  
  # Environment variables (all validated as real/current)
  environmentVars = {
    required = [ "VAR_NAME" ];       # Required env vars (validated)
    optional = [ "VAR_NAME" ];       # Optional env vars for enhancement (validated)
    xdgPaths = [ "CONFIG_HOME" ];    # XDG paths the tool uses (tested)
    pathConfigurable = true | false; # Whether tool allows path customization
    hardcodedPaths = [ "path" ];     # Paths that cannot be changed
  };
  
  # File management requirements (comprehensive file analysis)
  fileManagement = {
    configFiles = [ "path/to/config" ];     # Static config files needed
    homeFiles = [ "path/to/home/file" ];    # Files that must be in home root (with reason)
    dataFiles = [ "path/to/data/file" ];    # Data files for XDG data directory
    cacheFiles = [ "path/to/cache" ];       # Cache files and directories
    stateFiles = [ "path/to/state" ];       # State/history files
    runtimeFiles = [ "path/to/runtime" ];   # Runtime files (sockets, pids)
    createdFiles = [ "path/created" ];      # Files the tool creates automatically
    readOnlyFiles = [ "path/readonly" ];    # Files the tool only reads
    relocatable = true | false;             # Whether file locations can be changed
    locationReason = "string";              # Why certain locations are required
  };
  
  # Platform specifics
  platforms = {
    darwin = true | false;
    linux = true | false;
    universal = true | false;
  };
  
  # Integration notes
  notes = "Special requirements or limitations";
}
```

### Configuration Template Structure

#### Programs Template
```nix
# Title         : tool-category.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/tool-category.nix
# ----------------------------------------------------------------------------
# Tool category description and purpose

{ config, lib, pkgs, ... }:

{
  programs = {
    # --- Primary Tool Configuration ----------------------------------------
    tool-name = {
      enable = true;
      # Tool-specific configuration following home-manager patterns
    };
    
    # --- Related Tools -----------------------------------------------------
    # Additional tools in the same category
  };
}
```

#### Config File Template
```toml
# Title         : tool-config.toml
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/00.core/configs/category/tool-config.toml
# ----------------------------------------------------------------------------
# Tool configuration description

# Configuration sections with clear organization
```

## Documentation and Foundation Strategy

### Documentation-Only Approach
- **Foundation Phase**: All work is documentation and research-focused
- **Commented Configurations**: All new files and additions will be fully commented out
- **No Active Changes**: No modifications to active system configurations
- **Research Documentation**: Comprehensive documentation of tool capabilities and requirements

### Documentation Standards
- **Comprehensive Comments**: All configuration examples fully commented with explanations
- **Research Notes**: Detailed research findings documented inline
- **Implementation Guidance**: Clear guidance for future implementation phases
- **Limitation Documentation**: Clear documentation of tool limitations and constraints

## Implementation Phases

### Phase 1: Research and Inventory (Foundation)
1. **Complete Tool Inventory**: Catalog all 100+ tools from package files
2. **Documentation Research**: Research each tool's configuration capabilities
3. **Classification System**: Categorize tools by configuration requirements
4. **Gap Analysis**: Identify tools lacking any configuration

### Phase 2: Documentation Framework (Foundation)
1. **Template System**: Create standardized documentation templates for programs and configs
2. **Environment Variable Documentation**: Document all environment variables with validation
3. **File Management Documentation**: Document all file management requirements comprehensively
4. **Configuration Examples**: Create fully commented configuration examples

### Phase 3: High-Priority Tool Documentation (Essential Tools)
1. **Development Tools**: Document essential development tools first
2. **Shell Enhancements**: Document shell tool configurations
3. **Language Ecosystems**: Document language-specific toolchains
4. **Container Tools**: Document container and DevOps tools

### Phase 4: Comprehensive Documentation Coverage (Complete System)
1. **Remaining Tools**: Document all remaining tools systematically
2. **Platform Documentation**: Document platform-specific requirements
3. **Integration Documentation**: Document tool integration patterns
4. **Implementation Guidance**: Complete implementation guidance documentation

## Documentation Quality Standards

### Documentation Standards
- **Comprehensive Research**: Every tool thoroughly researched and documented
- **Clear Organization**: All documentation follows established patterns and templates
- **Inline Documentation**: Every configuration example includes clear inline documentation
- **Implementation Readiness**: Documentation provides clear guidance for future implementation

### Documentation Process
- **Research Documentation**: All research findings documented with sources
- **Configuration Examples**: All examples fully commented and explained
- **Limitation Documentation**: Clear documentation of constraints and limitations
- **Implementation Guidance**: Step-by-step guidance for future implementation phases