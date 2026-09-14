# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# mise runtime manager: installed binary, interactive-zsh activation, and a settings-only global config that never shadows a project's own
# `mise.toml`. Activation (`mise activate zsh`, a precmd/chpwd hook) is what makes a project's `[env]` and `[tools]` rows apply to the shell
# inside its tree, so a per-project variable such as PLAYWRIGHT_BROWSERS_PATH is owned by that project's `mise.toml`, never by a machine-wide
# export. The hook lives in .zshrc and reads the shell's directory once at activation and again at every prompt and directory change, so only
# an interactive shell inside a project gets its tools this way; the shim farm `toolchain-env.nix` puts last on every PATH vector is what a
# non-interactive login shell, a launchd agent, and a GUI app resolve a project's tools through, each shim reading its caller's directory. Both
# routes stay behind Nix: the farm's segment trails every Nix profile, and outside a trusted project the hook is a no-op over a tool-free global config.
# The global auto-install gate stays off so a missing tool is a typed failure, never a mid-command download; trust covers the estate roots so
# a project config composes freely while a foreign checkout's config never executes implicitly.
{pkgs, ...}: {
  programs.mise = {
    enable = true;
    package = pkgs.mise;
    # HM's integration has no order; zsh/init.nix evals `mise activate zsh` as the last interactive line, where mise documents it belongs.
    enableZshIntegration = false;
    globalConfig.settings = {
      trusted_config_paths = ["~/Developer"];
      # The global gate every install path checks: off, so no command ever starts a download. not_found_auto_install stays at its default
      # (true): activation keeps the shim farm in PATH only under it (src/cli/activate.rs remove_shims), and its handler installs nothing
      # while this gate is off.
      auto_install = false;
      exec_auto_install = false;
      disable_hints = ["*"]; # the wildcard every hint id matches (src/hint.rs)
    };
  };
}
