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

    # Web packaging host row: this darwin host ships the full-web build with
    # the server OFF and sharing disabled; exposure needs reverse-proxy plus
    # token-lifecycle rows first. A future NixOS host row may flip these.
    web = {
      server = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      sharing = lib.mkOption {
        type = lib.types.enum ["on" "off" "disabled"];
        default = "disabled";
      };
    };
  };

  config = {
    home.packages = [pkgs.zellij];

    home.activation.zellijPluginGrants = lib.hm.dag.entryAfter ["writeBoundary"] (let
      seed = wasm: perms: ''
        if ! /usr/bin/grep -qF "plugins/${wasm}" "$permsFile" 2>/dev/null; then
          {
            printf '"%s" {\n' "$plugDir/${wasm}"
            printf '    %s\n' ${lib.escapeShellArgs perms}
            printf '}\n'
          } >>"$permsFile"
        fi
      '';
    in ''
      permsFile="${config.home.homeDirectory}/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl"
      plugDir="${config.xdg.configHome}/zellij/plugins"
      run /bin/mkdir -p "''${permsFile%/*}"
      ${lib.concatStrings (lib.mapAttrsToList seed config.programs.zellij.pluginGrants)}
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
