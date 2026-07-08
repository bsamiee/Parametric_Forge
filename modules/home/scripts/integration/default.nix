# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/default.nix
# ----------------------------------------------------------------------------
# Yazi -> Zellij -> Neovim rail: popup dispatcher, RPC handoff, server owner.
# Pane targeting is ID-based via list-panes JSON; never ordinal focus. The one
# hide-floating-panes in dismiss is a deliberate baseline restore, not layer
# coupling. terminal_command is the spawn command (invoked_with), so exec
# inside a pane never breaks pane rediscovery.
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

      # Tab resolution can lag pane creation at layout startup; retry briefly
      # and skip registry publication rather than poisoning a tab-0 entry.
      tab_id=""
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        tab_id="$(zellij action list-panes --all --json 2>/dev/null \
          | jq -r --arg self "$pane_id" \
            '[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0].tab_id // empty' \
          || true)"
        if [[ -n "$tab_id" ]]; then
          break
        fi
        sleep 0.1
      done

      socket="''${runtime_root}/pane-''${pane_id}.sock"
      rm -f "$socket"
      if [[ -n "$tab_id" ]]; then
        printf '%s\t%s\t%s\n' "$tab_id" "$pane_id" "$socket" \
          >"''${runtime_root}/editor-tab-''${tab_id}.tsv"
      fi
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
      caller_row="$(jq -c --arg self "$caller" \
        '[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0] // {}' <<<"$panes")"
      tab_id="$(jq -r '.tab_id // 0' <<<"$caller_row")"

      editor_pane=""
      socket=""
      registry="''${runtime_root}/editor-tab-''${tab_id}.tsv"
      if [[ -r "$registry" ]]; then
        IFS=$'\t' read -r _ editor_pane socket <"$registry" || true
      fi

      # Registry hit counts only if the recorded pane still lives in this tab
      # AND the socket answers AND the remote open succeeds; any miss or race
      # falls through to a fresh editor pane.
      handed_off="false"
      if [[ -n "$editor_pane" && -n "$socket" && -S "$socket" ]]; then
        pane_alive="$(jq -r --arg id "$editor_pane" --argjson tab "$tab_id" \
          '[.[] | select((.is_plugin | not) and ((.id | tostring) == $id)
            and (.tab_id == $tab) and (.exited | not))] | length > 0' <<<"$panes")"
        if [[ "$pane_alive" == "true" ]] \
          && nvim --server "$socket" --remote-expr '1' >/dev/null 2>&1 \
          && nvim --server "$socket" --remote "$@" >/dev/null 2>&1; then
          handed_off="true"
        fi
      fi
      if [[ "$handed_off" != "true" ]]; then
        editor_pane="$(zellij action new-pane --name " [EDITOR] " --cwd "$PWD" -- forge-nvim.sh "$@")"
      fi

      # Focusing the tiled editor lowers the floating layer without touching
      # other floating panes.
      if [[ -n "$editor_pane" ]]; then
        zellij action focus-pane-id "terminal_''${editor_pane#terminal_}" >/dev/null 2>&1 || true
      fi

      # Pane-scoped dismissal: close only the Forge popup we ran inside; this
      # kills our own process tree, so it must stay the final statement.
      caller_is_popup="$(jq -r \
        '((.is_floating // false) and ((.terminal_command // "") | startswith("forge-yazi.sh")))' <<<"$caller_row")"
      if [[ "$caller_is_popup" == "true" ]]; then
        zellij action close-pane --pane-id "terminal_''${caller}" >/dev/null 2>&1 || true
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
      # Prefix-anchored on the spawn command: a rediscovered popup is exactly a
      # forge-yazi.sh process, never an editor holding a forge-yazi* file arg.
      popup_row="$(jq -c --arg self "$self" --argjson tab "$tab_id" \
        '[.[] | select((.is_plugin | not) and (.exited | not) and (.tab_id == $tab)
          and ((.id | tostring) != $self)
          and ((.terminal_command // "") | startswith("forge-yazi.sh"))
          and (((.terminal_command // "") | startswith("forge-yazi.sh toggle")) | not))][0] // {}' <<<"$panes")"
      popup="$(jq -r '.id // empty' <<<"$popup_row")"

      if [[ -z "$popup" ]]; then
        created="$(zellij action new-pane --floating --pinned true \
          -x "8%" -y "6%" --width "84%" --height "86%" \
          --name " [YAZI] " --close-on-exit --cwd "$PWD" -- forge-yazi.sh)"
        zellij action focus-pane-id "$created" >/dev/null 2>&1 || true
      elif [[ "$(jq -r '.is_suppressed // false' <<<"$popup_row")" == "true" ]]; then
        # The in-place dispatcher replaced the focused popup: chord means
        # dismiss. Lower the layer first (restores the hide_floating_panes
        # baseline), then close only the popup pane.
        zellij action hide-floating-panes >/dev/null 2>&1 || true
        zellij action close-pane --pane-id "terminal_''${popup}"
      else
        # Focusing a floating pane surfaces the floating layer
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
      # ya emit passes argv structurally; the raw path is one argument
      ya emit cd "$selection"
    '';
  };
in {
  home.packages = [forgeNvim forgeEdit forgeYazi yaziZoxideCdi];
}
