# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# mise runtime manager: installed binary, interactive-zsh activation, and a tool-free global config that never shadows a project's own
# `mise.toml`. Activation (`mise activate zsh`, a precmd/chpwd hook) makes a project's `[env]` and `[tools]` rows apply to the shell inside its
# tree, so a per-project variable is owned by that project's `mise.toml`, never by a machine-wide export. Every process without the hook (a login
# shell, a launchd agent, a GUI app) resolves a project's tools through the shim segment `toolchain-env.nix` puts first on every PATH vector,
# each shim reading its caller's directory and passing through to the next copy on PATH where no version is set. The global auto-install gate
# stays off so a missing tool is a typed failure, never a mid-command download; trust covers the estate roots so a project config composes
# freely while a foreign checkout's config never executes implicitly.
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.mise = {
    enable = true;
    package = pkgs.mise;
    # HM's integration has no order; zsh/init.nix evals `mise activate zsh` as the last interactive line, where mise documents it belongs.
    enableZshIntegration = false;
    globalConfig = {
      settings = {
        trusted_config_paths = ["~/Developer"];
        # The global gate every install path checks: off, so no command ever starts a download. It also turns off exec_auto_install and
        # not_found_auto_install, so activation drops the shim segment from PATH; zsh/init.nix keeps activation out of VS Code's
        # environment resolution for that reason.
        auto_install = false;
        disable_hints = ["*"]; # the wildcard every hint id matches (src/hint.rs)
        # A shared-store SDK install overwrites the running `dotnet` host in place, and macOS then kills every process it hosts
        dotnet.isolated = true;
      };
      # Points the link /etc/dotnet/install_location_arm64 names (darwin/settings/system.nix) at the project's SDK, else the newest installed
      hooks.postinstall = ''
        if root="$(${lib.getExe config.programs.mise.package} where dotnet 2>/dev/null)"; then
          ln -sfn "$root" "${config.xdg.dataHome}/mise/dotnet-current"
        fi
      '';
    };
  };
}
