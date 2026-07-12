# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# mise runtime manager: installed binary plus a settings-only global config that never shadows a project's own `mise.toml`. Nix keeps PATH truth —
# no activation, no shims. Auto-install stays off in every form so a missing tool is a typed failure, never a mid-command download; trust covers
# the estate roots so a project config (tools, env, its own tasks) composes freely while a foreign checkout's config never executes implicitly.
{pkgs, ...}: let
  toml = pkgs.formats.toml {};
in {
  home.packages = [pkgs.mise];
  xdg.configFile."mise/config.toml".source = toml.generate "mise-config.toml" {
    settings = {
      trusted_config_paths = ["~/Documents/99.Github"];
      auto_install = false;
      not_found_auto_install = false;
      exec_auto_install = false;
      disable_hints = ["*"];
      status = {
        show_env = false;
        show_tools = false;
      };
    };
  };
}
