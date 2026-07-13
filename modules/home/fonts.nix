# Title         : fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/fonts.nix
# ----------------------------------------------------------------------------
# Estate font owner: the cross-scope family catalog, typography roles, fallback chains, per-surface typography rows, and renderer projections. Every
# type consumer interpolates these rows; no consumer carries a private family, size, leading, or weight. The darwin module folds the same catalog into
# its install list; this owner names families and drives renderers — it never reads config.fonts.packages.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  # --- [FAMILY_CATALOG]
  # The cross-scope catalog (modules/common/fonts-catalog.nix) is the single family-truth surface; the darwin owner folds the same rows into its
  # install list, so a catalog family absent from the install set is structurally impossible. The manifest derivation opens each representative file
  # with fonttools and fails the build on name-table disagreement (parity at build time). `class`: static | variable | patched. `sample` overrides text.
  catalog = import ../common/fonts-catalog.nix {inherit pkgs;};

  # --- [ROLES_CHAINS_SURFACES_FEATURES]
  # Roles are the swap surface: one family per role, scripts ordered by shaping preference. The mono chain is the only fallback expression on macOS —
  # fontconfig is inert against CoreText and Chromium renderers. Emoji is system-owned (Apple Color Emoji) and is never a role or a package row.
  roles = {
    mono = "Geist Mono"; # forge-font:mono
    sans = "Geist";
    symbols = "Symbols Nerd Font Mono";
    scripts = ["Scheherazade New" "Noto Naskh Arabic" "Noto Sans Arabic"];
  };
  chains.mono = [roles.mono roles.symbols] ++ roles.scripts;

  # Per-mono-family terminal leading, folded from catalog rows: 0.95 is tuned for Geist and clips Monaspace/JetBrains descenders; below 1.0 is
  # family-proven only. Projected to WezTerm's per-family line_heights; the terminal surface's default_line_height governs any family without a row.
  familyLeading = lib.mapAttrs (_: row: row.lineHeight) (lib.filterAttrs (_: row: row ? lineHeight) catalog);

  # Per-surface typography table: each surface binds a family role, size (px), leading (unitless), and weight — the sole owner of every type fact.
  # Every renderer projection folds from its surface row; no consumer carries a private family, size, leading, or weight. Positional constructor keeps
  # rows single-line (alejandra explodes multi-key attrset literals); weightBold defaults bold and only the terminal surface reads it.
  mkSurface = family: size: leading: weight: {
    inherit family size leading weight;
    weightBold = "bold";
  };
  surfaces = {
    terminal = mkSurface "mono" 13.0 1.0 "normal";
    editor = mkSurface "mono" 13.0 1.5 "normal";
    screenshot = mkSurface "mono" 16.0 1.4 "normal";
    proof = mkSurface "sans" 14.0 1.5 "normal";
    label = mkSurface "mono" 13.0 1.0 "normal";
  };

  # CSS projectors: px size and rounded-percent leading single-source the unit forms consumers previously hardcoded (F5's numeric-vs-% disagreement).
  cssSize = surf: "${toString (builtins.floor surfaces.${surf}.size)}px";
  cssLeading = surf: "${toString (builtins.floor (surfaces.${surf}.leading * 100.0 + 0.5))}%";
  # Sans body stack (proof surface): sans role first, the mono chain as fallback, generic monospace last.
  cssSansStack = lib.concatStringsSep ", " ([roles.sans] ++ chains.mono ++ ["monospace"]);

  # Literal-safe shaping: contextual alternates on, every ligature class off.
  features = {
    harfbuzz = ["calt=1" "liga=0" "clig=0" "dlig=0"];
    vscode = "'calt' on, 'liga' off, 'clig' off, 'dlig' off";
  };

  overridePath = "${config.xdg.configHome}/forge/fonts/override.json";
  receiptsFold = import ./programs/shell-tools/receipts.nix;

  # --- [BUILD_TIME_MANIFEST_NAME_TABLE_IDENTITY_FEATURE_SHAPING_RECEIPTS]
  # fonttools is the metadata oracle, hb-shape the shaping oracle; feature claims are proven by receipts, never by settings presence. Script rows
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
      nativeBuildInputs = [(pkgs.python3.withPackages (ps: [ps.fonttools])) pkgs.harfbuzz.dev];
    } ''
      mkdir -p $out
      # Base harfbuzz owns the shaping oracle: the icu variant ships no core libharfbuzz.so on Linux, and hb-shape carries no RUNPATH, so the
      # explicit library path binds the loader on Linux while staying inert on darwin (absolute install-names). OT shaping needs no ICU.
      export LD_LIBRARY_PATH=${lib.makeLibraryPath [pkgs.harfbuzz]}
      python3 ${manifestPy} ${catalogJson} ${pkgs.harfbuzz.dev}/bin/hb-shape $out
    '';
  manifestJson = pkgs.runCommand "forge-fonts.json" {nativeBuildInputs = [pkgs.jq];} ''
    jq --argjson roles ${lib.escapeShellArg (builtins.toJSON roles)} \
       --argjson chains ${lib.escapeShellArg (builtins.toJSON chains)} \
       --argjson surfaces ${lib.escapeShellArg (builtins.toJSON surfaces)} \
       --argjson features ${lib.escapeShellArg (builtins.toJSON features)} \
       '. + {roles: $roles, chains: $chains, surfaces: $surfaces, features: $features}' \
       ${fontManifest}/families.json >$out
  '';

  # --- [FORGE_FONT_ONE_POLYMORPHIC_DISPATCH_OVER_THE_OWNER]
  # pick (default) | list | set <role> <family> | commit | reset. The runtime override prepends a manifest-proven family; WezTerm hot-reloads
  # through its watch list. commit folds the override into this file and switches.
  forgeFont = pkgs.writeShellApplication {
    name = "forge-font";
    runtimeInputs = [pkgs.jq pkgs.fzf pkgs.sd pkgs.gnugrep pkgs.coreutils];
    text = ''
      manifest="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/manifest.json"
      override="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/override.json"
      owner="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}/modules/home/fonts.nix"
      receipt_log="''${FORGE_FONT_RECEIPT_LOG:-$HOME/Library/Logs/forge-font.receipts.log}"
      receipt_surface="forge-font"
      ${receiptsFold}
      emit() { # $1=verb $2=outcome key (result|state) $3=outcome $4=detail
        local ts row
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        printf -v row 'ts=%s\tverb=%s\tdetail=%s\t%s=%s' "$ts" "$1" "$4" "$2" "$3"
        # An unwritable log must never mask a landed verb.
        append_receipt "$row" \
          || printf 'forge-font: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
      }
      require_manifest() { # admission gate: shape-asserted once, typed fault on a torn file
        jq -e '(.families | type == "object") and (.roles | type == "object")' "$manifest" >/dev/null 2>&1 || {
          printf 'forge-font: manifest missing or malformed: %s\n' "$manifest" >&2
          exit 66
        }
      }
      monos() { jq -r '.families | to_entries[] | select(.value.roles | index("mono")) | .key' "$manifest"; }
      apply() { # $1=role $2=family
        require_manifest
        jq -e --arg f "$2" '.families | has($f)' "$manifest" >/dev/null || {
          printf 'forge-font: %s is not a manifest family\n' "$2" >&2
          exit 64
        }
        mkdir -p "''${override%/*}"
        jq -n --arg r "$1" --arg f "$2" '{($r): $f}' >"$override"
        emit set result ok "$1=$2"
        printf 'override: %s = %s (WezTerm reloads live; forge-font commit makes it durable)\n' "$1" "$2"
      }
      case "''${1:-pick}" in
        pick)
          require_manifest
          fam="$(monos | fzf --border-label='[FORGE-FONT: MONO]' --height=40%)" || exit 130
          apply mono "$fam"
          ;;
        list)
          require_manifest
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
          command -v forge-redeploy >/dev/null || {
            printf 'forge-font: forge-redeploy not on PATH — commit needs the deploy rail\n' >&2
            emit commit result fail "forge-redeploy-missing"
            exit 69
          }
          sd '^    mono = ".*"; # forge-font:mono' "    mono = \"$fam\"; # forge-font:mono" "$owner"
          # sd exits 0 on zero matches; the landed row is the only edit proof.
          grep -qF "mono = \"$fam\"; # forge-font:mono" "$owner" || {
            printf 'forge-font: marker drift — no "# forge-font:mono" row landed in %s\n' "$owner" >&2
            emit commit result fail marker-drift
            exit 65
          }
          # Transition receipt at the edit, terminal receipt only after the switch lands — a failed redeploy leaves state=edited on record.
          emit commit state edited "mono=$fam"
          forge-redeploy --switch
          rm -f "$override"
          emit commit result ok "mono=$fam"
          ;;
        reset)
          rm -f "$override"
          emit reset result ok "-"
          printf 'override cleared; nix roles govern\n'
          ;;
        *)
          printf 'usage: forge-font [pick|list|set <role> <family>|commit|reset]\n' >&2
          exit 64
          ;;
      esac
    '';
  };

  # --- [FORGE_FONT_DOCTOR_MANIFEST_VS_OBSERVED_PROOF]
  # Rows: payload parity against the darwin projection manifest, CoreText registration through system_profiler enumeration, per-role presence,
  # and the Electron lane note. fc-* stays a separate Pango-only lane, never mixed.
  forgeFontDoctor = pkgs.writeShellApplication {
    name = "forge-font-doctor";
    runtimeInputs = [pkgs.jq pkgs.coreutils];
    text = ''
      manifest="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/manifest.json"
      payload="$HOME/Library/Fonts/.forge-fonts-manifest"
      # Admission gate: the manifest crosses once, shape-asserted — a missing or torn projection fails typed, never as a raw jq slurpfile error.
      jq -e '(.families | type == "object") and (.roles | type == "object")' "$manifest" >/dev/null 2>&1 || {
        printf 'forge-font-doctor: manifest missing or malformed: %s\n' "$manifest" >&2
        exit 66
      }
      if [[ -f $payload ]]; then
        payload_result=ok
        payload_detail="$(wc -l <"$payload") managed files projected"
      else
        payload_result=fail
        payload_detail="darwin projection manifest missing"
      fi
      # One projection: CoreText enumeration joins the manifest role chain in a single jq pass over the system_profiler snapshot. A dead profiler
      # degrades typed — an empty snapshot fails every CoreText row, never the kernel. One row stream renders both the human table and --json.
      snapshot="$(/usr/sbin/system_profiler SPFontsDataType -json 2>/dev/null || true)"
      [[ -n $snapshot ]] || snapshot='{}'
      report="$(jq -c --slurpfile m "$manifest" --arg pr "$payload_result" --arg pd "$payload_detail" '
          ([.SPFontsDataType[]?.typefaces[]?.family] | unique) as $registered
          | ($m[0].roles | [to_entries[].value] | flatten | unique) as $families
          | {schema: "forge-font-doctor/v1",
             rows: ([{surface: "payload", result: $pr, detail: $pd}]
               + [$families[] | {
                   surface: "coretext:\(.)",
                   result: (if IN($registered[]) then "ok" else "fail" end),
                   detail: (if IN($registered[]) then "registered" else "not enumerated by system_profiler" end)}]
               + [{surface: "electron", result: "note", detail: "Chromium reads CoreText post-restart; the rendered receipt is the VS Code capture lane"},
                  {surface: "fontconfig", result: "note", detail: "fc-* serves Pango-class consumers only; CoreText rows above are Darwin truth"}])}' <<<"$snapshot")"
      if [[ "''${1:-}" == "--json" ]]; then
        jq . <<<"$report"
      else
        jq -r '.rows[] | [.surface, .result, .detail] | @tsv' <<<"$report" \
          | awk -F'\t' 'BEGIN{printf "%-34s %-6s %s\n","SURFACE","RESULT","DETAIL"}{printf "%-34s %-6s %s\n",$1,$2,$3}'
      fi
      jq -e '.rows | any(.result == "fail") | not' <<<"$report" >/dev/null
    '';
  };
