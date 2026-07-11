# Title         : xh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/xh.nix
# ----------------------------------------------------------------------------
# HTTP client (HTTPie reimplementation in Rust)
{
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};

  # default_options is the ONLY key xh reads from config.json; named sessions live under XH_CONFIG_DIR/sessions as user state (--session per invocation).
  # Behavior rows only — presentation (--style/--print/--pretty) rides the interactive alias so piped output stays the upstream body-only stream.
  xhConfig = {
    default_options = [
      "--follow"
      "--timeout=30"
      "--check-status" # Exit with error on HTTP errors (4xx/5xx)
      "--max-redirects=5"
    ];
  };

  # Upstream reads any redirected stdin as a request body and flips GET to POST, so a bare call under /dev/null stdin — every agent shell —
  # mutates instead of reading, and an idle open stdin blocks forever. Null stdin drops the pseudo-body; pipes and files keep stdin-as-body.
  # Injection precedes "$@": xh tolerates a duplicate --ignore-stdin, and a caller --no-ignore-stdin lands later, so it wins.
  xhAgentSafe = pkgs.writeShellApplication {
    name = "xh";
    text = ''
      if [[ /dev/fd/0 -ef /dev/null ]]; then
        exec ${lib.getExe pkgs.xh} --ignore-stdin "$@"
      fi
      exec ${lib.getExe pkgs.xh} "$@"
    '';
  };
in {
  home.packages = [xhAgentSafe];
  xdg.configFile."xh/config.json".source = jsonFormat.generate "xh-config" xhConfig;
}
