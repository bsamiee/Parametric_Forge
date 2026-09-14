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
  # Plugin admission rows (wasm url, hash, permissions) are the zellij-plugins lane of overlays/manifest.nix.
  pluginRows = (import ../../../../../overlays/manifest.nix).extensions.zellij-plugins.rows;
  # zellij PermissionType vocabulary: typed grant rows seed the permission cache; a 1-row bar pane cannot render the interactive prompt.
  grantVocabulary = [
    "ReadApplicationState"
    "ChangeApplicationState"
    "OpenFiles"
    "RunCommands"
    "OpenTerminalsOrPlugins"
    "WriteToStdin"
    "WebAccess"
    "ReadCliPipes"
    "MessageAndLaunchOtherPlugins"
    "Reconfigure"
    "FullHdAccess"
    "StartWebServer"
    "InterceptInput"
    "ReadPaneContents"
    "RunActionsAsUser"
    "WriteToClipboard"
    "ReadSessionEnvironmentVariables"
  ];
in {
  imports = [
    ./config.nix # Nix-generated main config
    ./themes/dracula.nix # Nix-generated Dracula theme
    ./layouts/default.nix # Shell-first layout with floating lazygit
  ];

  options.programs.zellij = {
    # One geometry owner per floating popup; the layout KDL and the integration scripts both render from these rows, never from inline literals.
    # Percent strings only: both KDL and the zellij CLI accept them verbatim, and a malformed value fails at eval instead of misrendering a popup.
    popupGeometry = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options =
          lib.genAttrs ["x" "y" "width" "height"] (_:
            lib.mkOption {type = lib.types.strMatching "^[0-9]+%$";});
      });
      default = {
        lazygit = {
          x = "10%";
          y = "5%";
          width = "80%";
          height = "80%";
        };
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

    # Permission rows per wasm, exact upstream grant names, projected from the manifest lane. Clearing the plugin cache revokes grants —
    # activation reseeds rows, so a plugin upgrade (cache rebuild) and session resurrection stay distinct.
    pluginGrants = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf (lib.types.enum grantVocabulary));
      default = lib.mapAttrs' (name: row: lib.nameValuePair "${name}.wasm" row.permissions) pluginRows;
    };
  };

  config = {
    home.packages = [pkgs.zellij];

    # Grant reconcile, not append: plugDir-scoped rows PROJECT from the declared set every activation — stale plugin rows are pruned,
    # grant edits propagate, rows outside plugDir (interactive grants for foreign paths) stay untouched.
    home.activation.zellijPluginGrants = lib.hm.dag.entryAfter ["writeBoundary"] (let
      plugDir = "${config.xdg.configHome}/zellij/plugins";
      permsFile = "${config.home.homeDirectory}/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl";
      grantBlocks = pkgs.writeText "zellij-plugin-grants.kdl" (lib.concatStrings (lib.mapAttrsToList (wasm: perms: ''
          "${plugDir}/${wasm}" {
          ${lib.concatMapStrings (p: "    ${p}\n") perms}}
        '')
        config.programs.zellij.pluginGrants));
      pruneAwk = pkgs.writeText "zellij-grant-prune.awk" ''
        /^"/ { drop = (index($0, q dir) == 1) }
        !drop { print }
        /^}/ { drop = 0 }
      '';
    in ''
      run ${pkgs.runtimeShell} -c ${lib.escapeShellArg ''
        set -eu
        permsFile="${permsFile}"
        tmp="$permsFile.forge-tmp"
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
    # Every third-party wasm is file-owned and hash-pinned from its manifest row; aliases resolve through file: locations, so plugin load never
    # depends on the network.
    xdg.configFile = lib.mapAttrs' (name: row: lib.nameValuePair "zellij/plugins/${name}.wasm" {source = pkgs.fetchurl {inherit (row) url hash;};}) pluginRows;
  };
}
