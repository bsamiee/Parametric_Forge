{
  lib,
  pkgs,
  ...
}: let
  # --- [FAMILY_CATALOG]
  catalog = import ./fonts-catalog.nix {inherit pkgs;};

  # --- [ROLES_CHAINS_SURFACES_FEATURES]
  roles = {
    mono = "Geist Mono";
    sans = "Geist";
    symbols = "Symbols Nerd Font Mono";
    scripts = ["Scheherazade New" "Noto Naskh Arabic" "Noto Sans Arabic"];
  };
  chains.mono = [roles.mono roles.symbols] ++ roles.scripts ++ ["Apple Color Emoji"];

  mkSurface = family: size: leading: {inherit family size leading;};
  surfaces.quicklook = mkSurface "mono" 15.0 1.5;
  surfaces.terminal = mkSurface "mono" 13.0 catalog.${roles.mono}.lineHeight;

  features.harfbuzz = ["calt=1" "liga=0" "clig=0" "dlig=0"];
in {
  options.forge.fonts = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit catalog roles chains surfaces features;
      projections = {
        luaFont = {
          chain = chains.mono;
          inherit (surfaces.terminal) size;
          line_height = surfaces.terminal.leading;
          harfbuzz_features = features.harfbuzz;
        };
        cssMono = lib.concatStringsSep ", " (chains.mono ++ ["monospace"]);
        fastfetchLabel = "${roles.mono} ${toString (builtins.floor surfaces.terminal.size)}pt";
      };
    };
    description = "Forge font owner: family catalog, roles, chains, per-surface typography, projections.";
  };

  config = {
    home.packages = lib.unique (lib.mapAttrsToList (_: row: row.package) catalog);
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = chains.mono;
        sansSerif = [roles.sans] ++ roles.scripts;
        emoji = ["Apple Color Emoji"];
      };
    };
  };
}
