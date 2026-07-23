# Title         : theme.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/theme.nix
# ----------------------------------------------------------------------------
# Estate palette owner: enriched Dracula-variant rows, semantic roles, ANSI-16 projection, the master syntax scope table (tmTheme, treesitter,
# textMate, and semantic tokens project from one pivot), derived diff/search/git roles, the shared icon vocabulary, the target registry with its
# coverage projection, and the rendered proof lane. Every color consumer interpolates these tokens; no consumer carries a private hex.
{
  config,
  lib,
  pkgs,
  ...
}: let
  fonts = config.forge.fonts;
  byte = s: i: lib.fromHexString (builtins.substring i 2 s);

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

  # --- [ROW_GRAMMAR]
  # Positional tuples zip against a field schema: a short tuple drops trailing fields, null skips a slot, and an oversized tuple faults —
  # zipListsWith would truncate silently otherwise. byName keys a row list on its `name`.
  row = fields: t:
    lib.throwIf (builtins.length t > builtins.length fields)
    "theme row '${toString (builtins.head t)}' exceeds schema [${lib.concatStringsSep " " fields}]"
    (lib.filterAttrs (_: v: v != null) (lib.listToAttrs (lib.zipListsWith lib.nameValuePair fields t)));
  byName = rows: lib.listToAttrs (map (r: lib.nameValuePair r.name (removeAttrs r ["name"])) rows);

  # Enriched palette: the canonical rows plus the design-language growth — crust/surface complete the elevation ladder, subtle is the third fg
  # tier and the structural-UI hue, amber splits warning from string-yellow, blue ends the faked ANSI blue, brightBlue ends blue==cyan.
  # current_line is retuned (chroma pulled to kill the muddy active line) and magenta is AA-lifted; every row is contrast-verified against the
  # base. Rows spell as name=#HEX tokens folded through mkColor — one vector, one constructor.
  hexRows = s: lib.listToAttrs (map (t: let p = lib.splitString "=" t; in lib.nameValuePair (builtins.head p) (mkColor (builtins.elemAt p 1))) (lib.splitString " " s));
  palette = hexRows "crust=#0E0D16 background=#15131F surface=#201E30 current_line=#2A2A3A selection=#44475A foreground=#F8F8F2 subtle=#8E91A5 comment=#6272A4 purple=#A072C6 cyan=#94F2E8 green=#50FA7B yellow=#F1FA8C amber=#F3AE51 orange=#F97359 red=#FF5555 magenta=#EE55A8 pink=#E98FBE blue=#7AA2F7 brightBlue=#A9C7FF";

  # Derived roles: computed fills, never palette rows. Diff and search tint the background and hold the code foreground neutral (fg clears 7.7+
  # on every fill); emphasis is the same hue at +0.06 OKLCH L.
  derived = hexRows "overlay=#37364D diffAdd=#122A18 diffAddEmph=#213926 diffDel=#3B1818 diffDelEmph=#4C2726 diffChange=#152539 diffChangeEmph=#233449 search=#3A3418 searchCurrent=#5A4E1E";

  # Role families as [name color] pair rows folded per family.
  pairs = ps: lib.listToAttrs (map (p: lib.nameValuePair (builtins.elemAt p 0) (builtins.elemAt p 1)) ps);
  families = lib.mapAttrs (_: pairs) {
    surface = [["crust" palette.crust] ["base" palette.background] ["surface" palette.surface] ["raised" palette.current_line] ["overlay" derived.overlay] ["selected" palette.selection]];
    text = [["primary" palette.foreground] ["subtle" palette.subtle] ["muted" palette.comment] ["inverse" palette.background]];
    accent = [["primary" palette.cyan] ["secondary" palette.magenta] ["tertiary" palette.pink] ["structural" palette.purple]];
    state = [["success" palette.green] ["warning" palette.amber] ["attention" palette.orange] ["danger" palette.red] ["info" palette.blue]];
    # Focus pair: the one active/inactive derivation every chrome surface (tabs, pane frames, ribbons) reads instead of re-picking hues.
    focus = [["active" palette.cyan] ["inactive" palette.subtle]];
    # Modal-UI hue ladder: one hue per mux/editor mode chip; search and entersearch share deliberately (one toggled surface), renames share
    # (one input-editing state), and every other mode reads distinct at a glance — no two standing modes collapse onto one hue.
    mode = [["normal" palette.green] ["locked" palette.selection] ["tab" palette.magenta] ["pane" palette.orange] ["move" palette.cyan] ["resize" palette.purple] ["scroll" palette.yellow] ["search" palette.pink] ["entersearch" palette.pink] ["session" palette.blue] ["renametab" palette.red] ["renamepane" palette.red] ["prompt" palette.foreground] ["tmux" palette.amber]];
    diff = [["add" derived.diffAdd] ["addEmph" derived.diffAddEmph] ["del" derived.diffDel] ["delEmph" derived.diffDelEmph] ["change" derived.diffChange] ["changeEmph" derived.diffChangeEmph]];
    ui = [["border" palette.subtle] ["cursor" palette.foreground] ["indent" palette.subtle] ["whitespace" palette.selection] ["search" derived.search] ["match" derived.searchCurrent]];
  };

  # Two-register git vocabulary from the fonts-catalog gitAlphabet rows; dotted role paths resolve on the folded families (contextBadges grammar),
  # so a hue rebind lands on every consumer and a new state is one catalog row. Register law: ascii = persisted/piped output and prose-like readouts
  # where marker+count reads as a text token (delta labels; the operator-ratified starship cluster); glyph = fixed one-cell icon columns where shape
  # is the cue (gitsigns gutter, yazi linemode); unthemable-glyph tools (eza, lazygit NFv3) take .color only; the prompt alone bins color.
  roles =
    families
    // {
      git = byName (map (t: {
          name = builtins.elemAt t 0;
          color = lib.getAttrFromPath (lib.splitString "." (builtins.elemAt t 1)) families;
          glyph = builtins.fromJSON ''"\u${builtins.elemAt t 2}"'';
          ascii = builtins.elemAt t 3;
        })
        fonts.catalog."Symbols Nerd Font Mono".gitAlphabet);
    };

  # Canonical hex->ANSI-16 assignment; terminal palettes and ANSI-slot consumers agree with truecolor consumers. Slot 4 carries a real blue,
  # slot 12 its bright companion, and both magenta slots ride the AA lift. Brights derive from the normal octet with the two real divergences
  # (brightBlack -> selection, brightBlue -> the dedicated bright row) as override rows.
  ansi16 = let
    base = {
      inherit (palette) red green yellow blue magenta cyan;
      black = palette.background;
      white = palette.foreground;
    };
  in
    base
    // lib.mapAttrs' (n: v: lib.nameValuePair "bright${lib.toUpper (builtins.substring 0 1 n)}${builtins.substring 1 99 n}" v)
    (base
      // {
        black = palette.selection;
        blue = palette.brightBlue;
      });

  # Master scope table: the one scope-to-role-to-hue pivot. tmTheme (bat, delta, yazi syntect), VS Code textMate + semantic tokens, and the nvim
  # treesitter projection all derive from these rows; `captures` names the treesitter side so a hue rebind lands everywhere with zero edits.
  # Rebinds vs stock Dracula: keyword->pink (AA), operator/punctuation->subtle, escape->orange, variable/parameter->blue (ends type==variable),
  # tag keeps magenta, warning splits to amber so a diagnostic is never a string. Row tuple: [name scope color style captures background].
  syntaxScopes = map (row ["name" "scope" "color" "style" "captures" "background"]) [
    ["Comment" "comment, punctuation.definition.comment" palette.comment "italic" ["comment"]]
    ["String" "string" palette.yellow null ["string" "character"]]
    ["Escape" "constant.character.escape" palette.orange null ["string.escape" "character.special"]]
    ["Number" "constant.numeric" palette.purple null ["number" "number.float"]]
    ["Constant" "constant.language, constant.character, constant.other" palette.purple null ["constant" "constant.builtin" "boolean"]]
    ["Keyword" "keyword, storage, storage.type, storage.modifier" palette.pink null ["keyword"]]
    ["Operator" "keyword.operator, punctuation.accessor" palette.subtle null ["operator" "keyword.operator"]]
    ["Punctuation" "punctuation" palette.subtle null ["punctuation.bracket" "punctuation.delimiter" "punctuation.special"]]
    ["Function" "entity.name.function, support.function" palette.green null ["function" "function.method" "function.macro" "function.builtin"]]
    ["Type" "entity.name.class, entity.name.type, entity.other.inherited-class, support.type, support.class" palette.cyan null ["type" "type.builtin" "constructor"]]
    ["Variable" "variable, support.variable" palette.blue null ["variable" "variable.member" "property"]]
    ["Parameter" "variable.parameter" palette.blue "italic" ["variable.parameter"]]
    ["Attribute" "entity.other.attribute-name" palette.magenta "italic" ["attribute"]]
    ["Tag" "entity.name.tag" palette.magenta null ["tag"]]
    ["Heading" "markup.heading" palette.purple "bold" ["markup.heading"]]
    ["Bold" "markup.bold" palette.orange "bold" ["markup.strong"]]
    ["Italic" "markup.italic" palette.yellow "italic" ["markup.italic"]]
    ["Link" "markup.underline.link" palette.blue null ["markup.link" "markup.link.url" "string.special.url"]]
    ["Inserted" "markup.inserted" palette.green null ["diff.plus"]]
    ["Deleted" "markup.deleted" palette.red null ["diff.minus"]]
    ["Invalid" "invalid" palette.foreground null [] palette.red]
  ];

  # Shared icon vocabulary: one directory/process glyph table projected into consumers (Yazi dirs; tab titles, prompts, and dashboards
  # adopt through their register rows) — never app-local maps. Dir row tuple: [name glyph color]. glyphsProved fails eval on any empty glyph:
  # the harness edit path can silently strip BMP private-use glyphs, and an empty glyph is a dead icon row every consumer renders as nothing.
  glyphsProved = v: let
    dead =
      lib.attrNames (lib.filterAttrs (_: r: r.glyph == "") v.dirs)
      ++ lib.attrNames (lib.filterAttrs (_: g: g == "") v.process);
  in
    if dead == []
    then v
    else throw "forge.theme.icons: empty glyph rows (harness strip?): ${lib.concatStringsSep ", " dead}";
  icons = glyphsProved {
    dirs = byName (map (row ["name" "glyph" "color"]) [
      [".git" "󰊢" palette.pink]
      ["node_modules" "󰏗" palette.green]
      ["target" "󰀘" palette.magenta]
      [".venv" "󰅩" palette.yellow]
      ["__pycache__" "󰌠" palette.yellow]
      [".config" "󰒓" palette.purple]
      [".ssh" "󰣀" palette.pink]
      ["src" "󰈙" palette.cyan]
      ["bin" "󰞰" palette.green]
    ]);
    process = {
      nvim = "";
      zsh = "󰆍";
      python = "󰌠";
      node = "󰎙";
      docker = "󰡨";
      ssh = "󰣀";
      git = "󰊢";
      nix = "󱄅";
      claude = "󰙴";
      container = builtins.fromJSON ''"\uf4b7"''; # oct-container: in-container rootfs, distinct from the docker-CLI whale
    };
    # Status alphabet: the CLOSED glyph vocabulary for terminal-bound render surfaces — single-codepoint codicons (Symbols Nerd Font Mono,
    # 1-cell advance proven at font install), each with the ASCII twin persisted surfaces use instead. Rows live on the symbols family
    # (fonts catalog statusAlphabet) so the hb-shape zero-.notdef gate proves the exact column these glyphs mint from; codepoint minting is
    # immune to harness glyph-stripping. Emoji and EAW-ambiguous glyphs never render on width-load-bearing surfaces; a new status class is
    # one catalog row, never an app-local glyph.
    alphabet = byName (map (t: {
        name = builtins.elemAt t 0;
        glyph = builtins.fromJSON ''"\u${builtins.elemAt t 1}"'';
        ascii = builtins.elemAt t 2;
      })
      fonts.catalog."Symbols Nerd Font Mono".statusAlphabet);
  };

  # --- [TARGET_REGISTRY]
  # One row per rendering consumer; verdicts: bound (interpolates owner tokens), gap (adoption pending), defer (no config surface to own).
  # coverage.json projects from these rows so gaps surface before drift. Row tuple: [id owner carrier binds verdict]; binds admits as a
  # space-joined token string and lands typed so JSON consumers never re-split.
  targets = let
    apps = "modules/home/programs/apps";
    st = "modules/home/programs/shell-tools";
    mkTarget = t: let
      r = row ["id" "owner" "carrier" "binds" "verdict"] t;
    in
      r // {binds = lib.optionals (r.binds != "-") (lib.splitString " " r.binds);};
  in
    map mkTarget [
      ["wezterm" "${apps}/wezterm/default.nix" "lua+toml" "roles ansi16 fonts badges" "bound"]
      ["zellij" "${apps}/zellij/config.nix" "kdl" "roles icons" "bound"]
      ["zellij-theme" "${apps}/zellij/themes/dracula.nix" "kdl" "palette" "bound"]
      ["yazi" "${apps}/yazi/theme.nix" "toml+tmTheme" "palette icons git badges" "bound"]
      ["nvim" "${apps}/nvim/default.nix" "lua" "roles palette scopes git" "bound"]
      ["bat" "${st}/bat.nix" "tmTheme" "scopes" "bound"]
      ["delta" "modules/home/programs/git-tools/git.nix" "gitconfig" "diff blameRamp git" "bound"]
      ["lazygit" "modules/home/programs/git-tools/lazygit.nix" "yaml" "palette git" "bound"]
      ["starship" "${st}/starship.nix" "toml" "roles palette icons git badges" "bound"]
      ["fzf" "${st}/fzf.nix" "env" "roles" "bound"]
      ["eza" "${st}/eza.nix" "yaml" "roles palette git" "bound"]
      ["fastfetch" "${st}/fastfetch.nix" "json" "roles fonts" "bound"]
      ["k9s" "modules/home/programs/container-tools/k9s.nix" "yaml" "roles palette" "bound"]
      ["atuin" "${st}/atuin.nix" "toml" "roles" "bound"]
      ["carbon" "${st}/carbon.nix" "json" "roles scopes fonts" "bound"]
      ["bottom" "${st}/bottom.nix" "toml" "roles palette" "bound"]
      ["procs" "${st}/procs.nix" "toml" "ansi16-slots" "bound"]
      ["jnv" "${st}/jnv.nix" "flags" "roles palette" "bound"]
      ["pik" "${st}/pik.nix" "toml" "roles" "bound"]
      ["trippy" "${st}/trippy.nix" "toml" "roles palette" "bound"]
      ["tlrc" "${st}/tlrc.nix" "toml" "palette" "bound"]
      ["ripgrep" "${st}/ripgrep.nix" "flags" "roles" "bound"]
      ["browsers" "${st}/browsers.nix" "toml" "roles" "bound"]
      ["posting" "${st}/posting.nix" "yaml" "roles palette" "bound"]
      ["process-compose" "${st}/process-compose.nix" "yaml" "roles palette" "bound"]
      ["mcp-cells" "${st}/mcp-launchers.nix" "zjstatus-pipe" "roles icons" "bound"]
      ["glow" "modules/home/programs/media-tools/glow.nix" "json" "-" "gap"]
      ["zsh-syntax-highlighting" "modules/home/programs/zsh" "env" "-" "gap"]
      ["zsh-autosuggestions" "modules/home/programs/zsh" "env" "-" "gap"]
      ["you-should-use" "modules/home/programs/zsh" "env" "-" "gap"]
      ["macos-accent" "modules/darwin/settings" "defaults" "-" "gap"]
      ["mermaid-html-studio" ".claude/skills" "css" "-" "gap"]
      ["wallpaper" "modules/home/assets/wallpaper" "bitmap" "-" "defer"]
      ["dock-controlcenter" "system-owned" "-" "-" "defer"]
    ];

  # Registry rows are proven at eval: every owner path must exist on disk, ids stay unique, and verdicts stay on the closed ladder, so a moved
  # consumer, a copy-pasted row, or a typo'd verdict breaks loudly. "system-owned" rows carry no file.
  targetsProved = let
    missing = builtins.filter (t: t.owner != "system-owned" && !builtins.pathExists (../.. + "/${t.owner}")) targets;
    dupes = lib.attrNames (lib.filterAttrs (_: c: c > 1) (lib.foldl' (acc: t: acc // {${t.id} = (acc.${t.id} or 0) + 1;}) {} targets));
    unruled = builtins.filter (t: !lib.elem t.verdict ["bound" "gap" "defer"]) targets;
  in
    if missing != []
    then throw "forge.theme.targets: owner paths missing on disk: ${lib.concatMapStringsSep ", " (t: "${t.id}=${t.owner}") missing}"
    else if dupes != []
    then throw "forge.theme.targets: duplicate target ids: ${lib.concatStringsSep ", " dupes}"
    else if unruled != []
    then throw "forge.theme.targets: verdicts off the bound|gap|defer ladder: ${lib.concatMapStringsSep ", " (t: "${t.id}=${t.verdict}") unruled}"
    else targets;

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

  # Global editor settings rows: [key role] pairs folded into the leading settings dict; scope rules follow from the master pivot.
  tmSetting = p: "        <key>${builtins.elemAt p 0}</key><string>${(builtins.elemAt p 1).hex}</string>";
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
    ${lib.concatMapStringsSep "\n" tmSetting [["background" roles.surface.base] ["foreground" roles.text.primary] ["caret" roles.text.primary] ["selection" roles.surface.selected] ["lineHighlight" roles.surface.raised] ["invisibles" roles.surface.selected] ["gutterForeground" roles.text.subtle] ["findHighlight" roles.ui.match] ["findHighlightForeground" roles.text.primary] ["misspelling" roles.state.danger]]}
          </dict>
        </dict>
    ${lib.concatMapStringsSep "\n" scopeRule syntaxScopes}
      </array>
    </dict>
    </plist>
  '';
  tmThemeFile = pkgs.writeText "forge-dracula.tmTheme" tmTheme;

  # Deep hex projection: a color record (any attrset carrying `hex`) collapses to its hex, every other leaf (glyphs, labels) passes through —
  # so a new role family lands in palette.json with zero edits here.
  project = v:
    if lib.isAttrs v && v ? hex
    then v.hex
    else if lib.isAttrs v
    then lib.mapAttrs (_: project) v
    else v;
  paletteJson = builtins.toJSON {
    palette = project palette;
    derived = project derived;
    roles = project roles;
    ansi16 = project ansi16;
    icons = project icons;
    syntax = map (row:
      {
        inherit (row) name scope captures;
        color = row.color.hex;
        style = row.style or "";
      }
      // lib.optionalAttrs (row ? background) {background = row.background.hex;})
    syntaxScopes;
  };

  # Base16/Base24 export adapter (Tinted scheme exchange); slot names derive from the ordered palette-row vector (base00..base17). The canonical
  # palette stays runtime truth; this is the ecosystem egress.
  base24Slots = lib.listToAttrs (lib.imap0 (
      i: p: lib.nameValuePair "base${lib.fixedWidthString 2 "0" (lib.toHexString i)}" palette.${p}
    ) (lib.splitString " "
      "background surface selection comment subtle foreground foreground foreground red orange yellow green cyan blue purple magenta crust crust red yellow green cyan brightBlue pink"));
  base24File = (pkgs.formats.yaml {}).generate "forge-base24.yaml" {
    system = "base24";
    name = "Forge Dracula";
    author = "Parametric Forge";
    variant = "dark";
    palette = lib.mapAttrs (_: c: lib.toLower (lib.removePrefix "#" c.hex)) base24Slots;
  };

  # --- [RENDERED_PROOF_BOARD]
  # palette.html: swatches, elevation ladder, fg tiers, ANSI-16, syntax scopes over a live sample, diff/search fills, git glyphs, and a WCAG
  # contrast matrix computed in the page against base/surface/overlay landings.
  paletteHtml = pkgs.writeText "forge-palette.html" ''
    <!doctype html><html><head><meta charset="utf-8"><title>Forge Theme Proof Board</title>
    <style>
      body{background:${palette.background.hex};color:${palette.foreground.hex};font:${fonts.projections.proofFont};margin:2rem;max-width:1100px}
      h1,h2{color:${palette.pink.hex};font-weight:700;text-transform:uppercase;letter-spacing:.08em}
      h2{color:${palette.cyan.hex};margin-top:2.5rem}
      table{border-collapse:collapse;width:100%;margin:.75rem 0}
      td,th{padding:.35rem .6rem;text-align:left;border-bottom:1px solid ${palette.current_line.hex}}
      th{color:${palette.subtle.hex};text-transform:uppercase;font-size:.75rem;letter-spacing:.08em}
      .sw{display:inline-block;width:2.4rem;height:1.2rem;border-radius:3px;vertical-align:middle;margin-right:.5rem}
      .chip{padding:.1rem .45rem;border-radius:3px;font-size:.75rem}
      .pass{background:${derived.diffAdd.hex};color:${palette.green.hex}}
      .park{background:${derived.search.hex};color:${palette.yellow.hex}}
      .fail{background:${derived.diffDel.hex};color:${palette.red.hex}}
      .muted{color:${palette.comment.hex}}
      pre{background:${palette.crust.hex};padding:1rem;border-radius:6px;overflow-x:auto}
    </style></head><body>
    <h1>Forge Theme Proof Board</h1>
    <p class="muted">Generated from modules/home/theme.nix — the estate palette owner. Contrast is computed live in this page (WCAG2 relative luminance).</p>
    <div id="root"></div>
    <script id="data" type="application/json">${paletteJson}</script>
    <script>
    var D=JSON.parse(document.getElementById('data').textContent);
    function lin(c){c/=255;return c<=0.04045?c/12.92:Math.pow((c+0.055)/1.055,2.4)}
    function lum(h){return 0.2126*lin(parseInt(h.slice(1,3),16))+0.7152*lin(parseInt(h.slice(3,5),16))+0.0722*lin(parseInt(h.slice(5,7),16))}
    function cr(f,b){var a=lum(f),c=lum(b),hi=Math.max(a,c),lo=Math.min(a,c);return (hi+0.05)/(lo+0.05)}
    function chip(r,floor){var cls=r>=floor?'pass':(r>=3?'park':'fail');return '<span class="chip '+cls+'">'+r.toFixed(2)+'</span>'}
    function sw(h){return '<span class="sw" style="background:'+h+'"></span>'+h}
    var out=[];
    out.push('<h2>Palette + Contrast Matrix</h2><table><tr><th>row</th><th>hex</th><th>vs base</th><th>vs surface</th><th>vs overlay</th></tr>');
    Object.keys(D.palette).forEach(function(k){var h=D.palette[k];
      out.push('<tr><td>'+k+'</td><td>'+sw(h)+'</td><td>'+chip(cr(h,D.palette.background),4.5)+'</td><td>'+chip(cr(h,D.palette.surface),4.5)+'</td><td>'+chip(cr(h,D.derived.overlay),4.5)+'</td></tr>')});
    out.push('</table><p class="muted">green = clears body AA (4.5), amber = parked 3.0-4.5 (non-text / by-design muted), red = below the non-text floor.</p>');
    out.push('<h2>Elevation Ladder</h2><div>');
    ['crust','background','surface','current_line'].forEach(function(k){out.push('<div style="background:'+D.palette[k]+';padding:.6rem 1rem">'+k+' '+D.palette[k]+'</div>')});
    out.push('<div style="background:'+D.derived.overlay+';padding:.6rem 1rem">overlay '+D.derived.overlay+'</div>');
    out.push('<div style="background:'+D.palette.selection+';padding:.6rem 1rem">selection '+D.palette.selection+'</div></div>');
    out.push('<h2>ANSI-16</h2><div>');
    Object.keys(D.ansi16).forEach(function(k){out.push('<span class="sw" title="'+k+'" style="background:'+D.ansi16[k]+';width:3.5rem;height:1.6rem"></span>')});
    out.push('</div>');
    out.push('<h2>Syntax Scopes</h2><table><tr><th>scope</th><th>hue</th><th>sample</th></tr>');
    D.syntax.forEach(function(s){out.push('<tr><td>'+s.name+'</td><td>'+sw(s.color)+'</td><td style="color:'+s.color+';font-style:'+(s.style.indexOf('italic')>=0?'italic':'normal')+';font-weight:'+(s.style.indexOf('bold')>=0?'700':'400')+'">'+('let '+s.name.toLowerCase()+' = shape(value)')+'</td></tr>')});
    out.push('</table>');
    out.push('<h2>Diff + Search Fills</h2>');
    [['diffAdd','+ inserted line'],['diffDel','− deleted line'],['diffChange','~ changed line'],['search','search match'],['searchCurrent','current match']].forEach(function(p){
      out.push('<div style="background:'+D.derived[p[0]]+';padding:.4rem 1rem">'+p[1]+' <span class="muted">fg holds neutral — '+cr(D.palette.foreground,D.derived[p[0]]).toFixed(1)+':1</span></div>')});
    out.push('<h2>Git States</h2><table><tr><th>state</th><th>glyph</th><th>ascii twin</th><th>hue</th></tr>');
    Object.keys(D.roles.git).forEach(function(k){var g=D.roles.git[k];out.push('<tr><td>'+k+'</td><td style="color:'+g.color+'">'+g.glyph+'</td><td class="muted">'+g.ascii+'</td><td>'+sw(g.color)+'</td></tr>')});
    out.push('</table>');
    out.push('<h2>Status Alphabet</h2><table><tr><th>role</th><th>glyph</th><th>ascii twin</th></tr>');
    Object.keys(D.icons.alphabet).forEach(function(k){var a=D.icons.alphabet[k];out.push('<tr><td>'+k+'</td><td>'+a.glyph+'</td><td class="muted">'+a.ascii+'</td></tr>')});
    out.push('</table>');
    document.getElementById('root').innerHTML=out.join(''');
    </script></body></html>
  '';

  receiptsFold = import ./programs/shell-tools/receipts.nix;

  # forge-theme-proof: the terminal-native proof lane. Renders every claim in the live renderer and stamps a dual receipt (source hash, geometry,
  # font, TERM) through the shared receipts fold; NO_COLOR=1 rerun is the strip test.
  forgeThemeProof = pkgs.writeShellApplication {
    name = "forge-theme-proof";
    runtimeInputs = [pkgs.jq pkgs.coreutils];
    text = ''
      p="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/theme/palette.json"
      f="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/manifest.json"
      receipt_log="''${FORGE_THEME_PROOF_RECEIPT_LOG:-$HOME/Library/Logs/forge-theme-proof.receipts.log}"
      receipt_surface="forge-theme-proof"
      ${receiptsFold}
      # Admission gate: the palette snapshot crosses once, shape-asserted — a missing or torn projection fails typed, never as an unbound-var crash.
      jq -e '(.palette | type == "object") and (.derived | type == "object")
        and (.roles.git | type == "object") and (.syntax | type == "array")' "$p" >/dev/null 2>&1 || {
        printf 'forge-theme-proof: palette projection missing or malformed: %s\n' "$p" >&2
        exit 66
      }
      hash="$(sha256sum "$p" | cut -c1-12)"
      font="$(jq -r '.roles.mono + " " + (.surfaces.terminal.size|tostring)' "$f" 2>/dev/null || true)"
      font="''${font:-unknown}"

      # One projection over the palette snapshot: color, syntax, git, and alphabet rows cross on a unit-separator rail; hex decodes in shell arithmetic.
      declare -A RGB HEX
      syntax_rows=()
      git_rows=()
      alpha_rows=()
      while IFS=$'\x1f' read -r kind key hex glyph twin; do # streaming boundary: typed row feed
        if [[ "$kind" == alpha ]]; then # alphabet rows carry glyph + ascii twin, never a hue
          alpha_rows+=("$key"$'\x1f'"$hex"$'\x1f'"$glyph")
          continue
        fi
        h="''${hex#\#}"
        rgb="$((16#''${h:0:2}));$((16#''${h:2:2}));$((16#''${h:4:2}))"
        case "$kind" in
          color)
            RGB[$key]="$rgb"
            HEX[$key]="$hex"
            ;;
          syntax) syntax_rows+=("$key"$'\x1f'"$rgb") ;;
          git) git_rows+=("$key"$'\x1f'"$rgb"$'\x1f'"$glyph"$'\x1f'"$twin") ;;
        esac
      done < <(jq -r '
        ((.palette | to_entries[] | ["color", "palette.\(.key)", .value, "", ""]),
         (.derived | to_entries[] | ["color", "derived.\(.key)", .value, "", ""]),
         (.syntax[] | ["syntax", .name, .color, "", ""]),
         (.roles.git | to_entries[] | ["git", .key, .value.color, .value.glyph, .value.ascii]),
         (.icons.alphabet | to_entries[] | ["alpha", .key, .value.glyph, .value.ascii, ""]))
        | join("\u001f")' "$p")

      esc() { printf '\033[%sm' "$1"; }
      if [[ -n "''${NO_COLOR:-}" ]]; then
        esc() { :; }
      fi
      fg() { printf '38;2;%s' "''${RGB[$1]}"; }
      bg() { printf '48;2;%s' "''${RGB[$1]}"; }
      r() { esc 0; }
      printf '\n%s[FORGE-THEME-PROOF]%s src=%s geometry=%sx%s font="%s" term=%s\n\n' \
        "$(esc "$(fg palette.pink);1")" "$(r)" "$hash" "''${COLUMNS:-?}" "''${LINES:-?}" "$font" "''${TERM_PROGRAM:-$TERM}"
      printf '%s[SURFACE_LADDER]%s\n' "$(esc "$(fg palette.cyan);1")" "$(r)"
      for row in crust background surface current_line selection; do
        printf '  %s %-14s %s\n' "$(esc "$(bg "palette.$row")")        $(r)" "$row" "''${HEX[palette.$row]}"
      done
      printf '  %s %-14s %s\n\n' "$(esc "$(bg derived.overlay)")        $(r)" "overlay" "''${HEX[derived.overlay]}"
      printf '%s[FG_TIERS]%s ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      printf '%sprimary%s %ssubtle%s %smuted%s\n\n' \
        "$(esc "$(fg palette.foreground)")" "$(r)" "$(esc "$(fg palette.subtle)")" "$(r)" "$(esc "$(fg palette.comment)")" "$(r)"
      printf '%s[ANSI16]%s\n  ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      for i in 0 1 2 3 4 5 6 7; do printf '%s  %s' "$(esc "4$i")" "$(r)"; done
      printf '\n  '
      for i in 0 1 2 3 4 5 6 7; do printf '%s  %s' "$(esc "10$i")" "$(r)"; done
      printf '\n\n%s[SEMANTIC]%s ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      printf '%sok%s %swarn%s %sattention%s %sdanger%s %sinfo%s\n\n' \
        "$(esc "$(fg palette.green)")" "$(r)" "$(esc "$(fg palette.amber)")" "$(r)" \
        "$(esc "$(fg palette.orange)")" "$(r)" "$(esc "$(fg palette.red)")" "$(r)" "$(esc "$(fg palette.blue)")" "$(r)"
      printf '%s[SYNTAX]%s\n' "$(esc "$(fg palette.cyan);1")" "$(r)"
      {
        for row in "''${syntax_rows[@]}"; do
          IFS=$'\x1f' read -r name rgb <<<"$row"
          printf '  %s%-12s%s' "$(esc "38;2;$rgb")" "$name" "$(r)"
        done
        printf '\n'
      } | fold -w "''${COLUMNS:-100}" -s
      printf '\n%s[DIFF_FILLS]%s\n' "$(esc "$(fg palette.cyan);1")" "$(r)"
      for pair in "diffAdd:+ inserted" "diffDel:- deleted" "diffChange:~ changed" "search:search match" "searchCurrent:current match"; do
        printf '  %s %s %s\n' "$(esc "$(bg "derived.''${pair%%:*}");$(fg palette.foreground)")" "''${pair#*:}" "$(r)"
      done
      printf '\n%s[GIT]%s ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      for row in "''${git_rows[@]}"; do
        IFS=$'\x1f' read -r k rgb glyph twin <<<"$row"
        printf '%s%s %s%s %s%s%s  ' "$(esc "38;2;$rgb")" "$glyph" "$k" "$(r)" "$(esc "$(fg palette.comment)")" "$twin" "$(r)"
      done
      printf '\n\n%s[ALPHABET]%s ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      for row in "''${alpha_rows[@]}"; do
        IFS=$'\x1f' read -r k glyph twin <<<"$row"
        printf '%s %s %s%s%s  ' "$glyph" "$k" "$(esc "$(fg palette.comment)")" "$twin" "$(r)"
      done
      printf '\n\n'
      TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
      receipt="$(printf 'ts=%s\tartifact=terminal\trenderer=%s\tfont=%s\tgeometry=%sx%s\thash=%s\tresult=ok' \
        "$ts" "''${TERM_PROGRAM:-$TERM}" "$font" "''${COLUMNS:-?}" "''${LINES:-?}" "$hash")"
      # An unwritable log must never mask a rendered proof.
      append_receipt "$receipt" \
        || printf 'forge-theme-proof: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
    '';
  };

  fzfColorRows = [
    "--color=fg:${roles.text.primary.hex},fg+:${roles.text.inverse.hex},bg:${roles.surface.base.hex},bg+:${roles.focus.active.hex},selected-fg:${roles.text.inverse.hex},selected-bg:${roles.focus.active.hex}"
    "--color=hl:${roles.state.success.hex},hl+:${roles.accent.secondary.hex},info:${roles.text.muted.hex},marker:${roles.state.success.hex}"
    "--color=prompt:${roles.accent.secondary.hex},spinner:${roles.state.success.hex},pointer:${roles.accent.secondary.hex},header:${roles.text.muted.hex}"
    "--color=gutter:${roles.surface.base.hex},border:${roles.accent.primary.hex},separator:${roles.accent.tertiary.hex},scrollbar:${roles.accent.tertiary.hex}"
    "--color=preview-fg:${roles.text.primary.hex},preview-scrollbar:${roles.accent.tertiary.hex},label:${roles.accent.secondary.hex},query:${roles.text.primary.hex}"
  ];

  projections = {
    inherit tmThemeFile;
    # Flat hex mirror of the role families hex-projection consumers (VS Code, nvim, wezterm Lua rows) actually index; focus and mode stay Nix-side
    # deliberately — no hex consumer reads them, and palette.json already carries the full tree. A new family lands here with its first consumer.
    rolesHex = lib.mapAttrs (_: lib.mapAttrs (_: c: c.hex)) {inherit (roles) surface text accent state diff ui;};
    # Git-state vocabulary rows (hex + both registers); terminal-bound consumers render .glyph, persisted/piped surfaces render .ascii, every
    # consumer takes .color from the same row.
    gitHex =
      lib.mapAttrs (_: g: {
        color = g.color.hex;
        inherit (g) glyph ascii;
      })
      roles.git;
    # Cross-surface machine-context badges (remote host, in-container rootfs): the roles.git single-owner pattern applied to context — each row
    # carries the glyph, the dotted role path, and the resolved hex (.color, the gitHex field grammar), so prompt, wezterm strip, and yazi header
    # render one identical badge per class. Row tuple: [processIcon rolePath].
    contextBadges =
      lib.mapAttrs (_: t: rec {
        glyph = icons.process.${builtins.elemAt t 0};
        role = builtins.elemAt t 1;
        color = (lib.getAttrFromPath (lib.splitString "." role) roles).hex;
      }) {
        remote = ["ssh" "state.warning"];
        container = ["container" "accent.structural"];
      };
    # Lua return-table behind the generated Neovim palette; derived fills ride along snake_cased for highlight consumers.
    luaPalette = ''
      -- Generated from the Forge theme owner (modules/home/theme.nix).
      return {
      ${lib.concatStrings (lib.mapAttrsToList (name: c: "  [\"${name}\"] = \"${c.hex}\",\n") palette)}${lib.concatStrings (lib.mapAttrsToList (name: c: "  [\"${name}\"] = \"${c.hex}\",\n") derived)}}
    '';
    # WezTerm color-scheme rows in the colors-TOML shape; the tab bar sits on the surface step and inactive chrome reads through the subtle tier.
    # Label quads and tab rows fold from [bg fg] pairs; ANSI vectors derive from the slot-name order.
    weztermColorScheme = let
      labeled = lib.concatMapAttrs (n: p: {
        "${n}_bg" = {Color = (builtins.elemAt p 0).hex;};
        "${n}_fg" = {Color = (builtins.elemAt p 1).hex;};
      });
      tab = bg: fg: {
        bg_color = bg.hex;
        fg_color = fg.hex;
      };
      slots = map (k: ansi16.${k}.hex);
    in
      lib.mapAttrs (_: c: c.hex) (pairs [["foreground" palette.foreground] ["background" palette.background] ["cursor_bg" palette.foreground] ["cursor_fg" palette.background] ["cursor_border" palette.foreground] ["selection_fg" palette.foreground] ["selection_bg" palette.selection] ["split" palette.subtle]])
      // {
        ansi = slots ["black" "red" "green" "yellow" "blue" "magenta" "cyan" "white"];
        brights = slots ["brightBlack" "brightRed" "brightGreen" "brightYellow" "brightBlue" "brightMagenta" "brightCyan" "brightWhite"];
        tab_bar = {
          background = roles.surface.surface.hex;
          active_tab = tab roles.accent.primary roles.text.inverse;
          inactive_tab = tab roles.surface.surface roles.text.subtle;
          inactive_tab_hover = tab roles.surface.raised roles.text.primary;
          new_tab = tab roles.surface.surface roles.text.subtle;
          new_tab_hover = tab roles.surface.raised roles.text.primary;
        };
      }
      // labeled {
        quick_select_label = [roles.state.attention roles.text.inverse];
        quick_select_match = [roles.surface.selected roles.text.primary];
        input_selector_label = [roles.surface.raised roles.accent.primary];
        launcher_label = [roles.surface.raised roles.accent.primary];
      };
    # Display-time grammar: transient/human surfaces render these strftime rows (24h local, no seconds, no tz); stored data stays ISO-8601 UTC.
    timeDisplay = {
      sameDay = "%H:%M";
      dated = "%d/%m %H:%M";
    };
    # fzf color vocabulary: the ONE role->slot mapping every fzf-embedding surface consumes (programs.fzf, register browsers, ops pickers).
    # Selection rides the focus pair, structure rides accents — a picker's selected row reads identically to the active tab chip estate-wide.
    inherit fzfColorRows;
    # Per-command fzf argument vocabulary: colors plus the chrome every generated script carries per invocation (scripts never assume the
    # interactive FZF_DEFAULT_OPTS reached them); the richer global interactive chrome stays fzf.nix-owned.
    fzfArgs = fzfColorRows ++ ["--border=sharp" "--layout=reverse" "--info=right" "--highlight-line" "--prompt=❯ " "--pointer=❯"];
    # Four-step surface ramp for delta blame backgrounds.
    blameRamp = lib.concatMapStringsSep " " (c: c.hex) [
      roles.surface.base
      roles.surface.raised
      roles.surface.overlay
      roles.surface.selected
    ];
  };
in {
  options.forge.theme = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit palette derived roles ansi16 syntaxScopes icons projections;
      targets = targetsProved;
    };
    description = "Estate palette owner: enriched Dracula tokens, roles, ANSI-16, registry, projections.";
  };

  config = {
    home.packages = [forgeThemeProof];

    # Machine-readable projections for consumers outside Home Manager, the ecosystem exchange adapter, the proof board, and the coverage ledger.
    xdg.configFile = {
      "forge/theme/palette.json".text = paletteJson;
      "forge/theme/forge-dracula.tmTheme".source = tmThemeFile;
      "forge/theme/base24.yaml".source = base24File;
      "forge/theme/palette.html".source = paletteHtml;
      "forge/theme/coverage.json".text = builtins.toJSON {
        schema = "forge-theme-coverage/v1";
        targets = targetsProved;
      };
    };
  };
}
