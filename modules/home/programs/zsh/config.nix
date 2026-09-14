# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh .zshenv floor for every shell: the PATH assertion, the scientific library exports, and the never-clobber session-variable floor.
{
  config,
  forgeToolchainEnvFor,
  lib,
  ...
}: let
  toolchainEnv = forgeToolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
    xdgConfigHome = config.xdg.configHome;
    xdgDataHome = config.xdg.dataHome;
    xdgStateHome = config.xdg.stateHome;
  };
in {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts, zellij panes). PATH has ONE owner list, toolchain-env.nix pathEntries;
    # home.sessionPath projects it once per session and this file asserts it in every shell. NIX_* rows come from nix-darwin's /etc/zshenv
    # (set-environment, every shell), man pages resolve from PATH (macOS manpath maps /opt/homebrew/bin to /opt/homebrew/share/man).
    envExtra = ''
      setopt no_equals # bare =-leading words (===, =foo) pass through as literals in every shell; =(...) process substitution is unaffected
      setopt no_nomatch # unmatched globs pass through literally so the tool reports honestly, matching sh/bash expansion semantics

      # The owner segments, asserted present before any tool init: hm-session-vars lands home.sessionPath once per session behind its guard and
      # nix-darwin's set-environment behind its own, so a shell whose parent exported either guard with a different PATH would otherwise reach
      # .zshrc's tool init without the profile bins. Only the segments the inherited PATH lacks are prepended (array subtraction), so a child of
      # a mise-activated shell keeps the project's installs ahead of the profile bins in the order the parent's hook set. The unique flag takes
      # effect on assignment per interface of the tied pair, so both carry it: the array here and the scalar for hm-session-vars' later prepend,
      # which then adds no second copy of any segment.
      typeset -U PATH path
      _forge_path=(${lib.concatMapStringsSep " " lib.escapeShellArg toolchainEnv.sessionPathEntries})
      path=(''${_forge_path:|path} $path)
      unset _forge_path

      ${toolchainEnv.shellExports toolchainEnv.scientificSessionEnv}
      ${toolchainEnv.resilientFloorExports}
    '';
  };
}
