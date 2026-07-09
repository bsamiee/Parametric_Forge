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
}: {
  imports = [
    ./config.nix # Nix-generated main config
    ./themes/dracula.nix # Nix-generated Dracula theme
    ./layouts/default.nix # Shell-first layout with floating lazygit
  ];

  # One geometry owner per floating popup; the layout KDL and the integration
  # scripts both render from these rows, never from inline literals.
  options.programs.zellij.popupGeometry = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        x = lib.mkOption {type = lib.types.str;};
        y = lib.mkOption {type = lib.types.str;};
        width = lib.mkOption {type = lib.types.str;};
        height = lib.mkOption {type = lib.types.str;};
      };
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

  config = {
    home.packages = [pkgs.zellij];

    # Zellij grants plugin permissions interactively; a 1-row bar pane cannot
    # render the prompt, so grants are seeded declaratively per wasm path.
    home.activation.zellijPluginGrants = lib.hm.dag.entryAfter ["writeBoundary"] (let
      grants = {
        "zjstatus.wasm" = ["ReadApplicationState" "ChangeApplicationState" "RunCommands"];
        "zellij_forgot.wasm" = ["ReadApplicationState" "ChangeApplicationState"];
        "zellij-pane-picker.wasm" = ["ReadApplicationState" "Reconfigure" "ChangeApplicationState"];
      };
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
      ${lib.concatStrings (lib.mapAttrsToList seed grants)}
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
      "zellij/plugins/zellij-pane-picker.wasm".source = pkgs.fetchurl {
        url = "https://github.com/shihanng/zellij-pane-picker/releases/download/v0.6.0/zellij-pane-picker.wasm";
        hash = "sha256-QO2cSZLPvFGg0ORcOjfrsU30Ox0at4z48aC5QvXLlho=";
      };
    };
  };
}
