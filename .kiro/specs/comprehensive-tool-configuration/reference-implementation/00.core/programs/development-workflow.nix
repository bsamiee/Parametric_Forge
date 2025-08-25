# Title         : development-workflow.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/development-workflow.nix
# ----------------------------------------------------------------------------
# Development workflow tools: just (command runner), pre-commit (git hooks),
# hyperfine (benchmarking), and tokei (code statistics). These tools streamline
# development processes with task automation, code quality gates, performance
# measurement, and project analysis.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Just Command Runner -------------------------------------------
    # Modern task runner and command organizer for project automation
    # Replaces Makefiles with a more intuitive syntax for development tasks
    # TODO: No home-manager module available - requires manual configuration
    
    # just = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   # Default justfile location and behavior
    #   settings = {
    #     # Shell to use for recipe execution
    #     shell = [ "bash" "-c" ];
    #     
    #     # --- Chooser Integration ---------------------------------
    #     # Program to use for interactive recipe selection
    #     chooser = "fzf";
    #     
    #     # --- Output Configuration --------------------------------
    #     # Suppress dotenv load warnings
    #     suppress_dotenv_load_warning = true;
    #     
    #     # Enable unstable features
    #     unstable = false;
    #   };
    #   
    #   # --- Shell Integration ------------------------------------
    #   enableBashIntegration = true;
    #   enableZshIntegration = true;
    #   enableFishIntegration = true;
    # };

    # --- Pre-commit Git Hook Framework --------------------------------
    # Automated code quality checks and formatting before commits
    # Integrates with multiple linters, formatters, and security tools
    # TODO: No home-manager module available - requires manual setup
    
    # pre-commit = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # Default hooks for all repositories
    #     default_install_hook_types = [
    #       "pre-commit"
    #       "pre-merge-commit" 
    #       "pre-push"
    #       "prepare-commit-msg"
    #       "commit-msg"
    #       "post-checkout"
    #       "post-commit"
    #       "post-merge"
    #       "post-rewrite"
    #     ];
    #     
    #     # --- Performance Settings -------------------------------
    #     # Minimum pre-commit version
    #     minimum_pre_commit_version = "2.20.0";
    #     
    #     # --- Repository Configuration ---------------------------
    #     repos = [
    #       {
    #         repo = "https://github.com/pre-commit/pre-commit-hooks";
    #         rev = "v4.4.0";
    #         hooks = [
    #           { id = "trailing-whitespace"; }
    #           { id = "end-of-file-fixer"; }
    #           { id = "check-yaml"; }
    #           { id = "check-added-large-files"; }
    #           { id = "check-merge-conflict"; }
    #         ];
    #       }
    #     ];
    #   };
    #   
    #   # --- Integration Settings ----------------------------------
    #   # Automatic installation in git repositories
    #   installHooks = true;
    # };

    # --- Hyperfine Benchmarking Tool ----------------------------------
    # Command-line benchmarking tool for performance measurement
    # Provides statistical analysis of command execution times
    # Note: No configuration file needed - pure command-line tool
    
    # hyperfine = {
    #   enable = true;
    #   
    #   # --- Default Settings ------------------------------------
    #   # These would be applied as default command-line options
    #   defaultOptions = [
    #     "--warmup" "3"        # Number of warmup runs
    #     "--min-runs" "10"     # Minimum number of benchmark runs
    #     "--max-runs" "100"    # Maximum number of benchmark runs
    #     "--show-output"       # Show stdout/stderr of benchmarked commands
    #   ];
    #   
    #   # --- Export Configuration --------------------------------
    #   # Default export format for benchmark results
    #   defaultExportFormat = "json";
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create shell aliases for common benchmark patterns
    #   aliases = {
    #     "bench" = "hyperfine --warmup 3 --min-runs 10";
    #     "bench-json" = "hyperfine --export-json results.json";
    #     "bench-compare" = "hyperfine --parameter-scan";
    #   };
    # };

    # --- Tokei Code Statistics Tool -----------------------------------
    # Fast code statistics tool for analyzing project composition
    # Counts lines of code, comments, and blanks across multiple languages
    # TODO: No home-manager module available - requires config file
    
    # tokei = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- Display Options ---------------------------------
    #     # Output format (default, json, yaml)
    #     output = "default";
    #     
    #     # Sort output by (files, lines, code, comments, blanks)
    #     sort = "lines";
    #     
    #     # --- Language Configuration -------------------------
    #     # Treat unknown extensions as specific language
    #     treat_doc_strings_as_comments = true;
    #     
    #     # --- Exclusion Patterns -----------------------------
    #     # Files and directories to exclude from analysis
    #     exclude = [
    #       "target/"
    #       "node_modules/"
    #       ".git/"
    #       "*.min.js"
    #       "*.min.css"
    #       "dist/"
    #       "build/"
    #     ];
    #     
    #     # --- File Type Overrides ----------------------------
    #     # Custom language definitions for specific extensions
    #     types = {
    #       "Nix" = [ "*.nix" ];
    #       "Justfile" = [ "justfile" "Justfile" ".justfile" ];
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common usage patterns
    #   aliases = {
    #     "count" = "tokei";
    #     "count-json" = "tokei --output json";
    #     "count-compact" = "tokei --compact";
    #   };
    # };
  };

  # --- Environment Variables for Manual Configuration -------------------
  # These environment variables configure the tools until home-manager modules
  # are available. They should be moved to environment.nix in actual implementation.
  
  # Just configuration
  # JUST_CHOOSER = "fzf";
  # JUST_LOG_LEVEL = "warn";
  # JUST_SUPPRESS_DOTENV_LOAD_WARNING = "true";
  
  # Pre-commit configuration (XDG compliant)
  # PRE_COMMIT_HOME = "${config.xdg.cacheHome}/pre-commit";
  # PRE_COMMIT_COLOR = "auto";
  
  # Hyperfine configuration
  # HYPERFINE_EXPORT_FORMAT = "json";
  # SHELL = "${pkgs.bash}/bin/bash";  # Ensure consistent shell for benchmarks
  
  # Tokei configuration (XDG compliant)
  # TOKEI_CONFIG = "${config.xdg.configHome}/tokei/.tokeirc";
  
  # --- Integration Notes -----------------------------------------------
  # 1. Just requires justfile templates in configs/development/just/
  # 2. Pre-commit needs .pre-commit-config.yaml templates in configs/development/pre-commit/
  # 3. Tokei requires .tokeirc config file in configs/development/tokei/
  # 4. Hyperfine needs no config files - pure command-line tool
  # 5. All tools benefit from shell aliases for common usage patterns
  # 6. Package dependencies: just, pre-commit, hyperfine, tokei in packages/dev-tools.nix
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Create comprehensive justfile templates for common project types
  # 2. Set up pre-commit hook configurations for different language ecosystems
  # 3. Integrate tokei with git hooks for commit statistics
  # 4. Create hyperfine benchmark suites for common performance tests
  # 5. Add integration with CI/CD pipelines for automated quality gates
  # 6. Consider integration with other development tools (git, editors)
}