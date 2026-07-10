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
  # Full upstream grant vocabulary, zellij 0.44.3 PermissionType — grants are
  # typed rows here, projected into the permission cache declaratively (a 1-row
  # bar pane cannot render the interactive prompt).
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
    ./ops.nix # Workspace graph, layout assets, watch rows, receipts
  ];

  options.programs.zellij = {
    # One geometry owner per floating popup; the layout KDL and the integration
    # scripts both render from these rows, never from inline literals. Percent
    # strings only: both KDL and the zellij CLI accept them verbatim, and a
    # malformed value fails at eval instead of misrendering a popup.
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
        # Chord-launched pickers and panels (chords.nix + ops.nix consumers).
        graph = {
          x = "18%";
          y = "12%";
          width = "64%";
          height = "72%";
        };
        watchPicker = {
          x = "22%";
          y = "18%";
          width = "56%";
          height = "56%";
        };
        watchPanel = {
          x = "12%";
          y = "10%";
          width = "76%";
          height = "78%";
        };
        browse = {
          x = "20%";
          y = "15%";
          width = "60%";
          height = "70%";
        };
        # Toggle-dispatcher stub: a deliberately tiny short-lived pane that
        # runs the popup dispatch logic and reaps itself.
        dispatcher = {
          x = "45%";
          y = "45%";
          width = "10%";
          height = "10%";
        };
      };
    };

    # Permission manifest owner: one row per wasm, exact upstream grant names.
    # Clearing the plugin cache revokes grants — activation reseeds rows, so a
    # plugin upgrade (cache rebuild) and session resurrection stay distinct.
    pluginGrants = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf (lib.types.enum grantVocabulary));
      default = {
        "zjstatus.wasm" = ["ReadApplicationState" "ChangeApplicationState" "RunCommands"];
        "zellij_forgot.wasm" = ["ReadApplicationState" "ChangeApplicationState"];
      };
    };
  };

  config = {
    home.packages = [pkgs.zellij];

    # Grant reconcile, not append: plugDir-scoped rows PROJECT from the declared
    # set every activation — stale plugin rows are pruned, grant edits propagate,
    # rows outside plugDir (interactive grants for foreign paths) stay untouched.
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
      run /bin/sh -c ${lib.escapeShellArg ''
        set -eu
        permsFile="${permsFile}"
        tmp="$permsFile.forge-tmp"
        /bin/mkdir -p "''${permsFile%/*}"
        if [ -f "$permsFile" ]; then
          /usr/bin/awk -v dir="${plugDir}/" -v q='"' -f ${pruneAwk} "$permsFile" >"$tmp"
        else
          : >"$tmp"
        fi
        /bin/cat ${grantBlocks} >>"$tmp"
        /bin/mv "$tmp" "$permsFile"
      ''}
    '');

    # --- Plugin Installation ------------------------------------------------
    # Every third-party wasm is file-owned and hash-pinned; aliases resolve
    # through file: locations, so plugin load never depends on the network.
    xdg.configFile = {
      "zellij/plugins/zjstatus.wasm".source = pkgs.fetchurl {
        url = "https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm";
        hash = "sha256-4AaQEiNSQjnbYYAh5MxdF/gtxL+uVDKJW6QfA/E4Yf8=";
      };
      "zellij/plugins/zellij_forgot.wasm".source = pkgs.fetchurl {
        url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
        hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
      };
    };
  };
}
