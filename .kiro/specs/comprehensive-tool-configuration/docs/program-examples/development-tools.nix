# Title         : development-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/development-tools.nix
# ----------------------------------------------------------------------------
# Development workflow tools that enhance productivity through automation,
# benchmarking, and code quality. This file provides programs/ configurations
# for tools that have home-manager module support or can be configured declaratively.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- JQ JSON Processor Configuration ----------------------------------
    # Powerful JSON processor and query tool for API development and data manipulation
    # Note: jq typically doesn't have extensive home-manager support
    # Configuration is primarily through environment variables and aliases
    
    # jq configuration is handled through:
    # 1. Environment variables in environment.nix
    # 2. Shell aliases for common operations
    # 3. Optional static config file for complex queries
    
    # --- Direnv Environment Management ------------------------------------
    # Already configured in shell-tools.nix, but showing integration example
    # direnv automatically loads .envrc files for project-specific environments
    
    # This is an example of how development tools integrate with existing configs
    # direnv = {
    #   enable = true; # Already enabled in shell-tools.nix
    #   
    #   # --- Integration with Development Workflows -------------------
    #   nix-direnv = {
    #     enable = true; # Enable nix-direnv for Nix project integration
    #   };
    #   
    #   # --- Configuration for Development Projects -------------------
    #   stdlib = ''
    #     # Custom direnv functions for development workflows
    #     
    #     # Function to load Python virtual environments
    #     layout_python_venv() {
    #       local python_version=$1
    #       local venv_name=$2
    #       
    #       if [[ -z $python_version ]]; then
    #         python_version="3.13"
    #       fi
    #       
    #       if [[ -z $venv_name ]]; then
    #         venv_name="venv"
    #       fi
    #       
    #       if [[ ! -d $venv_name ]]; then
    #         python$python_version -m venv $venv_name
    #       fi
    #       
    #       source $venv_name/bin/activate
    #     }
    #     
    #     # Function to load Node.js project dependencies
    #     layout_node() {
    #       if [[ -f package.json ]]; then
    #         if command -v pnpm >/dev/null 2>&1; then
    #           pnpm install
    #         elif command -v yarn >/dev/null 2>&1; then
    #           yarn install
    #         else
    #           npm install
    #         fi
    #       fi
    #     }
    #     
    #     # Function to load Rust project environment
    #     layout_rust() {
    #       if [[ -f Cargo.toml ]]; then
    #         export RUST_LOG=debug
    #         export RUST_BACKTRACE=1
    #       fi
    #     }
    #   '';
    # };
  };
  
  # --- Development Tool Environment Integration ----------------------------
  # These tools are primarily configured through environment variables
  # and static configuration files rather than home-manager programs
  
  # Environment variables for development tools (set in environment.nix):
  # 
  # JQ Configuration:
  # - JQ_COLORS: Custom color scheme for JSON output
  # - JQ_DEFAULT_OPTS: Default options for jq command
  # 
  # Hyperfine Configuration:
  # - HYPERFINE_DEFAULT_OPTS: Default benchmarking options
  # - HYPERFINE_EXPORT_FORMAT: Default export format (json, csv, markdown)
  # 
  # Just Configuration:
  # - JUST_CHOOSER: Command chooser for interactive recipe selection
  # - JUST_SUPPRESS_DOTENV_LOAD_WARNING: Suppress .env loading warnings
  # 
  # Pre-commit Configuration:
  # - PRE_COMMIT_HOME: Cache directory for pre-commit hooks
  # - PRE_COMMIT_COLOR: Enable colored output
  
  # --- Shell Integration and Aliases --------------------------------------
  # Development tools benefit from shell aliases and functions
  # These are typically defined in shell configuration files
  
  # Example aliases that would be defined in shell configuration:
  # 
  # JQ Aliases:
  # - jqp: jq with pretty-printing and colors
  # - jqr: jq with raw output (no quotes on strings)
  # - jqc: jq with compact output
  # 
  # Hyperfine Aliases:
  # - bench: hyperfine with common options
  # - benchjson: hyperfine with JSON export
  # - benchmd: hyperfine with Markdown export
  # 
  # Just Aliases:
  # - j: just (short alias)
  # - jl: just --list (list available recipes)
  # - jc: just --choose (interactive recipe selection)
  # 
  # Pre-commit Aliases:
  # - pc: pre-commit
  # - pci: pre-commit install
  # - pcr: pre-commit run --all-files
}

# Implementation Notes:
# 
# 1. Development Tool Configuration Strategy:
#    - Most development tools don't have extensive home-manager support
#    - Configuration is primarily through static files and environment variables
#    - Shell integration is crucial for productivity
# 
# 2. Static Configuration Files Needed:
#    - configs/development/just.toml - Just task runner configuration
#    - configs/development/hyperfine.toml - Benchmarking tool configuration
#    - configs/development/pre-commit-config.yaml - Pre-commit hook templates
#    - configs/development/jq-queries/ - Directory of common JQ queries
# 
# 3. Environment Variable Requirements:
#    - JQ_COLORS: Color scheme for JSON syntax highlighting
#    - HYPERFINE_DEFAULT_OPTS: Default options for consistent benchmarking
#    - JUST_CHOOSER: Interactive recipe selection (fzf integration)
#    - PRE_COMMIT_HOME: XDG-compliant cache directory
# 
# 4. Shell Integration Requirements:
#    - Aliases for common operations and shortened commands
#    - Functions for complex workflows and project setup
#    - Completion integration where available
#    - History integration for command recall
# 
# 5. Project Integration Patterns:
#    - .envrc files for direnv project-specific environments
#    - justfile templates for common project types
#    - .pre-commit-config.yaml templates for different languages
#    - JQ query libraries for common data transformations
# 
# 6. Performance Considerations:
#    - JQ can be slow on large JSON files - consider streaming mode
#    - Hyperfine needs sufficient runs for statistical significance
#    - Pre-commit hooks should be fast to avoid developer friction
#    - Just recipes should be optimized for common development tasks
# 
# 7. Integration with Other Tools:
#    - JQ integrates with curl, httpie (xh), and API development
#    - Hyperfine integrates with build systems and CI/CD
#    - Just integrates with all development tools as task orchestrator
#    - Pre-commit integrates with git workflow and code quality tools
# 
# 8. Platform Considerations:
#    - All tools work identically on macOS and Linux
#    - Path handling is consistent across platforms
#    - No platform-specific configuration needed
# 
# 9. Future Enhancements:
#    - TODO: Create JQ query library for common API operations
#    - TODO: Develop hyperfine templates for different benchmark types
#    - TODO: Create justfile templates for different project types
#    - TODO: Integrate pre-commit with existing code quality tools
# 
# 10. Documentation Requirements:
#     - Document common JQ patterns and queries
#     - Provide hyperfine benchmarking best practices
#     - Create just recipe examples for different workflows
#     - Document pre-commit hook configuration patterns