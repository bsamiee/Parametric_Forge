{
  lib,
  pkgs,
  ...
}: let
  apps = {
    Drafts = 1435957248;
    Xcode = 497799835;
    "Microsoft Word" = 462054704;
    "Microsoft Excel" = 462058435;
    "MEGA VPN" = 6456784858;
  };
  minutes = 60;
in {
  home.packages = [pkgs.mas];

  # --- [MAC_APP_STORE]
  home.activation.appStoreApps = lib.hm.dag.entryAfter ["writeBoundary"] (lib.concatStrings (lib.mapAttrsToList (name: id: ''
      if [[ ! -d ${lib.escapeShellArg "/Applications/${name}.app"} ]]; then
        run ${lib.getExe' pkgs.coreutils "timeout"} ${toString (minutes * 60)} ${lib.getExe pkgs.mas} install ${toString id} \
          || echo "app-store: ${name} is not installed (mas failed or passed ${toString minutes} minutes), the next switch retries" >&2
      fi
    '')
    apps));
}