in {
  options.forge.fonts = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      # overridePath reaches consumers only through luaFont.override_path — one public channel, never two; the manifest's one channel is the
      # xdg projection every kernel reads.
      inherit catalog roles chains surfaces features;
      projections = {
        # WezTerm rows (terminal surface): deck.lua walks the chain, applies per-family leading, and prepends the override family when it exists.
        luaFont = {
          chain = map (f: {family = f;}) chains.mono;
          inherit (surfaces.terminal) size;
          line_heights = familyLeading;
          default_line_height = surfaces.terminal.leading;
          harfbuzz_features = features.harfbuzz;
          override_path = overridePath;
        };
        # Quoted mono chain for editor-class consumers; the CSS stacks carry a generic fallback, and the sans stack falls through to the mono chain.
        vscodeFamily = lib.concatMapStringsSep ", " (f: "'${f}'") chains.mono;
        cssMono = lib.concatStringsSep ", " (chains.mono ++ ["monospace"]);
        fastfetchLabel = "${roles.mono} ${toString (builtins.floor surfaces.label.size)}pt";
        # Screenshot (carbon) and proof (theme HTML) CSS: one font shorthand plus the two scalar CSS forms the consumers previously hardcoded.
        proofFont = "${cssSize "proof"}/${cssLeading "proof"} ${cssSansStack}";
        screenshotSize = cssSize "screenshot";
        screenshotLeading = cssLeading "screenshot";
      };
    };
    description = "Estate font owner: family catalog, roles, chains, per-surface typography, projections.";
  };

  config = {
    # The doctor probes CoreText and the ~/Library/Fonts payload — Darwin-only.
    home.packages = [forgeFont] ++ lib.optionals (host.os == "darwin") [forgeFontDoctor];
    xdg.configFile."forge/fonts/manifest.json".source = manifestJson;
  };
}
