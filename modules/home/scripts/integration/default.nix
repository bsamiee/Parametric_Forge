# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/default.nix
# ----------------------------------------------------------------------------
# Yazi -> Zellij -> Neovim rail: popup dispatcher, RPC handoff, server owner.
# Pane targeting is ID-based via list-panes JSON; never ordinal focus.
{
  config,
  lib,
  pkgs,
  ...
}: let
  yaziPkg = config.programs.yazi.package;

  # Registry contract: one editor per tab, "<tab_id>\t<pane_id>\t<socket>" under
  # ${XDG_RUNTIME_DIR:-/tmp}/forge-edit/<session>/editor-tab-<tab_id>.tsv
  forgeNvim = pkgs.writeShellApplication {
    name = "forge-nvim.sh";
    runtimeInputs = [pkgs.neovim pkgs.zellij pkgs.jq];
    text = ''
      # Outside Zellij: plain editor. Inside: per-pane RPC server + tab registry.
      if [[ -z "''${ZELLIJ:-}" ]]; then
        exec nvim "$@"
      fi

      session="''${ZELLIJ_SESSION_NAME:-default}"
      pane_id="''${ZELLIJ_PANE_ID:-0}"
      runtime_root="''${XDG_RUNTIME_DIR:-/tmp}/forge-edit/''${session}"
      mkdir -p "$runtime_root"

      tab_id="$(zellij action list-panes --all --json \
        | jq -r --arg self "$pane_id" \
          '[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0].tab_id // 0')"

      socket="''${runtime_root}/tab-''${tab_id}-pane-''${pane_id}.sock"
      rm -f "$socket"
      printf '%s\t%s\t%s\n' "$tab_id" "$pane_id" "$socket" \
        >"''${runtime_root}/editor-tab-''${tab_id}.tsv"

      exec nvim --listen "$socket" "$@"
    '';
  };

  forgeEdit = pkgs.writeShellApplication {
    name = "forge-edit.sh";
    runtimeInputs = [pkgs.neovim pkgs.zellij pkgs.jq forgeNvim];
    text = ''
      # Yazi opener target: RPC into the tab's registered Neovim, else spawn one.
      if [[ $# -eq 0 ]]; then
        exit 0
      fi
      if [[ -z "''${ZELLIJ:-}" ]]; then
        exec nvim "$@"
      fi

      session="''${ZELLIJ_SESSION_NAME:-default}"
      caller="''${ZELLIJ_PANE_ID:-}"
      runtime_root="''${XDG_RUNTIME_DIR:-/tmp}/forge-edit/''${session}"
      panes="$(zellij action list-panes --all --json)"
      self_row="$(jq -r --arg self "$caller" \
        '[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0]' <<<"$panes")"
      tab_id="$(jq -r '.tab_id // 0' <<<"$self_row")"
      caller_floating="$(jq -r '.is_floating // false' <<<"$self_row")"

      editor_pane=""
      socket=""
      registry="''${runtime_root}/editor-tab-''${tab_id}.tsv"
      if [[ -r "$registry" ]]; then
        IFS=$'\t' read -r _ editor_pane socket <"$registry" || true
      fi

      if [[ -n "$socket" && -S "$socket" ]] \
        && nvim --server "$socket" --remote-expr '1' >/dev/null 2>&1; then
        nvim --server "$socket" --remote "$@"
      else
        editor_pane="$(zellij action new-pane --name " [EDITOR] " --cwd "$PWD" -- forge-nvim.sh "$@")"
      fi

      # Floating caller means the Yazi popup: dismiss it before focusing the editor
      if [[ "$caller_floating" == "true" ]]; then
        zellij action hide-floating-panes >/dev/null 2>&1 || true
      fi
      if [[ -n "$editor_pane" ]]; then
        zellij action focus-pane-id "terminal_''${editor_pane#terminal_}" >/dev/null 2>&1 || true
      fi
    '';
  };

  forgeYazi = pkgs.writeShellApplication {
    name = "forge-yazi.sh";
    runtimeInputs = [yaziPkg pkgs.zellij pkgs.jq forgeEdit];
    text = ''
      # Polymorphic entry: "toggle" dispatches the per-tab popup; any other argv
      # launches Yazi with the Forge editor handoff.
      if [[ "''${1:-}" != "toggle" ]]; then
        EDITOR="forge-edit.sh" exec yazi "''${1:-$PWD}"
      fi

      if [[ -z "''${ZELLIJ:-}" ]]; then
        echo "forge-yazi.sh toggle requires a Zellij session" >&2
        exit 1
      fi

      self="''${ZELLIJ_PANE_ID:-}"
      panes="$(zellij action list-panes --all --json)"
      tab_id="$(jq -r --arg self "$self" \
        '[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0].tab_id // 0' <<<"$panes")"
      popup="$(jq -r --arg self "$self" --argjson tab "$tab_id" \
        '[.[] | select((.is_plugin | not) and (.exited | not) and (.tab_id == $tab)
          and ((.id | tostring) != $self)
          and ((.terminal_command // "") | test("forge-yazi"))
          and (((.terminal_command // "") | test("toggle")) | not))][0].id // empty' <<<"$panes")"

      if [[ -z "$popup" ]]; then
        zellij action new-pane --floating --pinned true \
          -x "8%" -y "6%" --width "84%" --height "86%" \
          --name " [YAZI] " --close-on-exit --cwd "$PWD" -- forge-yazi.sh
      elif zellij action are-floating-panes-visible >/dev/null 2>&1; then
        zellij action hide-floating-panes
      else
        zellij action show-floating-panes
        zellij action focus-pane-id "terminal_''${popup}"
      fi
    '';
  };

  fzfDefaultOpts = lib.concatStringsSep " " (config.programs.fzf.defaultOptions or []);
  fzfDefaultCommand = config.programs.fzf.defaultCommand or "";

  yaziZoxideCdi = pkgs.writeShellApplication {
    name = "yazi-zoxide-cdi.sh";
    runtimeInputs = [pkgs.zoxide pkgs.fzf yaziPkg];
    text = ''
      # FZF-backed zoxide directory picker for Yazi; emits a safe cwd-change event.
      ${lib.optionalString (fzfDefaultOpts != "") ''
        if [[ -z "''${FZF_DEFAULT_OPTS:-}" ]]; then
          export FZF_DEFAULT_OPTS=${lib.escapeShellArg fzfDefaultOpts}
        fi
      ''}
      ${lib.optionalString (fzfDefaultCommand != "") ''
        if [[ -z "''${FZF_DEFAULT_COMMAND:-}" ]]; then
          export FZF_DEFAULT_COMMAND=${lib.escapeShellArg fzfDefaultCommand}
        fi
      ''}
      selection="$(zoxide query --interactive -- "$@" || true)"
      if [[ -z "$selection" ]]; then
        exit 0
      fi
      ya emit cd "$(printf %q "$selection")"
    '';
  };
in {
  home.packages = [forgeNvim forgeEdit forgeYazi yaziZoxideCdi];
}
