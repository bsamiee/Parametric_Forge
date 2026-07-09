# Title         : xh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/xh.nix
# ----------------------------------------------------------------------------
# Friendly and fast HTTP client (HTTPie reimplementation in Rust)
{pkgs, ...}: let
  jsonFormat = pkgs.formats.json {};

  # default_options is the ONLY key xh reads from config.json; named sessions
  # live under XH_CONFIG_DIR/sessions as user state (--session per invocation).
  xhConfig = {
    default_options = [
      "--style=fruity" # xh bundles four syntect themes only (auto/solarized/monokai/fruity); fruity is the closest dark match to the estate palette
      "--print=hbH" # Headers, body, request Headers
      "--follow" # Follow redirects by default
      "--timeout=30" # 30 second timeout
      "--check-status" # Exit with error on HTTP errors (4xx/5xx)
      "--pretty=all" # Pretty print with colors and formatting
      "--max-redirects=5" # Reasonable redirect limit
    ];
  };
in {
  home.packages = [pkgs.xh];
  xdg.configFile."xh/config.json".source = jsonFormat.generate "xh-config" xhConfig;
}
