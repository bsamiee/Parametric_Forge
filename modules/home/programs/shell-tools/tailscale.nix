{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  cfg = config.forge.tailnet;
  app = config.forge.apps.tailscale;
  jq = lib.getExe pkgs.jq;
in {
  options.forge.tailnet = {
    cli = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${app.path}/Contents/MacOS/Tailscale";
      description = "CLI of the Standalone Tailscale app, the one tailnet client on this Mac.";
    };
    serve = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Tailnet HTTPS port -> local target; activation keeps each row in the app's own serve config.";
    };
  };

  config = {
    home.packages = [(pkgs.writeShellScriptBin "tailscale" ''exec ${cfg.cli} "$@"'')];

    # --- [START_AT_LOGIN]
    targets.darwin.defaults.${app.id}.TailscaleStartOnLogin = true;

    # --- [SERVE]
    home.activation.tailnetServe = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if certificates="$(${cfg.cli} status --json 2>/dev/null | ${jq} -r '.CertDomains | length')" && ((certificates > 0)); then
        served="$(${cfg.cli} serve status --json 2>/dev/null || echo "{}")"
        ${lib.concatStrings (lib.mapAttrsToList (port: target: ''
          if [[ "$(${jq} -r --arg web ${host.tailnet.node}:${port} '.Web[$web].Handlers["/"].Proxy // empty' <<<"$served")" != ${lib.escapeShellArg target} ]]; then
            run ${lib.getExe' pkgs.coreutils "timeout"} 30 ${cfg.cli} serve --bg --https=${port} ${lib.escapeShellArg target} >/dev/null || echo "tailnet-serve: https ${port} to ${target} not set" >&2
          fi
        '')
        cfg.serve)}
      else
        echo "tailnet-serve: no certificate for ${host.tailnet.node} yet (tailnet HTTPS off or the app not running), rows wait: ${toString (lib.attrNames cfg.serve)}" >&2
      fi
    '';
  };
}
