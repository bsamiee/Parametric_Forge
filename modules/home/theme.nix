# Title         : theme.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/theme.nix
# ----------------------------------------------------------------------------
# Estate palette owner: enriched Dracula-variant rows, semantic roles, ANSI-16
# projection, the master syntax scope table (tmTheme, treesitter, textMate,
# and semantic tokens project from one pivot), derived diff/search/git roles,
# the shared icon vocabulary, the target registry with coverage and closeout
# projections, and the rendered proof lane. Every color consumer interpolates
# these tokens; no consumer carries a private hex.
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

  # Enriched palette: the canonical rows plus the design-language growth —
  # crust/surface complete the elevation ladder, subtle is the third fg tier
  # and the structural-UI hue, amber splits warning from string-yellow, blue
  # ends the faked ANSI blue, brightBlue ends blue==cyan. current_line is
  # retuned (chroma pulled to kill the muddy active line) and magenta is
  # AA-lifted; every row is contrast-verified against the base.
  palette = lib.mapAttrs (_: mkColor) {
    crust = "#0E0D16";
    background = "#15131F";
    surface = "#201E30";
    current_line = "#2A2A3A";
    selection = "#44475A";
    foreground = "#F8F8F2";
    subtle = "#8E91A5";
    comment = "#6272A4";
    purple = "#A072C6";
    cyan = "#94F2E8";
    green = "#50FA7B";
    yellow = "#F1FA8C";
    amber = "#F3AE51";
    orange = "#F97359";
    red = "#FF5555";
    magenta = "#EE55A8";
    pink = "#E98FBE";
    blue = "#7AA2F7";
    brightBlue = "#A9C7FF";
  };

  # Derived roles: computed fills, never palette rows. Diff and search tint
  # the background and hold the code foreground neutral (fg clears 7.7+ on
  # every fill); emphasis is the same hue at +0.06 OKLCH L.
  derived = lib.mapAttrs (_: mkColor) {
    overlay = "#37364D";
    diffAdd = "#122A18";
    diffAddEmph = "#213926";
    diffDel = "#3B1818";
    diffDelEmph = "#4C2726";
    diffChange = "#152539";
    diffChangeEmph = "#233449";
    search = "#3A3418";
    searchCurrent = "#5A4E1E";
  };

  roles = {
    surface = {
      inherit (palette) crust surface;
      base = palette.background;
      raised = palette.current_line;
      inherit (derived) overlay;
      selected = palette.selection;
    };
    text = {
      primary = palette.foreground;
      inherit (palette) subtle;
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
      warning = palette.amber;
      attention = palette.orange;
      danger = palette.red;
      info = palette.blue;
    };
    diff = {
      add = derived.diffAdd;
      addEmph = derived.diffAddEmph;
      del = derived.diffDel;
      delEmph = derived.diffDelEmph;
      change = derived.diffChange;
      changeEmph = derived.diffChangeEmph;
    };
    # Git states carry a redundant glyph so meaning never rides hue alone.
    git = {
      added = {
        color = palette.green;
        glyph = "+";
      };
      staged = {
        color = palette.green;
        glyph = "●";
      };
      modified = {
        color = palette.blue;
        glyph = "~";
      };
      deleted = {
        color = palette.red;
        glyph = "−";
      };
      untracked = {
        color = palette.subtle;
        glyph = "?";
      };
      renamed = {
        color = palette.purple;
        glyph = "»";
      };
      conflict = {
        color = palette.magenta;
        glyph = "!";
      };
    };
    ui = {
      border = palette.subtle;
      cursor = palette.foreground;
      indent = palette.subtle;
      whitespace = palette.selection;
      inherit (derived) search;
      match = derived.searchCurrent;
    };
  };

  # Canonical hex->ANSI-16 assignment; terminal palettes and ANSI-slot
  # consumers agree with truecolor consumers. Slot 4 carries a real blue,
  # slot 12 its bright companion, and both magenta slots ride the AA lift.
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

  # Master scope table: the one scope-to-role-to-hue pivot. tmTheme (bat,
  # delta, yazi syntect), VS Code textMate + semantic tokens, and the nvim
  # treesitter projection all derive from these rows; `captures` names the
  # treesitter side so a hue rebind lands everywhere with zero edits.
  # Rebinds vs stock Dracula: keyword->pink (AA), operator/punctuation->subtle,
  # escape->orange, variable/parameter->blue (ends type==variable), tag keeps
  # magenta, warning splits to amber so a diagnostic is never a string.
  syntaxScopes = [
    {
      name = "Comment";
      scope = "comment, punctuation.definition.comment";
      color = palette.comment;
      style = "italic";
      captures = ["comment"];
    }
    {
      name = "String";
      scope = "string";
      color = palette.yellow;
      captures = ["string" "character"];
    }
    {
      name = "Escape";
      scope = "constant.character.escape";
      color = palette.orange;
      captures = ["string.escape" "character.special"];
    }
    {
      name = "Number";
      scope = "constant.numeric";
      color = palette.purple;
      captures = ["number" "number.float"];
    }
    {
      name = "Constant";
      scope = "constant.language, constant.character, constant.other";
      color = palette.purple;
      captures = ["constant" "constant.builtin" "boolean"];
    }
    {
      name = "Keyword";
      scope = "keyword, storage, storage.type, storage.modifier";
      color = palette.pink;
      captures = ["keyword"];
    }
    {
      name = "Operator";
      scope = "keyword.operator, punctuation.accessor";
      color = palette.subtle;
      captures = ["operator" "keyword.operator"];
    }
    {
      name = "Punctuation";
      scope = "punctuation";
      color = palette.subtle;
      captures = ["punctuation.bracket" "punctuation.delimiter" "punctuation.special"];
    }
    {
      name = "Function";
      scope = "entity.name.function, support.function";
      color = palette.green;
      captures = ["function" "function.method" "function.macro" "function.builtin"];
    }
    {
      name = "Type";
      scope = "entity.name.class, entity.name.type, entity.other.inherited-class, support.type, support.class";
      color = palette.cyan;
      captures = ["type" "type.builtin" "constructor"];
    }
    {
      name = "Variable";
      scope = "variable, support.variable";
      color = palette.blue;
      captures = ["variable" "variable.member" "property"];
    }
    {
      name = "Parameter";
      scope = "variable.parameter";
      color = palette.blue;
      style = "italic";
      captures = ["variable.parameter"];
    }
    {
      name = "Attribute";
      scope = "entity.other.attribute-name";
      color = palette.magenta;
      style = "italic";
      captures = ["attribute"];
    }
    {
      name = "Tag";
      scope = "entity.name.tag";
      color = palette.magenta;
      captures = ["tag"];
    }
    {
      name = "Heading";
      scope = "markup.heading";
      color = palette.purple;
      style = "bold";
      captures = ["markup.heading"];
    }
    {
      name = "Bold";
      scope = "markup.bold";
      color = palette.orange;
      style = "bold";
      captures = ["markup.strong"];
    }
    {
      name = "Italic";
      scope = "markup.italic";
      color = palette.yellow;
      style = "italic";
      captures = ["markup.italic"];
    }
    {
      name = "Link";
      scope = "markup.underline.link";
      color = palette.blue;
      captures = ["markup.link" "markup.link.url" "string.special.url"];
    }
    {
      name = "Inserted";
      scope = "markup.inserted";
      color = palette.green;
      captures = ["diff.plus"];
    }
    {
      name = "Deleted";
      scope = "markup.deleted";
      color = palette.red;
      captures = ["diff.minus"];
    }
    {
      name = "Invalid";
      scope = "invalid";
      color = palette.foreground;
      background = palette.red;
      captures = [];
    }
  ];

  # Semantic-token projection: language-server styling VS Code textMate rules
  # miss. Same pivot hues; modifiers express sub-distinction, never new hues.
  semanticRules = {
    namespace = palette.cyan.hex;
    class = palette.cyan.hex;
    enum = palette.cyan.hex;
    interface = palette.cyan.hex;
    struct = palette.cyan.hex;
    type = palette.cyan.hex;
    typeParameter = palette.cyan.hex;
    function = palette.green.hex;
    method = palette.green.hex;
    macro = palette.green.hex;
    parameter = {
      foreground = palette.blue.hex;
      fontStyle = "italic";
    };
    variable = palette.blue.hex;
    property = palette.blue.hex;
    enumMember = palette.purple.hex;
    "variable.readonly" = palette.purple.hex;
    keyword = palette.pink.hex;
    string = palette.yellow.hex;
    number = palette.purple.hex;
    comment = {
      foreground = palette.comment.hex;
      fontStyle = "italic";
    };
    decorator = palette.magenta.hex;
    operator = palette.subtle.hex;
  };

  # Shared icon vocabulary: one directory/process glyph table projected into
  # consumers (Yazi dirs today; tab titles, prompts, and dashboards adopt
  # through their register rows) — never app-local maps.
  icons = {
    dirs = {
      ".git" = {
        glyph = "󰊢";
        color = palette.pink;
      };
      node_modules = {
        glyph = "󰏗";
        color = palette.green;
      };
      target = {
        glyph = "󰀘";
        color = palette.magenta;
      };
      ".venv" = {
        glyph = "󰅩";
        color = palette.yellow;
      };
      __pycache__ = {
        glyph = "󰌠";
        color = palette.yellow;
      };
      ".config" = {
        glyph = "";
        color = palette.purple;
      };
      ".ssh" = {
        glyph = "";
        color = palette.pink;
      };
      src = {
        glyph = "󰈙";
        color = palette.cyan;
      };
      bin = {
        glyph = "󰞰";
        color = palette.green;
      };
    };
    process = {
      nvim = "";
      zsh = "";
      python = "󰌠";
      node = "";
      docker = "󰡨";
      ssh = "󰣀";
      git = "󰊢";
      nix = "󱄅";
      claude = "✳";
    };
  };

  # --- Target registry: the Stylix-class capability matrix ---------------------
  # One row per rendering consumer; verdicts: bound (interpolates owner
  # tokens), gap (adoption pending), defer (no config surface to own).
  # Coverage and the AESTHETIC-CLOSEOUT phase-1 register project from these
  # rows so projection gaps surface before drift.
  targets = let
    row = id: owner: carrier: binds: verdict: {inherit id owner carrier binds verdict;};
    apps = "modules/home/programs/apps";
    st = "modules/home/programs/shell-tools";
  in [
    (row "wezterm" "${apps}/wezterm/default.nix" "lua+toml" "roles ansi16 fonts" "bound")
    (row "zellij" "${apps}/zellij/config.nix" "kdl" "palette roles" "bound")
    (row "zellij-theme" "${apps}/zellij/themes/dracula.nix" "kdl" "palette" "bound")
    (row "yazi" "${apps}/yazi/theme.nix" "toml+tmTheme" "palette icons" "bound")
    (row "nvim" "${apps}/nvim/default.nix" "lua" "palette scopes roles" "bound")
    (row "vscode" "${apps}/vscode/default.nix" "jsonc-sentinel" "ansi16 scopes semantic fonts" "bound")
    (row "bat" "${st}/bat.nix" "tmTheme" "scopes" "bound")
    (row "delta" "modules/home/programs/git-tools/git.nix" "gitconfig" "ansi16 diff blameRamp" "bound")
    (row "lazygit" "modules/home/programs/git-tools/lazygit.nix" "yaml" "palette" "bound")
    (row "starship" "${st}/starship.nix" "toml" "palette" "bound")
    (row "fzf" "${st}/fzf.nix" "env" "palette" "bound")
    (row "eza" "${st}/eza.nix" "yaml" "palette" "bound")
    (row "fastfetch" "${st}/fastfetch.nix" "json" "palette fonts" "bound")
    (row "k9s" "modules/home/programs/container-tools/k9s.nix" "yaml" "roles" "bound")
    (row "atuin" "${st}/atuin.nix" "toml" "palette" "bound")
    (row "carbon" "${st}/carbon.nix" "json" "scopes fonts" "bound")
    (row "bottom" "${st}/bottom.nix" "toml" "palette" "bound")
    (row "procs" "${st}/procs.nix" "toml" "ansi16" "bound")
    (row "jnv" "${st}/jnv.nix" "flags" "palette" "bound")
    (row "pik" "${st}/pik.nix" "toml" "palette" "bound")
    (row "trippy" "${st}/trippy.nix" "toml" "palette" "bound")
    (row "tlrc" "${st}/tlrc.nix" "toml" "palette" "bound")
    (row "ripgrep" "${st}/ripgrep.nix" "flags" "palette" "bound")
    (row "browsers" "${st}/browsers.nix" "toml" "palette" "bound")
    (row "posting" "${st}/posting.nix" "yaml" "palette" "bound")
    (row "process-compose" "${st}/process-compose.nix" "yaml" "palette" "bound")
    (row "mcp-cells" "${st}/mcp-launchers.nix" "zjstatus-pipe" "roles" "bound")
    (row "glow" "${st}/glow.nix" "json" "-" "gap")
    (row "zsh-syntax-highlighting" "modules/home/programs/zsh" "env" "-" "gap")
    (row "zsh-autosuggestions" "modules/home/programs/zsh" "env" "-" "gap")
    (row "you-should-use" "modules/home/programs/zsh" "env" "-" "gap")
    (row "macos-accent" "modules/darwin/settings" "defaults" "-" "gap")
    (row "mermaid-html-studio" ".claude/skills" "css" "-" "gap")
    (row "wallpaper" "modules/home/assets/wallpaper" "bitmap" "-" "defer")
    (row "dock-controlcenter" "system-owned" "-" "-" "defer")
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
            <key>gutterForeground</key><string>${roles.text.subtle.hex}</string>
            <key>findHighlight</key><string>${roles.ui.match.hex}</string>
            <key>findHighlightForeground</key><string>${roles.text.primary.hex}</string>
            <key>misspelling</key><string>${roles.state.danger.hex}</string>
          </dict>
        </dict>
    ${lib.concatMapStringsSep "\n" scopeRule syntaxScopes}
      </array>
    </dict>
    </plist>
  '';
  tmThemeFile = pkgs.writeText "forge-dracula.tmTheme" tmTheme;

  hexOnly = lib.mapAttrs (_: c: c.hex);
  paletteJson = builtins.toJSON {
    palette = hexOnly palette;
    derived = hexOnly derived;
    roles =
      lib.mapAttrs (_: lib.mapAttrs (_: c: c.hex))
      {inherit (roles) surface text accent state diff ui;}
      // {
        git =
          lib.mapAttrs (_: g: {
            color = g.color.hex;
            inherit (g) glyph;
          })
          roles.git;
      };
    ansi16 = hexOnly ansi16;
    syntax =
      map (row: {
        inherit (row) name scope captures;
        color = row.color.hex;
        style = row.style or "";
      })
      syntaxScopes;
  };

  # Base16/Base24 export adapter (Tinted scheme exchange); the canonical
  # palette stays runtime truth, this is the ecosystem egress.
  base24Slots = {
    base00 = palette.background;
    base01 = palette.surface;
    base02 = palette.selection;
    base03 = palette.comment;
    base04 = palette.subtle;
    base05 = palette.foreground;
    base06 = palette.foreground;
    base07 = palette.foreground;
    base08 = palette.red;
    base09 = palette.orange;
    base0A = palette.yellow;
    base0B = palette.green;
    base0C = palette.cyan;
    base0D = palette.blue;
    base0E = palette.purple;
    base0F = palette.magenta;
    base10 = palette.crust;
    base11 = palette.crust;
    base12 = palette.red;
    base13 = palette.yellow;
    base14 = palette.green;
    base15 = palette.cyan;
    base16 = palette.brightBlue;
    base17 = palette.pink;
  };
  base24Yaml = ''
    system: "base24"
    name: "Forge Dracula"
    author: "Parametric Forge"
    variant: "dark"
    palette:
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (slot: c: "  ${slot}: \"${lib.toLower (lib.removePrefix "#" c.hex)}\"") base24Slots)}
  '';

  # --- Rendered proof board -----------------------------------------------------
  # palette.html: swatches, elevation ladder, fg tiers, ANSI-16, syntax scopes
  # over a live sample, diff/search fills, git glyphs, and a WCAG contrast
  # matrix computed in the page against base/surface/overlay landings.
  paletteHtml = pkgs.writeText "forge-palette.html" ''
    <!doctype html><html><head><meta charset="utf-8"><title>Forge Theme Proof Board</title>
    <style>
      body{background:${palette.background.hex};color:${palette.foreground.hex};font:14px/1.5 "Geist Mono",monospace;margin:2rem;max-width:1100px}
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
    out.push('<h2>Git States</h2><table><tr><th>state</th><th>glyph</th><th>hue</th></tr>');
    Object.keys(D.roles.git).forEach(function(k){var g=D.roles.git[k];out.push('<tr><td>'+k+'</td><td style="color:'+g.color+'">'+g.glyph+'</td><td>'+sw(g.color)+'</td></tr>')});
    out.push('</table>');
    document.getElementById('root').innerHTML=out.join(''');
    </script></body></html>
  '';

  # forge-theme-proof: the terminal-native proof lane. Renders every claim in
  # the live renderer and stamps a receipt (source hash, geometry, font,
  # TERM); NO_COLOR=1 rerun is the strip test.
  forgeThemeProof = pkgs.writeShellApplication {
    name = "forge-theme-proof";
    runtimeInputs = [pkgs.jq pkgs.coreutils];
    text = ''
      p="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/theme/palette.json"
      f="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/manifest.json"
      hash="$(sha256sum "$p" | cut -c1-12)"
      font="$(jq -r '.roles.mono + " " + (.metrics.size|tostring)' "$f" 2>/dev/null || echo unknown)"
      esc() { printf '\033[%sm' "$1"; }
      fg() { jq -r ".$1" "$p" | sed 's/#//' | { read -r h; printf '38;2;%d;%d;%d' "0x''${h:0:2}" "0x''${h:2:2}" "0x''${h:4:2}"; }; }
      bg() { jq -r ".$1" "$p" | sed 's/#//' | { read -r h; printf '48;2;%d;%d;%d' "0x''${h:0:2}" "0x''${h:2:2}" "0x''${h:4:2}"; }; }
      r() { esc 0; }
      if [[ -n "''${NO_COLOR:-}" ]]; then
        esc() { :; }
      fi
      printf '\n%s[FORGE-THEME-PROOF]%s src=%s geometry=%sx%s font="%s" term=%s\n\n' \
        "$(esc "$(fg palette.pink);1")" "$(r)" "$hash" "''${COLUMNS:-?}" "''${LINES:-?}" "$font" "''${TERM_PROGRAM:-$TERM}"
      printf '%s[SURFACE_LADDER]%s\n' "$(esc "$(fg palette.cyan);1")" "$(r)"
      for row in crust background surface current_line selection; do
        printf '  %s %-14s %s %s\n' "$(esc "$(bg "palette.$row")")        " "$(r) $row" "$(jq -r ".palette.$row" "$p")" ""
      done
      printf '  %s %-14s %s\n\n' "$(esc "$(bg derived.overlay)")        " "$(r) overlay" "$(jq -r '.derived.overlay' "$p")"
      printf '%s[FG_TIERS]%s ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      printf '%sprimary%s %ssubtle%s %smuted%s\n\n' \
        "$(esc "$(fg palette.foreground)")" "$(r)" "$(esc "$(fg palette.subtle)")" "$(r)" "$(esc "$(fg palette.comment)")" "$(r)"
      printf '%s[ANSI16]%s\n  ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      for i in 0 1 2 3 4 5 6 7; do printf '\033[4%sm  \033[0m' "$i"; done
      printf '\n  '
      for i in 0 1 2 3 4 5 6 7; do printf '\033[10%sm  \033[0m' "$i"; done
      printf '\n\n%s[SEMANTIC]%s ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      printf '%sok%s %swarn%s %sattention%s %sdanger%s %sinfo%s\n\n' \
        "$(esc "$(fg palette.green)")" "$(r)" "$(esc "$(fg palette.amber)")" "$(r)" \
        "$(esc "$(fg palette.orange)")" "$(r)" "$(esc "$(fg palette.red)")" "$(r)" "$(esc "$(fg palette.blue)")" "$(r)"
      printf '%s[SYNTAX]%s\n' "$(esc "$(fg palette.cyan);1")" "$(r)"
      jq -r '.syntax[] | [.name, .color] | @tsv' "$p" | while IFS=$'\t' read -r name hex; do
        h="''${hex#\#}"
        printf '  \033[38;2;%d;%d;%dm%-12s\033[0m' "0x''${h:0:2}" "0x''${h:2:2}" "0x''${h:4:2}" "$name"
      done | fold -w "''${COLUMNS:-100}" -s
      printf '\n\n%s[DIFF_FILLS]%s\n' "$(esc "$(fg palette.cyan);1")" "$(r)"
      for pair in "diffAdd:+ inserted" "diffDel:− deleted" "diffChange:~ changed" "search:search match" "searchCurrent:current match"; do
        printf '  %s %s %s\n' "$(esc "$(bg "derived.''${pair%%:*}");$(fg palette.foreground)")" "''${pair#*:}" "$(r)"
      done
      printf '\n%s[GIT]%s ' "$(esc "$(fg palette.cyan);1")" "$(r)"
      jq -r '.roles.git | to_entries[] | [.key, .value.color, .value.glyph] | @tsv' "$p" | while IFS=$'\t' read -r k hex glyph; do
        h="''${hex#\#}"
        printf '\033[38;2;%d;%d;%dm%s %s\033[0m  ' "0x''${h:0:2}" "0x''${h:2:2}" "0x''${h:4:2}" "$glyph" "$k"
      done
      printf '\n\n'
      ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      mkdir -p "$HOME/Library/Logs"
      printf 'ts=%s\towner=forge-theme-proof\tartifact=terminal\trenderer=%s\tfont=%s\tgeometry=%sx%s\thash=%s\n' \
        "$ts" "''${TERM_PROGRAM:-$TERM}" "$font" "''${COLUMNS:-?}" "''${LINES:-?}" "$hash" \
        >>"$HOME/Library/Logs/forge-theme-proof.receipts.log"
    '';
  };

  projections = {
    inherit tmThemeFile;
    # Lua return-table shared by WezTerm and Neovim generated palettes;
    # derived fills ride along snake_cased for highlight consumers.
    luaPalette = ''
      -- Generated from the Forge theme owner (modules/home/theme.nix).
      return {
      ${lib.concatStrings (lib.mapAttrsToList (name: c: "  [\"${name}\"] = \"${c.hex}\",\n") palette)}${lib.concatStrings (lib.mapAttrsToList (name: c: "  [\"${name}\"] = \"${c.hex}\",\n") derived)}}
    '';
    # WezTerm color-scheme rows in the colors-TOML shape; the tab bar sits on
    # the surface step and inactive chrome reads through the subtle tier.
    weztermColorScheme = {
      foreground = palette.foreground.hex;
      background = palette.background.hex;
      cursor_bg = palette.foreground.hex;
      cursor_fg = palette.background.hex;
      cursor_border = palette.foreground.hex;
      selection_fg = palette.foreground.hex;
      selection_bg = palette.selection.hex;
      split = palette.subtle.hex;
      quick_select_label_bg = {Color = roles.state.attention.hex;};
      quick_select_label_fg = {Color = roles.text.inverse.hex;};
      quick_select_match_bg = {Color = roles.surface.selected.hex;};
      quick_select_match_fg = {Color = roles.text.primary.hex;};
      input_selector_label_bg = {Color = roles.surface.raised.hex;};
      input_selector_label_fg = {Color = roles.accent.primary.hex;};
      launcher_label_bg = {Color = roles.surface.raised.hex;};
      launcher_label_fg = {Color = roles.accent.primary.hex;};
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
        background = roles.surface.surface.hex;
        active_tab = {
          bg_color = roles.accent.primary.hex;
          fg_color = roles.text.inverse.hex;
        };
        inactive_tab = {
          bg_color = roles.surface.surface.hex;
          fg_color = roles.text.subtle.hex;
        };
        inactive_tab_hover = {
          bg_color = roles.surface.raised.hex;
          fg_color = roles.text.primary.hex;
        };
        new_tab = {
          bg_color = roles.surface.surface.hex;
          fg_color = roles.text.subtle.hex;
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
    # Semantic-token rules for editor.semanticTokenColorCustomizations.
    vscodeSemanticRules = semanticRules;
  };
in {
  options.forge.theme = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {inherit palette derived roles ansi16 syntaxScopes icons targets projections;};
    description = "Estate palette owner: enriched Dracula tokens, roles, ANSI-16, registry, projections.";
  };

  config = {
    home.packages = [forgeThemeProof];

    # Machine-readable projections for consumers outside Home Manager modules,
    # the ecosystem exchange adapter, the proof board, and the closeout seed.
    xdg.configFile = {
      "forge/theme/palette.json".text = paletteJson;
      "forge/theme/forge-dracula.tmTheme".source = tmThemeFile;
      "forge/theme/base24.yaml".text = base24Yaml;
      "forge/theme/palette.html".source = paletteHtml;
      "forge/theme/coverage.json".text = builtins.toJSON {
        schema = "forge-theme-coverage/v1";
        inherit targets;
      };
      # AESTHETIC-CLOSEOUT phase-1 register seed: one touchpoint per target;
      # the mapping wave fills option_space, capture_ref, and placement.
      "forge/theme/closeout-register.json".text = builtins.toJSON {
        schema = "aesthetic-closeout-register/v1";
        label_convention = "[BRACKETED_UPPER]";
        touchpoints =
          map (t: {
            inherit (t) id carrier verdict;
            config_path = t.owner;
            palette_tokens = t.binds;
            option_space = null;
            capture_ref = null;
            placement = null;
          })
          targets;
      };
    };
  };
}
