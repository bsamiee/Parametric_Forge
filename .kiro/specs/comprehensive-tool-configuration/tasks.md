# Implementation Plan

**Note**: All documentation and configuration examples will be created in a `docs/` folder within this spec directory. All configuration files created will be fully commented out examples, not active implementation files. Reference these documentation files in relevant tasks throughout the implementation process.

- [x] 1. Create comprehensive tool inventory and classification system

  - Extract all unique tools from package files across all categories
  - Create mental categorization map grouping tools by logical configuration patterns
  - Classify each tool's configuration requirements (programs/, configs/, both, none)
  - Document tool purposes and current configuration status in docs/tool-inventory.md
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Research and document tool configuration capabilities
- [x] 2.1 Research core development tools configuration requirements

  - Research git, gh, lazygit, gitui, git-secret, git-crypt, gitleaks configuration capabilities
  - Research just, hyperfine, jq, pre-commit configuration requirements
  - Research shellcheck, shfmt, bash-language-server, sqlfluff configuration options
  - Document environment variables, XDG support, file requirements in docs/dev-tools-research.md
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 2.2 Research shell enhancement tools configuration requirements

  - Research zoxide, starship, direnv, fzf, vivid, mcfly configuration capabilities
  - Research eza, bat, ripgrep, fd, broot configuration options
  - Research yazi, lf, ranger, nnn file manager configuration requirements
  - Document environment variables, XDG support, file requirements in docs/shell-tools-research.md
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 2.3 Research language ecosystem tools configuration requirements

  - Research Python tools: python313, pipx, poetry, ruff, uv, basedpyright configuration
  - Research Rust tools: rustup, bacon, cargo-\* tools configuration capabilities
  - Research Node.js tools: nodejs, pnpm, yarn, npm packages configuration options
  - Research Lua tools: luajit, luarocks, lua-language-server, stylua configuration
  - Document environment variables, XDG support, file requirements in docs/language-tools-research.md
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 2.4 Research container and DevOps tools configuration requirements

  - Research Docker ecosystem: docker-client, docker-compose, colima, podman configuration
  - Research container tools: dive, lazydocker, buildkit, hadolint configuration options
  - Research build tools: cmake, pkg-config configuration requirements
  - Research secret management: vault, pass, gopass configuration capabilities
  - Document environment variables, XDG support, file requirements in docs/devops-tools-research.md
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 2.5 Research system utilities and monitoring tools configuration requirements

  - Research system monitors: procs, bottom, duf, dust configuration options
  - Research network tools: xh, doggo, gping, mtr, bandwhich, iperf configuration
  - Research archive tools: ouch, compression utilities configuration capabilities
  - Research terminal utilities: hexyl, tokei, file configuration requirements
  - Document environment variables, XDG support, file requirements in docs/system-tools-research.md
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 2.6 Research Nix ecosystem tools configuration requirements

  - Research nix toolchain: nixVersions.latest, cachix, deploy-rs configuration
  - Research nix development: nix-output-monitor, nix-fast-build, nix-index configuration
  - Research nix quality: nil, deadnix, statix, nixfmt-rfc-style configuration options
  - Document environment variables, XDG support, file requirements in docs/nix-tools-research.md
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 2.7 Research macOS-specific and media tools configuration requirements

  - Research macOS tools: mas, \_1password-cli, dockutil, pngpaste, duti configuration
  - Research media tools: ffmpeg, imagemagick, yt-dlp, pandoc, graphviz configuration
  - Research sysadmin tools: parallel-full, watchexec, tldr, neovim configuration options
  - Document environment variables, XDG support, file requirements in docs/platform-media-tools-research.md
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 3. Create documentation templates and framework
- [x] 3.1 Create standardized program configuration templates

  - Design template structure for programs/\*.nix files with proper headers
  - Create grouping guidelines for related tools in single files
  - Establish commenting standards for fully commented configuration examples
  - Document integration patterns with existing home-manager configurations in docs/program-templates.md
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 3.2 Create standardized config file templates

  - Design template structure for configs/ static files with proper headers
  - Establish organization patterns within existing directory structure
  - Create commenting standards for fully commented static configuration files
  - Document file deployment patterns and requirements in docs/config-templates.md
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 3.3 Create environment variable documentation framework

  - Design systematic organization for environment.nix additions
  - Create validation framework for environment variable research
  - Establish documentation standards for XDG compliance patterns
  - Document environment variable categorization and sectioning in docs/environment-framework.md
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 3.4 Create file management documentation framework

  - Design systematic approach for file-management.nix additions
  - Create documentation patterns for file deployment requirements
  - Establish standards for documenting file location constraints
  - Document platform-specific file management patterns in docs/file-management-framework.md
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 4. Validate and verify documentation framework accuracy

  - [x] 4.1 Validate program configuration templates and examples
    - Research current home-manager module options and syntax for all referenced tools
    - Verify all configuration examples use correct and current option names
    - Validate XDG integration patterns against current home-manager implementation
    - Check all referenced environment variables exist and function correctly
    - Ensure all example configurations follow current best practices
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_
  - [x] 4.2 Validate static configuration file templates and formats
    - Research current configuration file formats and syntax for all referenced tools
    - Verify all TOML, YAML, and JSON examples use correct syntax and valid options
    - Validate all configuration paths and directory structures are accurate
    - Check all referenced file deployment patterns work with current home-manager
    - Ensure all example configurations represent current tool capabilities
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [x] 4.3 Validate environment variable framework and XDG compliance
    - Research current XDG Base Directory specification and implementation
    - Verify all referenced environment variables exist in current tool versions
    - Validate XDG directory usage patterns against specification
    - Check all environment variable examples for accuracy and effectiveness
    - Ensure all XDG compliance claims are factually correct
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  - [x] 4.4 Validate file management framework and deployment patterns
    - Research current file deployment capabilities in home-manager
    - Verify all file deployment patterns work with current home-manager version
    - Validate all referenced file paths and locations are accurate
    - Check all platform-specific deployment examples for correctness
    - Ensure all integration patterns function as documented
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 5. Consolidate validation results into framework documentation

  - Merge validation findings from all validation reports into original framework documents
  - Update program templates with validated syntax and current best practices
  - Correct static configuration templates based on validation results
  - Update environment framework with validated variables and XDG compliance status
  - Enhance file management framework with confirmed deployment patterns
  - Create single source of truth documentation with all corrections applied
  - Remove redundant validation-only documents after consolidation
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 6. Document missing configurations and create implementation guidance
- [x] 6.1 Identify and document configuration gaps

  - Compare tool inventory against existing configurations
  - Identify tools with no configuration coverage
  - Document tools with partial or incomplete configurations
  - Prioritize configuration gaps by tool importance and usage in docs/configuration-gaps.md
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 6.2 Create commented program configuration examples

  - Create fully commented examples for high-priority tools needing programs/ configs in docs/program-examples/
  - Group related tools into logical program files following established patterns
  - Document integration requirements with existing configurations
  - Provide implementation guidance for each configuration example (reference docs/program-templates.md)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 6.3 Create commented static configuration file examples

  - Create fully commented examples for tools requiring configs/ files in docs/config-examples/
  - Organize files within existing directory structure appropriately
  - Document file deployment requirements and constraints
  - Provide implementation guidance for each static configuration (reference docs/config-templates.md)
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 6.4 Document environment variable additions

  - Create fully commented environment variable additions in docs/environment-additions.md
  - Organize additions within existing sectioning structure
  - Document XDG compliance improvements and limitations
  - Provide validation guidance for environment variable effectiveness (reference docs/environment-framework.md)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 6.5 Document file management additions

  - Create fully commented file management additions in docs/file-management-additions.md
  - Document file deployment patterns and location requirements
  - Identify platform-specific file management needs
  - Provide implementation guidance for file deployment (reference docs/file-management-framework.md)
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 7. Create platform-specific configuration documentation
- [x] 7.1 Document macOS-specific configuration requirements

  - Identify tools requiring Darwin-specific configuration handling
  - Document macOS-specific file paths and environment variables
  - Create fully commented conditional configuration examples for macOS tools
  - Document integration with existing Darwin configuration patterns in implementation-docs/platform-specific/darwin-specific.md
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 7.2 Document Linux/NixOS-specific configuration requirements

  - Identify tools requiring Linux-specific configuration handling
  - Document Linux-specific file paths and environment variables
  - Create fully commented conditional configuration examples for Linux tools
  - Document integration with existing NixOS configuration patterns in implementation-docs/platform-specific/nixos-specific.md
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 8. Create comprehensive implementation documentation
- [x] 8.1 Document implementation phases and priorities

  - Create detailed implementation roadmap based on tool priorities in implementation-docs/integration-guides/implementation-roadmap.md
  - Document dependencies between different configuration components
  - Establish implementation order for minimal system disruption
  - Create rollback and validation procedures for each phase
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 8.2 Create maintenance and update documentation

  - Document procedures for adding new tools to the configuration system
  - Create guidelines for maintaining configuration consistency
  - Document update procedures for tool configuration changes
  - Establish monitoring procedures for configuration effectiveness in implementation-docs/integration-guides/maintenance-guide.md
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 9. Create reference implementation structure
- [x] 9.1 Create reference home configuration directory structure

  - Create reference-implementation/ directory with complete 00.core/ structure
  - Set up programs/, configs/, and supporting directories following actual system patterns
  - Create default.nix files for proper module imports and organization
  - Document directory structure and organization principles
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 9.2 Create reference environment.nix with comprehensive tool variables

  - Create reference-implementation/environment.nix with all researched environment variables
  - Organize variables following the validated environment framework structure
  - Include comprehensive validation comments and XDG compliance documentation
  - Reference docs/environment-framework.md and docs/environment-additions.md for guidance
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 9.3 Create reference file-management.nix with all static config deployments

  - Create reference-implementation/file-management.nix with all config file deployments
  - Include all static configuration files identified in research phases
  - Document file deployment patterns and platform-specific requirements
  - Reference docs/file-management-framework.md and docs/file-management-additions.md for guidance
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 10. Create comprehensive programs/ reference implementation
- [x] 10.1 Create Phase 1 high-priority program configurations

  - Create programs/essential-tools.nix with broot, mcfly configurations
  - Create programs/development-workflow.nix with just, pre-commit, hyperfine, tokei configurations
  - Create programs/shell-enhancements.nix with vivid configuration
  - Create programs/file-operations.nix with rsync, ouch configurations
  - Follow docs/program-templates.md standards and include comprehensive comments
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 10.2 Create Phase 2 system and network program configurations

  - Create programs/system-monitoring.nix with procs, bottom configurations
  - Create programs/network-tools.nix with xh, doggo, gping configurations
  - Create programs/development-tools.nix with shfmt, sqlfluff, fx configurations
  - Create programs/file-managers.nix with yazi, lf configurations
  - Follow docs/program-templates.md standards and include comprehensive comments
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 10.3 Create Phase 3 specialized program configurations

  - Create programs/container-tools.nix with docker-client, colima configurations
  - Create programs/git-alternatives.nix with gitui configuration
  - Create programs/language-tools.nix with rustup, bacon configurations
  - Create programs/media-tools.nix with ffmpeg configuration
  - Create programs/advanced-editors.nix with neovim configuration
  - Follow docs/program-templates.md standards and include comprehensive comments
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 10.4 Create programs/default.nix with proper imports

  - Create comprehensive programs/default.nix importing all program configuration files
  - Follow existing import patterns and organization from actual system
  - Include proper module structure and conditional imports where needed
  - Document import organization and rationale
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 11. Create comprehensive configs/ reference implementation
- [x] 11.1 Create Phase 1 high-priority static configurations

  - Create configs/development/just/ with justfile templates and configuration
  - Create configs/development/jq/ with jq configuration and custom functions
  - Create configs/system/procs/ with procs configuration and themes
  - Create configs/system/bottom/ with bottom configuration and layouts
  - Create configs/shell/vivid/ with LS_COLORS themes and configuration
  - Create configs/file-ops/rsync/ with rsync configuration and exclusion patterns
  - Create configs/file-ops/ouch/ with ouch configuration and compression settings
  - Follow docs/config-templates.md standards and include comprehensive comments
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 11.2 Create Phase 2 system and network static configurations

  - Create configs/network/xh/ with HTTP client configuration and themes
  - Create configs/system/duf/ with disk usage display configuration
  - Create configs/system/dust/ with directory analysis configuration
  - Create configs/network/doggo/ with DNS client configuration
  - Create configs/network/gping/ with ping visualization configuration
  - Create configs/development/shfmt/ with shell formatting configuration
  - Create configs/development/sqlfluff/ with SQL linting configuration
  - Create configs/development/fx/ with JSON viewer configuration
  - Create configs/file-managers/yazi/ with file manager configuration and themes
  - Create configs/file-managers/lf/ with lightweight file manager configuration
  - Follow docs/config-templates.md standards and include comprehensive comments
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 11.3 Create Phase 3 specialized static configurations

  - Create configs/git/gitui/ with Git TUI configuration and themes
  - Create configs/containers/docker/ with Docker CLI configuration
  - Create configs/containers/colima/ with container runtime configuration
  - Create configs/security/vault/ with HashiCorp Vault configuration
  - Create configs/languages/rust/ with Rust toolchain configuration
  - Create configs/languages/bacon/ with Rust compiler configuration
  - Create configs/media/ffmpeg/ with multimedia processing configuration
  - Create configs/editors/neovim/ with comprehensive editor configuration
  - Follow docs/config-templates.md standards and include comprehensive comments
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 12. Create platform-specific reference implementations
- [x] 12.1 Create Darwin-specific configuration overrides

  - Create reference-implementation/darwin/ directory with macOS-specific overrides
  - Create Darwin-specific program configurations for macOS-only tools
  - Create Darwin-specific environment variables and file paths
  - Document macOS-specific integration patterns and requirements
  - Reference implementation-docs/platform-specific/darwin-specific.md for guidance
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 12.2 Create NixOS-specific configuration overrides

  - Create reference-implementation/nixos/ directory with Linux-specific overrides
  - Create NixOS-specific program configurations for Linux-only tools
  - Create Linux-specific environment variables and file paths
  - Document Linux-specific integration patterns and requirements
  - Reference implementation-docs/platform-specific/nixos-specific.md for guidance
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 13. Create comprehensive package reference files
- [x] 13.1 Create reference package files with all researched tools

  - Create reference-implementation/packages/ directory with complete package organization
  - Create packages/core.nix, packages/dev-tools.nix, packages/devops.nix following actual patterns
  - Include all tools researched in phases 2.1-2.7 with proper categorization
  - Document package organization principles and tool categorization rationale
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 13.2 Create reference package default.nix with proper imports

  - Create comprehensive packages/default.nix importing all package files
  - Follow existing import patterns and organization from actual system
  - Include proper conditional imports for platform-specific packages
  - Document package import organization and platform handling
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 14. Validate and test reference implementation
- [x] 14.1 Validate reference implementation structure and syntax

  - Verify all Nix files have correct syntax and can be parsed
  - Check all import paths and module references are correct
  - Validate all configuration examples follow established patterns
  - Ensure all file headers and comments follow formatting standards
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 14.2 Create implementation deployment guide

  - Create reference-implementation/README.md with deployment instructions
  - Document how to integrate reference implementation with actual system
  - Provide step-by-step migration guide from reference to production
  - Include validation procedures and testing recommendations
  - Reference all relevant documentation and implementation guides
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ] 15. Create comprehensive reference documentation
- [ ] 15.1 Create reference implementation overview documentation

  - Create reference-implementation/OVERVIEW.md documenting complete structure
  - Document design decisions and organization principles
  - Explain relationship between reference implementation and actual system
  - Provide guidance for using reference implementation as template
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 15.2 Create tool configuration cross-reference guide

  - Create reference-implementation/TOOL-REFERENCE.md mapping all tools to configurations
  - Document which tools use programs/, configs/, environment variables, or combinations
  - Provide quick reference for finding specific tool configurations
  - Include implementation status and priority information for each tool
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 15.3 Audit and clean reference implementation against actual project

  - Compare reference-implementation/ files with actual 01.home/ directory structure
  - Remove any packages, configurations, or environment variables that already exist in the actual project
  - Update file-management.nix to exclude file deployments that are already handled
  - Revise environment.nix to remove environment variables already defined in the actual system
  - Update packages/ files to remove tools that are already properly packaged in the actual system
  - Create audit report documenting what was removed and what remains as net-new additions
  - Ensure reference implementation only contains truly missing configurations and improvements
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 11.1, 11.2, 11.3, 11.4, 11.5_
