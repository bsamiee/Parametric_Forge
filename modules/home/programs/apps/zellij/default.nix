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

  options.programs.zellij = {
    colors = lib.mkOption {
      # Single source of truth for all Zellij color configuration; r/g/b derive
      # from hex, so a palette entry is exactly one hex row.
      type = lib.types.attrs;
      default = let
        hexVal =
          lib.listToAttrs (lib.imap0 (i: c: lib.nameValuePair c i)
            (lib.stringToCharacters "0123456789abcdef"));
        byte = s: i:
          16
          * hexVal.${lib.toLower (builtins.substring i 1 s)}
          + hexVal.${lib.toLower (builtins.substring (i + 1) 1 s)};
        mkColor = hex: {
          inherit hex;
          r = byte hex 1;
          g = byte hex 3;
          b = byte hex 5;
        };
      in
        lib.mapAttrs (_: mkColor) {
          background = "#15131F";
          current_line = "#2A2640";
          selection = "#44475A";
          foreground = "#F8F8F2";
          comment = "#6272A4";
          purple = "#A072C6";
          cyan = "#94F2E8";
          green = "#50FA7B";
          yellow = "#F1FA8C";
          orange = "#F97359";
          red = "#FF5555";
          magenta = "#d82f94";
          pink = "#E98FBE";
        };
      description = "Color palette for Zellij theme and plugins";
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
