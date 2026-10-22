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
in {
  imports = [
    ./config.nix # Nix-generated main config
    ./themes/dracula.nix # Nix-generated Dracula theme
    ./layouts/default.nix # Shell-first layout
  ];

  options.forge.zellij = {
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
