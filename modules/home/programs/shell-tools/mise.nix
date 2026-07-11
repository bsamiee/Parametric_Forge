# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# mise owner: per-repo runtime and task contract, settings-only global config. Nix keeps PATH truth — no activation, no shims; agents discover
# tasks with `mise tasks --json` and execute with `mise run`. Auto-install stays off in every form: a missing tool is a typed failure, never a
# mid-command download. Trust covers the estate roots only, so a foreign checkout's config never executes implicitly.
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
      experimental = true; # monorepo task paths
      disable_hints = ["*"];
      status = {
        show_env = false;
        show_tools = false;
      };
    };
  };
}
