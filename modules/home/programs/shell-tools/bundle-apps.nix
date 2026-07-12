# Title         : bundle-apps.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/bundle-apps.nix
# ----------------------------------------------------------------------------
# macOS agent-identity owner: one bundleApps row per background agent projects the Applications/<display>.app Info.plist (so Login Items & Extensions
# resolves launchd AssociatedBundleIdentifiers to a real name instead of the "/bin/sh" basename) and one LaunchServices registration batch.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.forge.bundleApps;
in {
  options.forge = {
    bundleApps = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Identity bundle rows, ident -> display name: renders Applications/<display>.app and registers it so a launchd row's AssociatedBundleIdentifiers = [\"com.parametric-forge.<ident>\"] resolves.";
    };
  };

  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    home.file =
      lib.mapAttrs' (
        ident: display:
          lib.nameValuePair "Applications/${display}.app/Contents/Info.plist" {
            text = lib.generators.toPlist {escape = true;} {
              CFBundleIdentifier = "com.parametric-forge.${ident}";
              CFBundleName = display;
              CFBundleDisplayName = display;
              CFBundleVersion = "1";
              CFBundleShortVersionString = "1.0";
              CFBundlePackageType = "APPL";
              LSUIElement = true;
              LSBackgroundOnly = true;
            };
          }
      )
      cfg;

    # lsregister -f is idempotent; a missing app or binary is a silent no-op so activation never fails on this cosmetic identity surface.
    home.activation.registerForgeBundleApps = lib.hm.dag.entryAfter ["linkGeneration"] ''
      lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
      for app in ${lib.concatMapStringsSep " " (d: ''"$HOME/Applications/${d}.app"'') (lib.attrValues cfg)}; do
        if [ -d "$app" ] && [ -x "$lsregister" ]; then
          "$lsregister" -f "$app" || true
        fi
      done
    '';
  };
}
