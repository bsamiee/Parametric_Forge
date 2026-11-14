{
  pkgs,
  applications,
  ...
}: let
  app = applications.tailscale;
in {
  home.packages = [(pkgs.writeShellScriptBin "tailscale" ''exec "${app.path}/Contents/MacOS/Tailscale" "$@"'')];

  # --- [START_AT_LOGIN]
  targets.darwin.defaults.${app.id}.TailscaleStartOnLogin = true;
}
