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
  # fails at eval, never at runtime. The mono chain is the fallback expression CoreText and Chromium renderers read; fontconfig is
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
    home.packages = lib.unique (lib.mapAttrsToList (_: row: row.package) catalog);
    xdg.configFile."forge/fonts/manifest.json".source = manifestJson;
  };
}
