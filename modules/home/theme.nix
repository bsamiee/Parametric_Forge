# Title         : theme.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/theme.nix
# ----------------------------------------------------------------------------
# Estate palette owner: Dracula-variant base rows, semantic roles, ANSI-16
# projection, syntax scope table, and serialization projections. Every color
# consumer interpolates these tokens; no consumer carries a private hex.
{
  lib,
  pkgs,
  ...
}: let
  hexDigit =
    lib.listToAttrs (lib.imap0 (i: c: lib.nameValuePair c i)
      (lib.stringToCharacters "0123456789ABCDEF"));
  byte = s: i:
    16
    * hexDigit.${lib.toUpper (builtins.substring i 1 s)}
    + hexDigit.${lib.toUpper (builtins.substring (i + 1) 1 s)};
  pad2 = n: lib.fixedWidthString 2 "0" (lib.toHexString n);

  # Color record: uppercase hex plus every numeric rendering consumers need.
  mkColor = raw: let
    hex = lib.toUpper raw;
    r = byte hex 1;
    g = byte hex 3;
    b = byte hex 5;
  in {
    inherit hex r g b;
    triple = "${toString r} ${toString g} ${toString b}";
    csv = "${toString r},${toString g},${toString b}";
    rgba = alpha: "rgba(${toString r}, ${toString g}, ${toString b}, ${alpha})";
  };
  mix = a: b:
    mkColor "#${pad2 ((a.r + b.r) / 2)}${pad2 ((a.g + b.g) / 2)}${pad2 ((a.b + b.b) / 2)}";

  # The 13 canonical Dracula-variant rows plus the semantic blue pair; the
  # blue rows end the faked ANSI blue (comment slate) and blue==cyan aliasing.
  palette = lib.mapAttrs (_: mkColor) {
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
    magenta = "#D82F94";
    pink = "#E98FBE";
    blue = "#7AA2F7";
    brightBlue = "#A9C7FF";
  };

  roles = {
    surface = {
      base = palette.background;
      raised = palette.current_line;
      overlay = mix palette.current_line palette.selection;
      selected = palette.selection;
    };
    text = {
      primary = palette.foreground;
      muted = palette.comment;
      inverse = palette.background;
    };
    accent = {
      primary = palette.cyan;
      secondary = palette.magenta;
      tertiary = palette.pink;
      structural = palette.purple;
    };
    state = {
      success = palette.green;
      warning = palette.yellow;
      attention = palette.orange;
      danger = palette.red;
      info = palette.blue;
    };
  };

  # Canonical hex->ANSI-16 assignment; terminal palettes and ANSI-slot
  # consumers (procs, delta named styles) agree with truecolor consumers.
  # Slot 4 carries a real blue and slot 12 its bright companion — the
  # comment-slate fake and the blue==cyan duplication are closed defects.
  ansi16 = {
    inherit (palette) red green yellow magenta cyan blue;
    black = palette.background;
    white = palette.foreground;
    brightBlack = palette.selection;
    brightRed = palette.red;
    brightGreen = palette.green;
    brightYellow = palette.yellow;
    inherit (palette) brightBlue;
    brightMagenta = palette.magenta;
    brightCyan = palette.cyan;
    brightWhite = palette.foreground;
  };

  # One scope table drives the tmTheme (bat/delta/yazi syntect) and the
  # VS Code textMate rules; a new syntax consumer is a projection, not a copy.
  syntaxScopes = [
    {
      name = "Comment";
      scope = "comment, punctuation.definition.comment";
      color = palette.comment;
      style = "italic";
    }
    {
      name = "String";
      scope = "string";
      color = palette.yellow;
    }
    {
      name = "Escape";
      scope = "constant.character.escape";
      color = palette.magenta;
    }
    {
      name = "Number";
      scope = "constant.numeric";
      color = palette.purple;
    }
    {
      name = "Constant";
      scope = "constant.language, constant.character, constant.other";
      color = palette.purple;
    }
    {
      name = "Keyword";
      scope = "keyword, storage, storage.type";
      color = palette.magenta;
    }
    {
      name = "Operator";
      scope = "keyword.operator";
      color = palette.magenta;
    }
    {
      name = "Function";
      scope = "entity.name.function, support.function";
      color = palette.green;
    }
    {
      name = "Type";
      scope = "entity.name.class, entity.name.type, entity.other.inherited-class, support.type, support.class";
      color = palette.cyan;
    }
    {
      name = "Variable";
      scope = "variable, support.variable";
      color = palette.cyan;
    }
    {
      name = "Parameter";
      scope = "variable.parameter";
      color = palette.orange;
      style = "italic";
    }
    {
      name = "Attribute";
      scope = "entity.other.attribute-name";
      color = palette.green;
      style = "italic";
    }
    {
      name = "Tag";
      scope = "entity.name.tag";
      color = palette.magenta;
    }
    {
      name = "Heading";
      scope = "markup.heading";
      color = palette.purple;
      style = "bold";
    }
    {
      name = "Bold";
      scope = "markup.bold";
      color = palette.orange;
      style = "bold";
    }
    {
      name = "Italic";
      scope = "markup.italic";
      color = palette.yellow;
      style = "italic";
    }
    {
      name = "Link";
      scope = "markup.underline.link";
      color = palette.cyan;
    }
    {
      name = "Inserted";
      scope = "markup.inserted";
      color = palette.green;
    }
    {
      name = "Deleted";
      scope = "markup.deleted";
      color = palette.red;
    }
    {
      name = "Invalid";
      scope = "invalid";
      color = palette.foreground;
      background = palette.red;
    }
  ];

  scopeRule = row: let
    style = row.style or null;
    background = row.background or null;
  in ''
        <dict>
          <key>name</key><string>${row.name}</string>
          <key>scope</key><string>${row.scope}</string>
          <key>settings</key>
          <dict>
            <key>foreground</key><string>${row.color.hex}</string>
    ${lib.optionalString (background != null) "        <key>background</key><string>${background.hex}</string>\n"}${lib.optionalString (style != null) "        <key>fontStyle</key><string>${style}</string>\n"}      </dict>
        </dict>'';

  tmTheme = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key>
      <string>Forge Dracula</string>
      <key>settings</key>
      <array>
        <dict>
          <key>settings</key>
          <dict>
            <key>background</key><string>${roles.surface.base.hex}</string>
            <key>foreground</key><string>${roles.text.primary.hex}</string>
            <key>caret</key><string>${roles.text.primary.hex}</string>
            <key>selection</key><string>${roles.surface.selected.hex}</string>
            <key>lineHighlight</key><string>${roles.surface.raised.hex}</string>
            <key>invisibles</key><string>${roles.surface.selected.hex}</string>
            <key>gutterForeground</key><string>${roles.text.muted.hex}</string>
            <key>findHighlight</key><string>${palette.yellow.hex}</string>
            <key>findHighlightForeground</key><string>${roles.text.inverse.hex}</string>
            <key>misspelling</key><string>${roles.state.danger.hex}</string>
          </dict>
        </dict>
    ${lib.concatMapStringsSep "\n" scopeRule syntaxScopes}
      </array>
    </dict>
    </plist>
  '';
  tmThemeFile = pkgs.writeText "forge-dracula.tmTheme" tmTheme;

  projections = {
    inherit tmThemeFile;
    # Lua return-table shared by WezTerm and Neovim generated palettes.
    luaPalette = ''
      -- Generated from the Forge theme owner (modules/home/theme.nix).
      return {
      ${lib.concatStrings (lib.mapAttrsToList (name: c: "  [\"${name}\"] = \"${c.hex}\",\n") palette)}}
    '';
    # Role hexes as a Lua return-table: the shared visible-state vocabulary for
    # status cells, segment labels, and destructive-confirmation styling.
    luaRoles = ''
      -- Generated from the Forge theme owner (modules/home/theme.nix).
      return {
      ${lib.concatStrings (lib.mapAttrsToList (
          ns: rows: "  [\"${ns}\"] = {\n${lib.concatStrings (lib.mapAttrsToList (name: c: "    [\"${name}\"] = \"${c.hex}\",\n") rows)}  },\n"
        )
        roles)}}
    '';
    # WezTerm color-scheme rows in the colors-TOML shape; the wezterm owner
    # writes them under wezterm/colors and binds `color_scheme`.
    weztermColorScheme = {
      foreground = palette.foreground.hex;
      background = palette.background.hex;
      cursor_bg = palette.foreground.hex;
      cursor_fg = palette.background.hex;
      cursor_border = palette.foreground.hex;
      selection_fg = palette.foreground.hex;
      selection_bg = palette.selection.hex;
      split = palette.comment.hex;
      ansi = map (c: c.hex) [
        ansi16.black
        ansi16.red
        ansi16.green
        ansi16.yellow
        ansi16.blue
        ansi16.magenta
        ansi16.cyan
        ansi16.white
      ];
      brights = map (c: c.hex) [
        ansi16.brightBlack
        ansi16.brightRed
        ansi16.brightGreen
        ansi16.brightYellow
        ansi16.brightBlue
        ansi16.brightMagenta
        ansi16.brightCyan
        ansi16.brightWhite
      ];
      tab_bar = {
        background = roles.surface.base.hex;
        active_tab = {
          bg_color = roles.surface.selected.hex;
          fg_color = roles.text.primary.hex;
        };
        inactive_tab = {
          bg_color = roles.surface.base.hex;
          fg_color = roles.text.muted.hex;
        };
        inactive_tab_hover = {
          bg_color = roles.surface.raised.hex;
          fg_color = roles.text.primary.hex;
        };
        new_tab = {
          bg_color = roles.surface.base.hex;
          fg_color = roles.text.muted.hex;
        };
        new_tab_hover = {
          bg_color = roles.surface.raised.hex;
          fg_color = roles.text.primary.hex;
        };
      };
    };
    # Four-step surface ramp for delta blame backgrounds.
    blameRamp = lib.concatMapStringsSep " " (c: c.hex) [
      roles.surface.base
      roles.surface.raised
      roles.surface.overlay
      roles.surface.selected
    ];
    # textMate rules for VS Code editor.tokenColorCustomizations.
    vscodeTokenRules =
      map (row: {
        inherit (row) name scope;
        settings =
          {foreground = row.color.hex;}
          // lib.optionalAttrs (row ? style) {fontStyle = row.style;};
      })
      syntaxScopes;
  };
in {
  options.forge.theme = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {inherit palette roles ansi16 syntaxScopes projections;};
    description = "Estate palette owner: Dracula-variant tokens, roles, ANSI-16, projections.";
  };

  # Machine-readable projections for consumers outside Home Manager modules.
  config.xdg.configFile = {
    "forge/theme/palette.json".text = builtins.toJSON {
      palette = lib.mapAttrs (_: c: c.hex) palette;
      roles = lib.mapAttrs (_: lib.mapAttrs (_: c: c.hex)) roles;
      ansi16 = lib.mapAttrs (_: c: c.hex) ansi16;
    };
    "forge/theme/forge-dracula.tmTheme".source = tmThemeFile;
  };
}
