# Title         : fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/fonts.nix
# ----------------------------------------------------------------------------
# Forge font owner: package installation, typography roles, fallback chains, per-surface typography rows, and renderer projections.
# Home Manager's unconditional Darwin target unions share/fonts across every home.packages entry and rsyncs real files into
# ~/Library/Fonts/HomeManager (CoreText ignores symlinked fonts); no second font installer is needed.
{
  lib,
  pkgs,
  ...
}: let
  # --- [FAMILY_CATALOG]
  # The catalog supplies both the installed packages and renderer families.
  catalog = import ./fonts-catalog.nix {inherit pkgs;};

  # --- [ROLES_CHAINS_SURFACES_FEATURES]
  # Roles are the swap surface: one family per role, scripts ordered by shaping preference, each a catalog row. The mono chain is the fallback expression CoreText and Chromium renderers read; fontconfig is
  # inert against them. Emoji is system-owned (Apple Color Emoji): a chain member so WezTerm's bundled Noto Color Emoji never wins, never a package row.
  roles = {
    mono = "Geist Mono";
    sans = "Geist";
    symbols = "Symbols Nerd Font Mono";
    scripts = ["Scheherazade New" "Noto Naskh Arabic" "Noto Sans Arabic"];
  };
  chains.mono = [roles.mono roles.symbols] ++ roles.scripts ++ ["Apple Color Emoji"];

  # Per-surface typography table: each surface binds a family role, size (px), and leading (unitless) — the sole owner of every type fact. The
  # terminal leading is the mono family's own catalog row (0.95 is tuned for Geist and clips Monaspace/JetBrains descenders; below 1.0 is
  # family-proven only), so a role swap carries its leading with it. Positional constructor keeps rows single-line (alejandra explodes
  # multi-key attrset literals).
  mkSurface = family: size: leading: {inherit family size leading;};
  surfaces.terminal = mkSurface "mono" 13.0 catalog.${roles.mono}.lineHeight;

  # Literal-safe shaping: contextual alternates on, every ligature class off.
  features.harfbuzz = ["calt=1" "liga=0" "clig=0" "dlig=0"];
in {
  options.forge.fonts = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit catalog roles chains surfaces features;
      projections = {
        # WezTerm rows (terminal surface): deck.lua walks the chain; the leading is the terminal surface's one value.
        luaFont = {
          chain = chains.mono;
          inherit (surfaces.terminal) size;
          line_height = surfaces.terminal.leading;
          harfbuzz_features = features.harfbuzz;
        };
        # CSS stacks carry a generic fallback.
        cssMono = lib.concatStringsSep ", " (chains.mono ++ ["monospace"]);
        fastfetchLabel = "${roles.mono} ${toString (builtins.floor surfaces.terminal.size)}pt";
      };
    };
    description = "Forge font owner: family catalog, roles, chains, per-surface typography, projections.";
  };

  config.home.packages = lib.unique (lib.mapAttrsToList (_: row: row.package) catalog);
}
