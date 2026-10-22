# Title         : xh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/xh.nix
# ----------------------------------------------------------------------------
# HTTP client (HTTPie reimplementation in Rust)
{pkgs, ...}: let
  jsonFormat = pkgs.formats.json {};

  # default_options is the ONLY key xh reads from config.json; named sessions live under XH_CONFIG_DIR/sessions as user state (--session per invocation).
  # Behavior rows only — the --style choice rides the interactive alias.
  xhConfig = {
    default_options = [
      "--follow"
      "--timeout=30"
      "--max-redirects=5"
    ];
  };
in {
  home.packages = [pkgs.xh];
  xdg.configFile."xh/config.json".source = jsonFormat.generate "xh-config" xhConfig;
}
