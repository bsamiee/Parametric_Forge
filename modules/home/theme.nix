{
  lib,
  pkgs,
  typography,
  ...
}: let
  fonts = typography;
  byte = s: i: lib.fromHexString (builtins.substring i 2 s);

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

  # --- [ROW_GRAMMAR]
  row = fields: t: lib.filterAttrs (_: v: v != null) (lib.listToAttrs (lib.zipListsWith lib.nameValuePair fields t));
  byName = rows: lib.listToAttrs (map (r: lib.nameValuePair r.name (removeAttrs r ["name"])) rows);

  hexRows = s: lib.listToAttrs (map (t: let p = lib.splitString "=" t; in lib.nameValuePair (builtins.head p) (mkColor (builtins.elemAt p 1))) (lib.splitString " " s));
  palette = hexRows "crust=#0E0D16 background=#15131F surface=#1F1D2E current_line=#2A2839 selection=#45425E foreground=#F8F8F2 subtle=#9EA0BC comment=#857DB6 purple=#9580FF cyan=#80FFEA green=#8AFF80 yellow=#F0F05A amber=#F3AE51 orange=#FF9E4A red=#FF5C72 magenta=#FF79C6 pink=#E98FBE blue=#5AB4FF";
  brights = {black = palette.comment;} // hexRows "red=#FF7D89 green=#A4FF9B yellow=#FFFF80 blue=#7EC3FF magenta=#FF93CE cyan=#9FFFEE white=#FFFFFF";

  derived = hexRows "overlay=#37364D diffAdd=#122A18 diffAddEmph=#213926 diffDel=#3B1818 diffDelEmph=#4C2726 diffChange=#152539 diffChangeEmph=#233449 search=#3A3418 searchCurrent=#5A4E1E modeNormal=#50FA7B";

  pairs = ps: lib.listToAttrs (map (p: lib.nameValuePair (builtins.elemAt p 0) (builtins.elemAt p 1)) ps);
  families = lib.mapAttrs (_: pairs) {
    surface = [["crust" palette.crust] ["base" palette.background] ["surface" palette.surface] ["raised" palette.current_line] ["overlay" derived.overlay] ["selected" palette.selection]];
    text = [["primary" palette.foreground] ["subtle" palette.subtle] ["muted" palette.comment] ["inverse" palette.background]];
    accent = [["primary" palette.cyan] ["secondary" palette.magenta] ["tertiary" palette.pink] ["structural" palette.purple]];
    state = [["success" palette.green] ["warning" palette.amber] ["attention" palette.orange] ["danger" palette.red] ["info" palette.blue]];
    focus = [["active" palette.cyan] ["inactive" palette.subtle]];
    inbox = [["needs_you" palette.orange] ["failed" palette.red] ["done" palette.purple] ["working" palette.green] ["quiet" palette.subtle] ["new_output" palette.blue]];
    mode = [["normal" derived.modeNormal] ["locked" palette.selection] ["tab" palette.magenta] ["pane" palette.purple] ["move" palette.purple] ["resize" palette.purple] ["scroll" palette.foreground] ["search" palette.foreground] ["entersearch" palette.foreground] ["session" palette.magenta] ["renametab" palette.magenta] ["renamepane" palette.purple] ["renamesession" palette.magenta] ["prompt" palette.foreground] ["tmux" palette.selection]];
    diff = [["add" derived.diffAdd] ["addEmph" derived.diffAddEmph] ["del" derived.diffDel] ["delEmph" derived.diffDelEmph] ["change" derived.diffChange] ["changeEmph" derived.diffChangeEmph]];
    ui = [["border" palette.subtle] ["cursor" palette.foreground] ["indent" palette.subtle] ["whitespace" palette.selection] ["search" derived.search] ["match" derived.searchCurrent]];
  };

  roles =
    families
    // {
      git = byName (map (t: {
          name = builtins.elemAt t 0;
          color = lib.getAttrFromPath (lib.splitString "." (builtins.elemAt t 1)) families;
          ascii = builtins.elemAt t 2;
        }) [
          ["added" "state.success" "[+]"]
          ["staged" "state.success" "[*]"]
          ["modified" "state.info" "[~]"]
          ["deleted" "state.danger" "[-]"]
          ["untracked" "state.success" "[?]"]
          ["renamed" "accent.structural" "[>]"]
          ["typechange" "state.info" "[~]"]
          ["conflict" "accent.secondary" "[!]"]
          ["ahead" "state.success" "[^]"]
          ["behind" "state.warning" "[v]"]
          ["diverged" "state.attention" "[%]"]
          ["stashed" "text.muted" "[$]"]
          ["clean" "state.success" "[=]"]
        ]);
    };

  ansi16 = let
    base = {
      inherit (palette) red green yellow blue magenta cyan;
      black = palette.background;
      white = palette.foreground;
    };
  in
    base // lib.mapAttrs' (n: v: lib.nameValuePair "bright${lib.toUpper (builtins.substring 0 1 n)}${builtins.substring 1 99 n}" v) brights;

  syntaxScopes = map (row ["name" "scope" "color" "style" "background"]) [
    ["Comment" "comment, punctuation.definition.comment" palette.comment "italic"]
    ["String" "string" palette.yellow]
    ["Escape" "constant.character.escape" palette.orange]
    ["Number" "constant.numeric" palette.purple]
    ["Constant" "constant.language, constant.character, constant.other" palette.purple]
    ["Keyword" "keyword, storage, storage.type, storage.modifier" palette.pink]
    ["Operator" "keyword.operator, punctuation.accessor" palette.subtle]
    ["Punctuation" "punctuation" palette.subtle]
    ["Function" "entity.name.function, support.function" palette.green]
    ["Type" "entity.name.class, entity.name.type, entity.other.inherited-class, support.type, support.class" palette.cyan]
    ["Variable" "variable, support.variable" palette.blue]
    ["Parameter" "variable.parameter" palette.blue "italic"]
    ["Attribute" "entity.other.attribute-name" palette.magenta "italic"]
    ["Tag" "entity.name.tag" palette.magenta]
    ["Heading" "markup.heading" palette.purple "bold"]
    ["Bold" "markup.bold" palette.orange "bold"]
    ["Italic" "markup.italic" palette.yellow "italic"]
    ["Link" "markup.underline.link" palette.blue]
    ["Inserted" "markup.inserted" palette.green]
    ["Deleted" "markup.deleted" palette.red]
    ["Invalid" "invalid" palette.foreground null palette.red]
  ];

  icons = {
    process = {
      zsh = "󰆍";
      python = "󰌠";
      node = "󰎙";
      ssh = "󰣀";
      git = "󰊢";
      nix = "󱄅";
      claude = "󰙴";
      container = builtins.fromJSON ''"\uf4b7"'';
    };
    alphabet = byName (map (t: {
        name = builtins.elemAt t 0;
        glyph = builtins.fromJSON ''"\u${builtins.elemAt t 1}"'';
        ascii = builtins.elemAt t 2;
      })
      fonts.catalog."Symbols Nerd Font Mono".statusAlphabet);
  };

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

  tmSetting = p: "        <key>${builtins.elemAt p 0}</key><string>${(builtins.elemAt p 1).hex}</string>";
  tmTheme = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key>
      <string>Dracula</string>
      <key>settings</key>
      <array>
        <dict>
          <key>settings</key>
          <dict>
    ${lib.concatMapStringsSep "\n" tmSetting [["background" roles.surface.base] ["foreground" roles.text.primary] ["caret" roles.text.primary] ["selection" roles.surface.selected] ["lineHighlight" roles.surface.raised] ["invisibles" roles.surface.selected] ["gutterForeground" roles.text.subtle] ["findHighlight" roles.ui.match] ["findHighlightForeground" roles.text.primary] ["misspelling" roles.state.danger]]}
          </dict>
        </dict>
    ${lib.concatMapStringsSep "\n" scopeRule syntaxScopes}
      </array>
    </dict>
    </plist>
  '';
  tmThemeFile = pkgs.writeText "dracula.tmTheme" tmTheme;

  fzfColorRows = [
    "--color=fg:${roles.text.primary.hex},fg+:${roles.text.inverse.hex},bg:${roles.surface.base.hex},bg+:${roles.focus.active.hex},selected-fg:${roles.text.inverse.hex},selected-bg:${roles.focus.active.hex}"
    "--color=hl:${roles.state.success.hex},hl+:${roles.accent.secondary.hex},info:${roles.text.muted.hex},marker:${roles.state.success.hex}"
    "--color=prompt:${roles.accent.secondary.hex},spinner:${roles.state.success.hex},pointer:${roles.accent.secondary.hex},header:${roles.text.muted.hex}"
    "--color=gutter:${roles.surface.base.hex},border:${roles.accent.primary.hex},separator:${roles.accent.tertiary.hex},scrollbar:${roles.accent.tertiary.hex}"
    "--color=preview-fg:${roles.text.primary.hex},preview-scrollbar:${roles.accent.tertiary.hex},label:${roles.accent.secondary.hex},query:${roles.text.primary.hex}"
  ];

  projections = {
    inherit tmThemeFile;
    gitHex =
      lib.mapAttrs (_: g: {
        color = g.color.hex;
        inherit (g) ascii;
      })
      roles.git;
    contextBadges =
      lib.mapAttrs (_: t: {
        glyph = icons.process.${builtins.elemAt t 0};
        role = builtins.elemAt t 1;
      }) {
        remote = ["ssh" "state.warning"];
        container = ["container" "accent.structural"];
      };
    weztermColorScheme = let
      labeled = lib.concatMapAttrs (n: p: {
        "${n}_bg" = {Color = (builtins.elemAt p 0).hex;};
        "${n}_fg" = {Color = (builtins.elemAt p 1).hex;};
      });
      slots = map (k: ansi16.${k}.hex);
    in
      lib.mapAttrs (_: c: c.hex) (pairs [["foreground" palette.foreground] ["background" palette.background] ["cursor_bg" palette.foreground] ["cursor_fg" palette.background] ["cursor_border" palette.foreground] ["selection_fg" palette.foreground] ["selection_bg" palette.selection] ["split" palette.subtle]])
      // {
        ansi = slots ["black" "red" "green" "yellow" "blue" "magenta" "cyan" "white"];
        brights = slots ["brightBlack" "brightRed" "brightGreen" "brightYellow" "brightBlue" "brightMagenta" "brightCyan" "brightWhite"];
      }
      // labeled {
        quick_select_label = [roles.accent.structural roles.text.inverse];
        quick_select_match = [roles.surface.selected roles.text.primary];
        input_selector_label = [roles.surface.raised roles.accent.primary];
        launcher_label = [roles.surface.raised roles.accent.primary];
      };
    timeDisplay = {
      sameDay = "%H:%M";
      dated = "%d/%m %H:%M";
    };
    inherit fzfColorRows;
    fzfArgs = fzfColorRows ++ ["--border=sharp" "--layout=reverse" "--info=right" "--highlight-line" "--prompt=❯ " "--pointer=❯"];
    blameRamp = lib.concatMapStringsSep " " (c: c.hex) [
      roles.surface.base
      roles.surface.raised
      roles.surface.overlay
      roles.surface.selected
    ];
  };
in {
  _module.args.theme = {inherit palette derived roles ansi16 syntaxScopes icons projections;};
}
