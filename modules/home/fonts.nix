{
  lib,
  pkgs,
  ...
}: let
  # --- [FAMILY_CATALOG]
  catalog = import ./fonts-catalog.nix {inherit pkgs;};

  # --- [ROLES_CHAINS_SURFACES]
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
in {
  config = {
    _module.args.typography = {
      inherit catalog roles chains surfaces;
      projections = {
        luaFont = {
          chain = chains.mono;
          inherit (surfaces.terminal) size;
          line_height = surfaces.terminal.leading;
        };
        cssMono = lib.concatStringsSep ", " (chains.mono ++ ["monospace"]);
        fastfetchLabel = "${roles.mono} ${toString (builtins.floor surfaces.terminal.size)}pt";
      };
    };

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
