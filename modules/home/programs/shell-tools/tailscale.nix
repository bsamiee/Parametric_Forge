{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.forge.tailnet;
  app = config.forge.apps.tailscale;
in {
  options.forge.tailnet.cli = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "${app.path}/Contents/MacOS/Tailscale";
    description = "CLI of the Standalone Tailscale app, the one tailnet client on this Mac.";
  };

  config = {
    home.packages = [(pkgs.writeShellScriptBin "tailscale" ''exec ${cfg.cli} "$@"'')];

    # --- [START_AT_LOGIN]
    targets.darwin.defaults.${app.id}.TailscaleStartOnLogin = true;
  };
}
