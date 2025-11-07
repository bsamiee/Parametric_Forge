# Title         : users.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/users.nix
# ----------------------------------------------------------------------------
# Shared user-related options for both nix-darwin and Home Manager.

{ lib, config, ... }:

let
  inherit (lib) mkIf mkMerge mkOption optional types;

  primaryUser = config.system.primaryUser;
  hasPrimaryUser = primaryUser != null;
  userDefined = hasPrimaryUser && builtins.hasAttr primaryUser config.users.users;
  userHasHome = userDefined && (config.users.users.${primaryUser} ? home);
  resolvedHome = if userHasHome then config.users.users.${primaryUser}.home else null;
in {
  options.system.primaryUser = mkOption {
    type = types.nullOr types.nonEmptyStr;
    default = null;
    description = ''
      Logical owner of the machine. This value is reused by modules that need
      to derive per-user paths (for example, launchd environments or
      Homebrew ownership).
    '';
    example = "alice";
  };

  options.system.primaryUserHome = mkOption {
    type = types.nullOr types.nonEmptyStr;
    default = null;
    readOnly = true;
    description = ''
      Resolved home directory for the configured primary user. This value is
      computed automatically from the corresponding entry in `users.users`.
    '';
    example = "/Users/alice";
  };

  config = mkMerge [
    {
      assertions =
        optional hasPrimaryUser {
          assertion = userDefined;
          message = "system.primaryUser '${primaryUser}' must exist in users.users.";
        }
        ++ optional (hasPrimaryUser && userDefined) {
          assertion = userHasHome;
          message = "users.users.${primaryUser}.home must be set when system.primaryUser is defined.";
        };
    }

    (mkIf userHasHome {
      system.primaryUserHome = resolvedHome;
    })
  ];
}
