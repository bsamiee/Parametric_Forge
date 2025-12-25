# Title         : xh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/xh.nix
# ----------------------------------------------------------------------------
# Friendly and fast HTTP client (HTTPie reimplementation in Rust)
{
  config,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};

  xhConfig = {
    default_options = [
      "--style=fruity" # Dark theme (Dracula-adjacent)
      "--print=hbH" # Headers, body, request Headers
      "--follow" # Follow redirects by default
      "--timeout=30" # 30 second timeout
      "--check-status" # Exit with error on HTTP errors (4xx/5xx)
      "--pretty=all" # Pretty print with colors and formatting
      "--max-redirects=5" # Reasonable redirect limit
    ];

    # Session configuration for API testing workflows
    session = {
      default_dir = "${config.xdg.dataHome}/xh/sessions";
      auto_save = false; # Explicit session saving only
    };

    # Response handling
    response = {
      charset = "utf-8"; # Default charset for responses
      mime = {
        json = "application/json";
        xml = "application/xml";
        html = "text/html";
      };
    };
  };
in {
  home.packages = [pkgs.xh];

  # Main configuration
  xdg.configFile."xh/config.json".source = jsonFormat.generate "xh-config" xhConfig;

  # Session storage directory
  xdg.dataFile."xh/sessions/.keep".text = "";
}
