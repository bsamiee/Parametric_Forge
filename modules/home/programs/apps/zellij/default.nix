# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/default.nix
# ----------------------------------------------------------------------------
# Zellij terminal multiplexer configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Plugin admission rows (nixpkgs attr or wasm url and hash, plus permissions) are the zellij-plugins lane of overlays/manifest.nix.
  pluginRows = (import ../../../../../overlays/manifest.nix).extensions.zellij-plugins.rows;

  # --- [SESSION_ATTACH]
  # The one attach every WezTerm spawn runs (deck.lua). A zellij server is a daemon that outlives the login session which forked it, and a
  # logout (a WindowServer watchdog restart is one) leaves it, and every pane it later spawns, bound to that session's dead launchd bootstrap
  # namespace: no Mach lookup resolves, so user lookups (sudo), DNS, logd, and pgrep all fail inside it. A server whose start precedes this
  # login's loginwindow therefore belongs to an ended session: it takes SIGTERM, which ends it as a shutdown does and keeps its serialized
  # layout (zellij's kill-session deletes that layout, so it is never used here), and the attach rebuilds the session with its recorded
  # commands running at once, each Claude Code pane resuming its conversation through the discovery hook (config.nix). Only /bin/ps is read,
  # filtered on the numeric uid: pgrep resolves through sysmond and `ps -U` through the user directory, lookups a stale namespace cannot make,
  # so the attach decides the same from any namespace. A server signalled here is awaited up to five seconds so the
  # attach never reaches a socket that is still closing.
  sessionAttach = pkgs.writeShellApplication {
    name = "zellij-session-attach";
    runtimeInputs = [pkgs.zellij pkgs.coreutils];
    text = ''
      started() {
        local stamp
        stamp=$(/bin/ps -o lstart= -p "$1") || return 1
        read -r stamp <<<"$stamp"
        LC_ALL=C /bin/date -j -f '%a %b %e %T %Y' "$stamp" +%s
      }
      login="" servers=()
      while read -r uid pid args; do
        ((uid == UID)) || continue
        case $args in
          /System/Library/CoreServices/loginwindow.app/*) login=$pid ;;
          */bin/zellij\ --server\ *) servers+=("$pid") ;;
        esac
      done < <(/bin/ps -axo uid=,pid=,args=)
      if [[ -n $login ]] && boundary=$(started "$login"); then
        for pid in "''${servers[@]}"; do
          if since=$(started "$pid") && ((since < boundary)) && kill -TERM "$pid" 2>/dev/null; then
            for _ in {1..50}; do
              kill -0 "$pid" 2>/dev/null || break
              sleep 0.1
            done
          fi
        done
      fi
      exec zellij attach --create --force-run-commands "$@"
    '';
  };
in {
  imports = [
    ./config.nix # Nix-generated main config
    ./themes/dracula.nix # Nix-generated Dracula theme
    ./layouts/default.nix # Shell-first layout
  ];

  options.forge.zellij = {
    attach = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = sessionAttach;
      description = "Session attach for WezTerm spawns: retires servers from an ended login session, then attaches or rebuilds the named session.";
    };
    # One geometry owner per floating popup; the layout KDL and the integration scripts both render from these rows, never from inline literals.
    # Percent strings only: both KDL and the zellij CLI accept them verbatim, and a malformed value fails at eval instead of misrendering a popup.
    popupGeometry = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options =
          lib.genAttrs ["x" "y" "width" "height"] (_:
            lib.mkOption {type = lib.types.strMatching "^[0-9]+%$";});
      });
      default = {
        yazi = {
          x = "8%";
          y = "6%";
          width = "84%";
          height = "86%";
        };
        # Toggle-dispatcher stub: a deliberately tiny short-lived pane that runs the popup dispatch logic and reaps itself.
        dispatcher = {
          x = "45%";
          y = "45%";
          width = "10%";
          height = "10%";
        };
      };
    };
  };

  config = {
    programs.zellij.enable = true;

    # Grant reconcile, not append: a 1-row bar pane cannot render the interactive permission prompt, so the manifest rows' exact upstream
    # grant names seed zellij's permission cache. plugDir-scoped rows PROJECT from those rows every activation — stale plugin rows are pruned,
    # grant edits propagate, rows outside plugDir (interactive grants for foreign paths) stay untouched. Clearing the plugin cache revokes
    # grants, and the next activation reseeds them.
    home.activation.zellijPluginGrants = lib.hm.dag.entryAfter ["writeBoundary"] (let
      plugDir = "${config.xdg.configHome}/zellij/plugins";
      permsFile = "${config.home.homeDirectory}/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl";
      grantBlocks = pkgs.writeText "zellij-plugin-grants.kdl" (lib.concatStrings (lib.mapAttrsToList (name: row: ''
          "${plugDir}/${name}.wasm" {
          ${lib.concatMapStrings (p: "    ${p}\n") row.permissions}}
        '')
        pluginRows));
      pruneAwk = pkgs.writeText "zellij-grant-prune.awk" ''
        /^"/ { drop = (index($0, q dir) == 1) }
        !drop { print }
        /^}/ { drop = 0 }
      '';
    in ''
      run ${pkgs.runtimeShell} -c ${lib.escapeShellArg ''
        set -eu
        permsFile="${permsFile}"
        tmp="$permsFile.tmp"
        ${pkgs.coreutils}/bin/mkdir -p "''${permsFile%/*}"
        if [ -f "$permsFile" ]; then
          ${pkgs.gawk}/bin/awk -v dir="${plugDir}/" -v q='"' -f ${pruneAwk} "$permsFile" >"$tmp"
        else
          : >"$tmp"
        fi
        ${pkgs.coreutils}/bin/cat ${grantBlocks} >>"$tmp"
        ${pkgs.coreutils}/bin/mv "$tmp" "$permsFile"
      ''}
    '');

    # --- [PLUGIN_INSTALLATION]
    # Every third-party wasm is file-owned from its manifest row: a row with `attr` resolves in nixpkgs zellijPlugins, a row with url/hash is a
    # pinned release wasm nixpkgs omits. Aliases resolve through file: locations, so plugin load never depends on the network. The plugins
    # block lives in config.kdl (programs.zellij.extraConfig); programs.zellij.plugins would add a second one plus load_plugins.
    xdg.configFile = lib.mapAttrs' (name: row:
      lib.nameValuePair "zellij/plugins/${name}.wasm" {
        source =
          if row ? attr
          then pkgs.zellijPlugins.${row.attr}
          else pkgs.fetchurl {inherit (row) url hash;};
      })
    pluginRows;
  };
}
