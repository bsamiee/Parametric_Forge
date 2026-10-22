# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/defaults/default.nix
# ----------------------------------------------------------------------------
# User-defaults owner: each domain row renders one plist under the config root, and Home Manager's onChange hook imports it — restarting the
# domain's launch-time reader — only on the generation that changed it. nix-darwin's system.defaults rewrites every user key through
# launchctl+sudo+defaults and restarts the Dock on every activation (defaults-write.nix), which is a WindowServer/Finder/Electron redraw storm per
# pass; user rows therefore live here and only the root-scope rows (loginwindow, SoftwareUpdate) stay on system.defaults.
{
  config,
  lib,
  ...
}: let
  cfg = config.forge.userDefaults;
  # Readers that load their domain at launch only: a changed plist restarts them. Every other domain is picked up live through cfprefsd.
  restart = {"com.apple.dock" = "Dock";};
  # The global domain rides its defaults(1) import spelling; every other row imports under its own name.
  importDomain = domain:
    if domain == "NSGlobalDomain"
    then "-globalDomain"
    else domain;
  root = "${config.xdg.configHome}/forge/defaults";
  domains = lib.filterAttrs (_: keys: keys != {}) (lib.mapAttrs (_: lib.filterAttrs (_: v: v != null)) cfg);
  mkRow = domain: keys: let
    path = "${root}/${domain}.plist";
  in
    lib.nameValuePair path {
      text = lib.generators.toPlist {escape = true;} keys;
      onChange =
        ''
          run /usr/bin/defaults import ${lib.escapeShellArg (importDomain domain)} ${lib.escapeShellArg path}
        ''
        + lib.optionalString (restart ? ${domain}) ''
          run /usr/bin/killall -q ${restart.${domain}} || true
        '';
    };
in {
  imports = [
    ./input.nix
    ./interface.nix
    ./system.nix
  ];

  options.forge.userDefaults = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    default = {};
    description = "macOS user defaults, domain -> keys (a null key is left unwritten); each domain is one plist, imported (a merge into the live domain) only on the generation that changed it.";
  };

  config.home.file = lib.mapAttrs' mkRow domains;
}
