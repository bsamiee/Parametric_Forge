# Title         : fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/fonts.nix
# ----------------------------------------------------------------------------
# Estate font owner mirroring theme.nix: family catalog, typography roles,
# fallback chains, per-family metrics, and renderer projections. Every type
# consumer interpolates these rows; no consumer carries a private family
# string. The darwin module installs files; this owner names families and
# drives renderers — it never reads config.fonts.packages.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  notoArabic = pkgs.noto-fonts.override {variants = ["NotoSansArabic" "NotoNaskhArabic"];};
  notoMono = pkgs.noto-fonts.override {variants = ["NotoSansMono"];};

  # --- Family catalog ---------------------------------------------------------
  # The attr name is the CoreText family; the manifest derivation opens each
  # representative file with fonttools and fails the build when the internal
  # name table disagrees (manifest-vs-payload parity at build time). `class`:
  # static | variable | patched. `sample` overrides the shaping-receipt text.
  catalog = {
    "Geist Mono" = {
      package = pkgs.geist-font;
      file = "share/fonts/opentype/GeistMono-Regular.otf";
      class = "static";
      roles = ["mono"];
      lineHeight = 0.95;
    };
    Geist = {
      package = pkgs.geist-font;
      file = "share/fonts/opentype/Geist-Regular.otf";
      class = "static";
      roles = ["sans"];
    };
    Iosevka = {
      package = pkgs.iosevka-bin;
      file = "share/fonts/truetype/Iosevka-Regular.ttc";
      class = "static";
      roles = ["mono"];
      lineHeight = 1.0;
    };
    Hack = {
      package = pkgs.hack-font;
      file = "share/fonts/truetype/Hack-Regular.ttf";
      class = "static";
      roles = ["mono"];
      lineHeight = 1.0;
    };
    "IBM Plex Mono" = {
      package = pkgs.ibm-plex;
      file = "share/fonts/opentype/IBMPlexMono-Regular.otf";
      class = "static";
      roles = ["mono"];
      lineHeight = 1.05;
    };
    "Noto Sans Mono" = {
      package = notoMono;
      file = "share/fonts/noto/NotoSansMono.ttf";
      class = "variable";
      roles = ["mono"];
      lineHeight = 1.0;
    };
    "Symbols Nerd Font Mono" = {
      package = pkgs.nerd-fonts.symbols-only;
      file = "share/fonts/truetype/NerdFonts/Symbols/SymbolsNerdFontMono-Regular.ttf";
      class = "patched";
      roles = ["symbols"];
      sample = "\\uf07b \\ue0b0 \\ue712 \\uf121";
    };
    "Source Serif 4" = {
      package = pkgs.source-serif;
      file = "share/fonts/opentype/SourceSerif4-Regular.otf";
      class = "static";
      roles = ["serif"];
    };
    "Scheherazade New" = {
      package = pkgs.scheherazade-new;
      file = "share/fonts/truetype/ScheherazadeNew-Regular.ttf";
      class = "static";
      roles = ["script"];
      sample = "سلام دنیا چطوری";
    };
    "Noto Naskh Arabic" = {
      package = notoArabic;
      file = "share/fonts/noto/NotoNaskhArabic.ttf";
      class = "variable";
      roles = ["script"];
      sample = "سلام دنیا چطوری";
    };
    "Noto Sans Arabic" = {
      package = notoArabic;
      file = "share/fonts/noto/NotoSansArabic.ttf";
      class = "variable";
      roles = ["script"];
      sample = "سلام دنیا چطوری";
    };
  };

  # --- Roles, chains, metrics, features ----------------------------------------
  # Roles are the swap surface: one family per role, scripts ordered by shaping
  # preference. The mono chain is the only fallback expression on macOS —
  # fontconfig is inert against CoreText and Chromium renderers.
  roles = {
    mono = "Geist Mono"; # forge-font:mono
    sans = "Geist";
    serif = "Source Serif 4";
    symbols = "Symbols Nerd Font Mono";
    emoji = "Apple Color Emoji"; # system-owned; never a package row
    scripts = ["Scheherazade New" "Noto Naskh Arabic" "Noto Sans Arabic"];
  };
  chains.mono = [roles.mono roles.symbols] ++ roles.scripts;

  metrics = {
    size = 13.0;
    # Terminal leading travels per mono family: 0.95 is tuned for Geist and
    # clips Monaspace/JetBrains descenders; below 1.0 is family-proven only.
    lineHeights = lib.mapAttrs (_: row: row.lineHeight) (lib.filterAttrs (_: row: row ? lineHeight) catalog);
    editorLineHeight = 1.5;
    cssLineHeight = "140%";
  };

  # Literal-safe shaping: contextual alternates on, every ligature class off.
  features = {
    harfbuzz = ["calt=1" "liga=0" "clig=0" "dlig=0"];
    vscode = "'calt' on, 'liga' off, 'clig' off, 'dlig' off";
  };

  overridePath = "${config.xdg.configHome}/forge/fonts/override.json";
  receiptLog = "$HOME/Library/Logs/forge-font.receipts.log";

  # --- Build-time manifest: name-table identity + feature + shaping receipts ---
  # fonttools is the metadata oracle, hb-shape the shaping oracle; feature
  # claims are proven by receipts, never by settings presence. Script rows
  # additionally assert zero .notdef over the Perso-Arabic sample.
  catalogJson = pkgs.writeText "forge-font-catalog.json" (builtins.toJSON (lib.mapAttrs (_: row: {
      path = "${row.package}/${row.file}";
      package = "${row.package.pname or row.package.name}-${row.package.version or ""}";
      inherit (row) class roles;
      sample = row.sample or "-> => != >= fi ffi 0O1lI";
    })
    catalog));
  manifestPy = pkgs.writeText "forge-font-manifest.py" ''
    import json, os, subprocess, sys
    from fontTools.ttLib import TTFont

    catalog = json.load(open(sys.argv[1]))
    hb = sys.argv[2]
    rows = {}
    for family, row in catalog.items():
        font = TTFont(row["path"], fontNumber=0, lazy=True)
        names = {n.nameID: n.toUnicode() for n in font["name"].names if n.nameID in (1, 5, 6, 16)}
        internal = names.get(16, names.get(1))
        if internal != family:
            sys.exit(f"name-table parity: declared '{family}' but payload says '{internal}' ({row['path']})")
        gsub = sorted({f.FeatureTag for f in font["GSUB"].table.FeatureList.FeatureRecord}) if "GSUB" in font else []
        axes = [a.axisTag for a in font["fvar"].axes] if "fvar" in font else []
        sample = row["sample"]
        if "\\u" in sample:  # escaped symbol codepoints; UTF-8 text passes through untouched
            sample = sample.encode("ascii").decode("unicode_escape")
        shaped = subprocess.run(
            [hb, row["path"], "--features=calt=1,liga=0,clig=0,dlig=0", "--no-glyph-names", "--text=" + sample],
            capture_output=True, text=True, check=True).stdout.strip()
        notdef = shaped.count("gid0") if "script" in row["roles"] or "symbols" in row["roles"] else 0
        if notdef:
            sys.exit(f"shaping coverage: '{family}' produced {notdef} .notdef glyphs over its sample")
        rows[family] = {
            "package": row["package"], "class": row["class"], "roles": row["roles"],
            "internal_family": internal, "postscript": names.get(6, ""), "version": names.get(5, ""),
            "axes": axes, "features": gsub,
            "shaping": {"sample": sample, "glyphs": shaped},
        }
    json.dump({"schema": "forge-fonts/v1", "families": rows}, open(os.path.join(sys.argv[3], "families.json"), "w"), indent=1, ensure_ascii=False)
  '';
  fontManifest =
    pkgs.runCommand "forge-font-manifest" {
      nativeBuildInputs = [(pkgs.python3.withPackages (ps: [ps.fonttools])) pkgs.harfbuzzFull.dev];
    } ''
      mkdir -p $out
      python3 ${manifestPy} ${catalogJson} ${pkgs.harfbuzzFull.dev}/bin/hb-shape $out
    '';
  manifestJson = pkgs.runCommand "forge-fonts.json" {nativeBuildInputs = [pkgs.jq];} ''
    jq --argjson roles ${lib.escapeShellArg (builtins.toJSON roles)} \
       --argjson chains ${lib.escapeShellArg (builtins.toJSON chains)} \
       --argjson metrics ${lib.escapeShellArg (builtins.toJSON metrics)} \
       --argjson features ${lib.escapeShellArg (builtins.toJSON features)} \
       '. + {roles: $roles, chains: $chains, metrics: $metrics, features: $features}' \
       ${fontManifest}/families.json >$out
  '';

  # --- forge-font: one polymorphic dispatch over the owner ---------------------
  # pick (default) | list | set <role> <family> | commit | reset. The runtime
  # override prepends a manifest-proven family; WezTerm hot-reloads through its
  # watch list. commit folds the override into this file and switches.
  forgeFont = pkgs.writeShellApplication {
    name = "forge-font";
    runtimeInputs = [pkgs.jq pkgs.fzf pkgs.sd pkgs.coreutils];
    text = ''
      manifest="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/manifest.json"
      override="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/override.json"
      owner="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}/modules/home/fonts.nix"
      emit() { # $1=verb $2=result $3=detail
        local ts
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        mkdir -p "$HOME/Library/Logs"
        printf 'ts=%s\towner=forge-font\tverb=%s\tresult=%s\tdetail=%s\n' "$ts" "$1" "$2" "$3" >>"${receiptLog}"
      }
      monos() { jq -r '.families | to_entries[] | select(.value.roles | index("mono")) | .key' "$manifest"; }
      apply() { # $1=role $2=family
        jq -e --arg f "$2" '.families | has($f)' "$manifest" >/dev/null || {
          printf 'forge-font: %s is not a manifest family\n' "$2" >&2
          exit 64
        }
        mkdir -p "''${override%/*}"
        jq -n --arg r "$1" --arg f "$2" '{($r): $f}' >"$override"
        emit set ok "$1=$2"
        printf 'override: %s = %s (WezTerm reloads live; forge-font commit makes it durable)\n' "$1" "$2"
      }
      case "''${1:-pick}" in
        pick)
          fam="$(monos | fzf --border-label='[FORGE-FONT: MONO]' --height=40%)" || exit 130
          apply mono "$fam"
          ;;
        list)
          jq -r '.families | to_entries[] | [.key, .value.class, (.value.roles | join("+")), .value.version, .value.package] | @tsv' "$manifest" \
            | awk -F'\t' 'BEGIN{printf "%-24s %-9s %-14s %-24s %s\n","FAMILY","CLASS","ROLES","VERSION","PACKAGE"}{printf "%-24s %-9s %-14s %-24s %s\n",$1,$2,$3,$4,$5}'
          ;;
        set) apply "''${2:?role}" "''${3:?family}" ;;
        commit)
          [[ -f $override ]] || {
            printf 'forge-font: no override to commit\n' >&2
            exit 64
          }
          fam="$(jq -r '.mono // empty' "$override")"
          [[ -n $fam ]] || {
            printf 'forge-font: override carries no mono role\n' >&2
            exit 64
          }
          sd '^    mono = ".*"; # forge-font:mono' "    mono = \"$fam\"; # forge-font:mono" "$owner"
          emit commit ok "mono=$fam"
          forge-redeploy --switch && rm -f "$override" && emit reset ok "post-commit"
          ;;
        reset)
          rm -f "$override"
          emit reset ok "-"
          printf 'override cleared; nix roles govern\n'
          ;;
        *)
          printf 'usage: forge-font [pick|list|set <role> <family>|commit|reset]\n' >&2
          exit 64
          ;;
      esac
    '';
  };

  # --- forge-font-doctor: manifest-vs-observed proof ---------------------------
  # Rows: payload parity against the darwin projection manifest, CoreText
  # registration through system_profiler enumeration, per-role presence, and
  # the Electron lane note. fc-* stays a separate Pango-only lane, never mixed.
  forgeFontDoctor = pkgs.writeShellApplication {
    name = "forge-font-doctor";
    runtimeInputs = [pkgs.jq pkgs.coreutils];
    text = ''
      manifest="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/manifest.json"
      payload="$HOME/Library/Fonts/.forge-fonts-manifest"
      sp="$(/usr/sbin/system_profiler SPFontsDataType -json 2>/dev/null)"
      rows=()
      row() { rows+=("$(jq -nc --arg s "$1" --arg r "$2" --arg d "$3" '{surface:$s,result:$r,detail:$d}')"); }
      if [[ -f $payload ]]; then
        row payload ok "$(wc -l <"$payload" | tr -d ' ') managed files projected"
      else
        row payload fail "darwin projection manifest missing"
      fi
      while IFS= read -r fam; do
        if jq -e --arg f "$fam" '.SPFontsDataType[].typefaces[]? | select(.family == $f)' <<<"$sp" >/dev/null 2>&1; then
          row "coretext:$fam" ok "registered"
        else
          row "coretext:$fam" fail "not enumerated by system_profiler"
        fi
      done < <(jq -r '.roles | [.mono, .sans, .serif, .symbols] + .scripts | .[]' "$manifest")
      row electron "note" "Chromium reads CoreText post-restart; the rendered receipt is the VS Code capture lane"
      row fontconfig "note" "fc-* serves Pango-class consumers only; CoreText rows above are Darwin truth"
      printf '%s\n' "''${rows[@]}" | jq -s '{schema:"forge-font-doctor/v1", rows:.}'
      if printf '%s\n' "''${rows[@]}" | jq -e 'select(.result == "fail")' >/dev/null; then exit 1; fi
    '';
  };
in {
  options.forge.fonts = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit catalog roles chains metrics features overridePath;
      manifest = manifestJson;
      projections = {
        # WezTerm rows: deck.lua walks the chain, applies per-family leading,
        # and prepends the override family when the override file exists.
        luaFont = {
          chain = map (f: {family = f;}) chains.mono;
          inherit (metrics) size;
          line_heights = metrics.lineHeights;
          default_line_height = 1.0;
          harfbuzz_features = features.harfbuzz;
          override_path = overridePath;
        };
        # Quoted family chain for editor-class consumers.
        vscodeFamily = lib.concatMapStringsSep ", " (f: "'${f}'") chains.mono;
        cssMono = lib.concatStringsSep ", " (chains.mono ++ ["monospace"]);
        fastfetchLabel = "${roles.mono} ${toString (builtins.floor metrics.size)}pt";
      };
    };
    description = "Estate font owner: family catalog, roles, chains, metrics, projections.";
  };

  config = {
    # The doctor probes CoreText and the ~/Library/Fonts payload — Darwin-only.
    home.packages = [forgeFont] ++ lib.optionals (host.os == "darwin") [forgeFontDoctor];
    xdg.configFile."forge/fonts/manifest.json".source = manifestJson;
  };
}
