# Title         : development-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/development-tools.nix
# ----------------------------------------------------------------------------
# Development utility tools: shfmt (shell formatter), sqlfluff (SQL linter),
# and fx (JSON viewer). These tools enhance code quality and data inspection
# workflows with formatting, linting, and interactive data exploration.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Shfmt Shell Script Formatter ---------------------------------
    # Shell script formatter with consistent style enforcement
    # Integrates with editors and CI/CD pipelines for code quality
    # Note: No home-manager module - uses .editorconfig for configuration
    
    # shfmt = {
    #   enable = true;
    #   
    #   # --- Formatting Configuration ---------------------------
    #   # Default formatting options
    #   settings = {
    #     # --- Indentation Settings ---------------------------
    #     # Indentation style and size
    #     indent = 2;           # Number of spaces for indentation
    #     binary_next_line = false;  # Binary operators on next line
    #     switch_case_indent = false; # Indent case statements
    #     
    #     # --- Language Variant -------------------------------
    #     # Shell language variant to format
    #     language_variant = "bash";  # bash, posix, mksh
    #     
    #     # --- Formatting Style ------------------------------- 
    #     # Code style preferences
    #     space_redirects = false;    # Space after redirect operators
    #     keep_padding = false;       # Keep column alignment padding
    #     function_next_line = false; # Function opening brace on next line
    #     
    #     # --- Simplification Options -------------------------
    #     # Code simplification features
    #     simplify = true;      # Simplify code where possible
    #     minify = false;       # Minify code (remove unnecessary whitespace)
    #   };
    #   
    #   # --- Editor Integration ---------------------------------
    #   # Integration with common editors
    #   editorConfig = {
    #     # Use .editorconfig for project-specific settings
    #     respect_editorconfig = true;
    #     
    #     # Default .editorconfig settings for shell files
    #     shell_config = {
    #       indent_style = "space";
    #       indent_size = 2;
    #       end_of_line = "lf";
    #       charset = "utf-8";
    #       trim_trailing_whitespace = true;
    #       insert_final_newline = true;
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     "fmt-sh" = "shfmt -w";
    #     "fmt-bash" = "shfmt -ln bash -w";
    #     "fmt-posix" = "shfmt -ln posix -w";
    #     "check-sh" = "shfmt -d";
    #     "lint-sh" = "shfmt -d -ln bash";
    #   };
    # };

    # --- SQLFluff SQL Linter and Formatter ----------------------------
    # Comprehensive SQL linter with support for multiple dialects
    # Provides code quality enforcement and style consistency for SQL
    # TODO: No home-manager module available - requires config file
    
    # sqlfluff = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- Dialect Configuration ---------------------------
    #     # SQL dialect to use for parsing and linting
    #     dialect = "postgres";  # postgres, mysql, sqlite, bigquery, etc.
    #     
    #     # --- Templating Configuration -----------------------
    #     # Template engine for dynamic SQL
    #     templater = "jinja";   # jinja, python, placeholder
    #     
    #     # --- Linting Rules -----------------------------------
    #     # Rule configuration for code quality
    #     rules = {
    #       # Capitalization rules
    #       "capitalisation.keywords" = "upper";
    #       "capitalisation.identifiers" = "lower";
    #       "capitalisation.functions" = "upper";
    #       "capitalisation.literals" = "upper";
    #       
    #       # Layout rules
    #       "layout.indent" = 4;
    #       "layout.line_length" = 120;
    #       "layout.trailing_whitespace" = "remove";
    #       
    #       # Structure rules
    #       "structure.subquery" = "consistent";
    #       "structure.join_condition_order" = "consistent";
    #       "structure.column_order" = "consistent";
    #     };
    #     
    #     # --- Exclusion Patterns -----------------------------
    #     # Files and patterns to exclude from linting
    #     exclude_rules = [
    #       "L003"  # Indentation not consistent with previous lines
    #       "L011"  # Implicit aliasing of table not allowed
    #       "L013"  # Column expression without alias
    #     ];
    #     
    #     # --- Formatting Configuration -----------------------
    #     # Code formatting preferences
    #     format = {
    #       # Indentation
    #       indent_unit = "space";
    #       tab_space_size = 4;
    #       
    #       # Line breaks
    #       max_line_length = 120;
    #       split_before_logical_operator = true;
    #       
    #       # Comma placement
    #       trailing_comma = "forbid";
    #       leading_comma = false;
    #       
    #       # Keyword formatting
    #       keyword_case = "upper";
    #       identifier_case = "lower";
    #       function_case = "upper";
    #     };
    #   };
    #   
    #   # --- Dialect Profiles -----------------------------------
    #   # Predefined configurations for different SQL dialects
    #   profiles = {
    #     postgres = {
    #       dialect = "postgres";
    #       rules = {
    #         "capitalisation.keywords" = "upper";
    #         "layout.indent" = 2;
    #       };
    #     };
    #     
    #     mysql = {
    #       dialect = "mysql";
    #       rules = {
    #         "capitalisation.keywords" = "upper";
    #         "layout.indent" = 4;
    #       };
    #     };
    #     
    #     sqlite = {
    #       dialect = "sqlite";
    #       rules = {
    #         "capitalisation.keywords" = "lower";
    #         "layout.indent" = 2;
    #       };
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     "sql-lint" = "sqlfluff lint";
    #     "sql-fix" = "sqlfluff fix";
    #     "sql-format" = "sqlfluff format";
    #     "sql-check" = "sqlfluff lint --diff";
    #     "sql-postgres" = "sqlfluff lint --dialect postgres";
    #     "sql-mysql" = "sqlfluff lint --dialect mysql";
    #   };
    # };

    # --- FX JSON Viewer and Processor -----------------------------
    # Interactive JSON viewer with syntax highlighting and navigation
    # Provides powerful JSON exploration and manipulation capabilities
    # Note: No configuration file support - pure command-line tool
    
    # fx = {
    #   enable = true;
    #   
    #   # --- Display Configuration ------------------------------
    #   # JSON display and formatting options
    #   display = {
    #     # Color scheme for JSON syntax highlighting
    #     theme = "auto";       # auto, dark, light, monokai, etc.
    #     
    #     # Indentation for pretty printing
    #     indent = 2;
    #     
    #     # Show line numbers
    #     line_numbers = false;
    #     
    #     # Collapse large arrays/objects
    #     collapse_threshold = 20;
    #     
    #     # Maximum depth to display
    #     max_depth = null;     # null = no limit
    #   };
    #   
    #   # --- Interactive Features ---------------------------
    #   # Interactive mode configuration
    #   interactive = {
    #     # Enable mouse support
    #     mouse = true;
    #     
    #     # Key bindings for navigation
    #     key_bindings = {
    #       quit = "q";
    #       expand = "e";
    #       collapse = "c";
    #       search = "/";
    #       next_match = "n";
    #       prev_match = "N";
    #       copy_path = "y";
    #       copy_value = "Y";
    #     };
    #     
    #     # Search configuration
    #     search = {
    #       case_sensitive = false;
    #       regex = false;
    #       highlight_matches = true;
    #     };
    #   };
    #   
    #   # --- Processing Options -----------------------------
    #   # JSON processing and transformation
    #   processing = {
    #     # Default processing language
    #     language = "javascript"; # javascript, python
    #     
    #     # Predefined transformations
    #     transforms = {
    #       keys = "Object.keys(this)";
    #       values = "Object.values(this)";
    #       length = "this.length || Object.keys(this).length";
    #       flatten = "JSON.stringify(this, null, 0)";
    #       pretty = "JSON.stringify(this, null, 2)";
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     "json" = "fx";
    #     "jq-alt" = "fx";      # Alternative to jq
    #     "json-pretty" = "fx --pretty";
    #     "json-compact" = "fx --compact";
    #     "json-keys" = "fx 'Object.keys(this)'";
    #     "json-values" = "fx 'Object.values(this)'";
    #     "json-search" = "fx --interactive";
    #   };
    # };
  };

  # --- Environment Variables for Manual Configuration -------------------
  # These environment variables configure the tools until home-manager modules
  # are available. They should be moved to environment.nix in actual implementation.
  
  # SQLFluff configuration (XDG compliant)
  # SQLFLUFF_CONFIG = "${config.xdg.configHome}/sqlfluff/config";
  # SQLFLUFF_DIALECT = "postgres";
  # SQLFLUFF_TEMPLATER = "jinja";
  
  # FX configuration
  # FX_THEME = "auto";
  # FX_INDENT = "2";
  
  # Editor integration
  # EDITOR = "${pkgs.neovim}/bin/nvim";  # For tools that open editors
  
  # --- Integration Notes -----------------------------------------------
  # 1. Shfmt uses .editorconfig for project-specific formatting rules
  # 2. SQLFluff requires .sqlfluff config file in configs/development/sqlfluff/
  # 3. FX has no config files - pure command-line tool with runtime options
  # 4. All tools integrate well with editors and CI/CD pipelines
  # 5. Package dependencies: shfmt, sqlfluff, fx in packages/dev-tools.nix
  # 6. Consider integration with pre-commit hooks for automated formatting
  
  # --- Shell Aliases for Manual Configuration -------------------------
  # These aliases provide convenient shortcuts until programs modules are available
  
  # Shfmt aliases
  # alias fmt-sh='shfmt -w'
  # alias fmt-bash='shfmt -ln bash -w'
  # alias fmt-posix='shfmt -ln posix -w'
  # alias check-sh='shfmt -d'
  # alias lint-sh='shfmt -d -ln bash'
  
  # SQLFluff aliases
  # alias sql-lint='sqlfluff lint'
  # alias sql-fix='sqlfluff fix'
  # alias sql-format='sqlfluff format'
  # alias sql-check='sqlfluff lint --diff'
  # alias sql-postgres='sqlfluff lint --dialect postgres'
  # alias sql-mysql='sqlfluff lint --dialect mysql'
  
  # FX aliases
  # alias json='fx'
  # alias json-pretty='fx --pretty'
  # alias json-keys='fx "Object.keys(this)"'
  # alias json-values='fx "Object.values(this)"'
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Create comprehensive .editorconfig templates for different project types
  # 2. Set up SQLFluff configurations for different SQL dialects and projects
  # 3. Integrate with pre-commit hooks for automated code formatting
  # 4. Create wrapper scripts for common development workflows
  # 5. Add integration with editors (VS Code, Neovim, etc.)
  # 6. Consider integration with CI/CD pipelines for code quality gates
  # 7. Add support for custom formatting rules and style guides
  
  # --- Usage Examples ------------------------------------------------
  # Common usage patterns for these tools:
  
  # Shfmt examples:
  # shfmt -w script.sh                    # Format shell script in-place
  # shfmt -ln bash -w *.sh               # Format all bash scripts
  # shfmt -d script.sh                   # Show formatting diff
  # shfmt -ln posix script.sh            # Format as POSIX shell
  # find . -name "*.sh" -exec shfmt -w {} \;  # Format all shell scripts
  
  # SQLFluff examples:
  # sqlfluff lint query.sql               # Lint SQL file
  # sqlfluff fix query.sql                # Auto-fix SQL issues
  # sqlfluff format query.sql             # Format SQL file
  # sqlfluff lint --dialect postgres *.sql  # Lint with specific dialect
  # sqlfluff lint --config .sqlfluff     # Use custom config
  
  # FX examples:
  # cat data.json | fx                    # Interactive JSON viewer
  # fx data.json 'this.users'            # Extract users array
  # fx data.json 'Object.keys(this)'     # Get object keys
  # echo '{"a":1,"b":2}' | fx --pretty   # Pretty print JSON
  # fx data.json '.users[0].name'        # Extract specific value
}