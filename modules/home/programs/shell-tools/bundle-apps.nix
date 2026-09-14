# Title         : bundle-apps.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/bundle-apps.nix
# ----------------------------------------------------------------------------
# macOS agent-identity owner: one bundleApps row per background agent projects the Applications/<display>.app Info.plist (so Login Items & Extensions
# resolves launchd AssociatedBundleIdentifiers to a real name instead of the "/bin/sh" basename), one LaunchServices registration batch, and the
# `forgeAgent` fold every com.parametric-forge.<name> launchd row is built from.
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

  config = {
    # One launchd-agent grammar: label, argv, background class, one dual log per agent, and the identity bundle (its own name unless a shared
    # bundle row is named); every other key (schedule, KeepAlive, RunAtLoad, ThrottleInterval) rides as given.
    _module.args.forgeAgent = {
      name,
      argv,
      bundle ? name,
      ...
    } @ row: {
      enable = true;
      config =
        {
          Label = "com.parametric-forge.${name}";
          ProgramArguments = argv;
          ProcessType = "Background";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/${name}.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/${name}.log";
          AssociatedBundleIdentifiers = ["com.parametric-forge.${bundle}"];
        }
        // removeAttrs row ["name" "argv" "bundle"];
    };

    # Each identity bundle registers with LaunchServices on the generation that changed its Info.plist (onChange).
    home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
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
            onChange = ''
              lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
              run "$lsregister" -f "$HOME/Applications/${display}.app"
            '';
          }
      )
      cfg
    );
  };
}
