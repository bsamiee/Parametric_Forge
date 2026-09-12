# Title         : fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/fonts.nix
# ----------------------------------------------------------------------------
# Estate font owner: package installation, typography roles, fallback chains, per-surface typography rows, and renderer projections.
# Home Manager's unconditional Darwin target unions share/fonts across every home.packages entry and rsyncs real files into
# ~/Library/Fonts/HomeManager (CoreText ignores symlinked fonts); no second font installer is needed.
{
  host,
  lib,
  pkgs,
  ...
}: let
  # --- [FAMILY_CATALOG]
  # The catalog supplies both the installed packages and renderer families. The manifest derivation opens each representative file
  # with fonttools and fails the build on name-table disagreement (parity at build time). `class`: static | variable | patched. `sample` overrides text.
  catalog = import ../common/fonts-catalog.nix {inherit pkgs;};

  # --- [ROLES_CHAINS_SURFACES_FEATURES]
  # Roles are the swap surface: one family per role, scripts ordered by shaping preference. Every role family must be a catalog row — a typo
  # fails at eval, never at runtime in the doctor. The mono chain is the fallback expression CoreText and Chromium renderers read; fontconfig is
  # inert against them. Emoji is system-owned (Apple Color Emoji): a chain member so WezTerm's bundled Noto Color Emoji never wins, never a package row.
  roles = lib.throwIf (!(lib.all (f: catalog ? ${f}) (lib.flatten (lib.attrValues roles')))) "forge.fonts: a role names a family absent from the catalog" roles';
  roles' = {
    mono = "Geist Mono";
    sans = "Geist";
    symbols = "Symbols Nerd Font Mono";
    scripts = ["Scheherazade New" "Noto Naskh Arabic" "Noto Sans Arabic"];
  };
  chains.mono = [roles.mono roles.symbols] ++ roles.scripts ++ lib.optional (host.os == "darwin") "Apple Color Emoji";

  # Per-surface typography table: each surface binds a family role, size (px), and leading (unitless) — the sole owner of every type fact. The
  # terminal leading is the mono family's own catalog row (0.95 is tuned for Geist and clips Monaspace/JetBrains descenders; below 1.0 is
  # family-proven only), so a role swap carries its leading with it. Positional constructor keeps rows single-line (alejandra explodes
  # multi-key attrset literals).
  mkSurface = family: size: leading: {inherit family size leading;};
  surfaces = {
    terminal = mkSurface "mono" 13.0 catalog.${roles.mono}.lineHeight;
    screenshot = mkSurface "mono" 16.0 1.4;
    proof = mkSurface "sans" 14.0 1.5;
  };

  # CSS projectors: px size and rounded-percent leading single-source the unit forms consumers previously hardcoded (F5's numeric-vs-% disagreement).
  cssSize = surf: "${toString (builtins.floor surfaces.${surf}.size)}px";
  cssLeading = surf: "${toString (builtins.floor (surfaces.${surf}.leading * 100.0 + 0.5))}%";
  # Sans body stack (proof surface): sans role first, the mono chain as fallback, generic monospace last.
  cssSansStack = lib.concatStringsSep ", " ([roles.sans] ++ chains.mono ++ ["monospace"]);

  # Literal-safe shaping: contextual alternates on, every ligature class off.
  features.harfbuzz = ["calt=1" "liga=0" "clig=0" "dlig=0"];

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

  # --- [FORGE_FONT_DOCTOR_MANIFEST_VS_OBSERVED_PROOF]
  # Rows: payload parity against the active generation's font env (the marker is Home Manager's own symlink into the live generation, so it
  # can never name a stale one; only the copied payload can drift), then per-role CoreText registration proven from the Home Manager payload
  # path itself (system_profiler enumerates every registered file with its path and enabled/valid state on macOS 26) — a same-named family
  # registered from elsewhere, such as Adobe's user-owned font store, never satisfies a role row.
  forgeFontDoctor = pkgs.writeShellApplication {
    name = "forge-font-doctor";
    runtimeInputs = [pkgs.jq pkgs.coreutils pkgs.rsync pkgs.gawk];
    text = ''
      manifest="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/fonts/manifest.json"
      payload="$HOME/Library/Fonts/.home-manager-fonts-version"
      # Admission gate: the manifest crosses once, shape-asserted — a missing or torn projection fails typed, never as a raw jq slurpfile error.
      jq -e '(.families | type == "object") and (.roles | type == "object")' "$manifest" >/dev/null 2>&1 || {
        printf 'forge-font-doctor: manifest missing or malformed: %s\n' "$manifest" >&2
        exit 66
      }
      if [[ -f $payload && -d "$(<"$payload")/share/fonts" && -d "$HOME/Library/Fonts/HomeManager" ]]; then
        changes=$(rsync -acnL --chmod=u+w --delete --out-format='%n' "$(<"$payload")/share/fonts/" "$HOME/Library/Fonts/HomeManager/")
        if [[ -z $changes ]]; then
          payload_result=ok
          payload_detail="native Home Manager font projection matches its generation"
        else
          payload_result=fail
          payload_detail="native Home Manager font projection differs from its generation"
        fi
      else
        payload_result=fail
        payload_detail="native Home Manager font generation or projection missing"
      fi
      # One projection: CoreText enumeration joins the manifest role chain in a single jq pass over the system_profiler snapshot. A dead profiler
      # degrades typed — an empty snapshot fails every CoreText row, never the kernel. One row stream renders both the human table and --json.
      snapshot="$(/usr/sbin/system_profiler SPFontsDataType -json 2>/dev/null || true)"
      [[ -n $snapshot ]] || snapshot='{}'
      report="$(jq -c --slurpfile m "$manifest" --arg pr "$payload_result" --arg pd "$payload_detail" --arg hm "$HOME/Library/Fonts/HomeManager/" '
          ([.SPFontsDataType[]? | select((.path | startswith($hm)) and .enabled == "yes" and .valid == "yes")
            | .typefaces[]? | select(.enabled == "yes" and .valid == "yes") | .family] | unique) as $registered
          | ($m[0].roles | [to_entries[].value] | flatten | unique) as $families
          | {schema: "forge-font-doctor/v1",
             rows: ([{surface: "payload", result: $pr, detail: $pd}]
               + [$families[] | {
                   surface: "coretext:\(.)",
                   result: (if IN($registered[]) then "ok" else "fail" end),
                   detail: (if IN($registered[]) then "registered from the Home Manager payload" else "not enumerated from ~/Library/Fonts/HomeManager" end)}])}' <<<"$snapshot")"
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
      # The manifest's one public channel is the xdg projection every kernel reads.
      inherit catalog roles chains surfaces features;
      projections = {
        # WezTerm rows (terminal surface): deck.lua walks the chain; the leading is the terminal surface's one value.
        luaFont = {
          chain = chains.mono;
          inherit (surfaces.terminal) size;
          line_height = surfaces.terminal.leading;
          harfbuzz_features = features.harfbuzz;
        };
        # CSS stacks carry a generic fallback; the sans stack falls through to the mono chain.
        cssMono = lib.concatStringsSep ", " (chains.mono ++ ["monospace"]);
        fastfetchLabel = "${roles.mono} ${toString (builtins.floor surfaces.terminal.size)}pt";
        # Screenshot (carbon) and proof (theme HTML) CSS: one font shorthand plus the two scalar CSS forms the consumers previously hardcoded.
        proofFont = "${cssSize "proof"}/${cssLeading "proof"} ${cssSansStack}";
        screenshotSize = cssSize "screenshot";
        screenshotLeading = cssLeading "screenshot";
      };
    };
    description = "Estate font owner: family catalog, roles, chains, per-surface typography, projections.";
  };

  config = {
    home.packages = lib.unique (lib.mapAttrsToList (_: row: row.package) catalog) ++ lib.optionals (host.os == "darwin") [forgeFontDoctor];
    xdg.configFile."forge/fonts/manifest.json".source = manifestJson;
  };
}
