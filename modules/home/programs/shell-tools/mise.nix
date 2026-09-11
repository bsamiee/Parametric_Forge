# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# mise runtime manager: installed binary, interactive-zsh activation, and a settings-only global config that never shadows a project's own
# `mise.toml`. Activation (`mise activate zsh`, a precmd/chpwd hook, never shims) is what makes a project's `[env]` and `[tools]` rows apply
# to the shell inside its tree, so a per-project variable such as PLAYWRIGHT_BROWSERS_PATH is owned by that project's `mise.toml`, never by
# a machine-wide export. Outside a trusted project the hook is a no-op: the global config carries no tools, so Nix keeps PATH truth there.
# Auto-install stays off in every form so a missing tool is a typed failure, never a mid-command download; trust covers the estate roots so
# a project config composes freely while a foreign checkout's config never executes implicitly.
{pkgs, ...}: {
  programs.mise = {
    enable = true;
    package = pkgs.mise;
    enableZshIntegration = true;
    globalConfig.settings = {
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
