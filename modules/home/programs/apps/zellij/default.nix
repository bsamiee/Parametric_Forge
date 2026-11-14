{
  config,
  lib,
  pkgs,
  ...
}: let
  pluginRows = (import ../../../../../overlays/manifest.nix).extensions.zellij-plugins.rows;

  # --- [SESSION_ATTACH]
  sessionAttach = pkgs.writeShellApplication {
    name = "zellij-session-attach";
    text = ''
      started() {
        local stamp
        stamp=$(/bin/ps -o lstart= -p "$1") || return 1
        read -r stamp <<<"$stamp"
        LC_ALL=C /bin/date -j -f '%a %b %e %T %Y' "$stamp" +%s
      }
      login="" servers=()
      while read -r uid pid args; do
        ((uid == UID)) || continue
        case $args in
          /System/Library/CoreServices/loginwindow.app/*) login=$pid ;;
          */bin/zellij\ --server\ *) servers+=("$pid") ;;
        esac
      done < <(/bin/ps -axo uid=,pid=,args=)
      if [[ -n $login ]] && boundary=$(started "$login"); then
        for pid in "''${servers[@]}"; do
          if since=$(started "$pid") && ((since < boundary)) && kill -TERM "$pid" 2>/dev/null; then
            for _ in {1..50}; do
              kill -0 "$pid" 2>/dev/null || break
              /bin/sleep 0.1
            done
          fi
        done
      fi
      exec ${lib.getExe config.programs.zellij.package} attach --create --force-run-commands "$@"
    '';
  };
in {
  imports = [
    ./config.nix
    ./themes/dracula.nix
    ./layouts/default.nix
  ];

  options.forge.zellij.web = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    readOnly = true;
    default = {
      port = "8082";
      tailnetPort = "8443";
    };
    description = "Ports of the Zellij web client: the loopback port its server listens on and the tailnet HTTPS port that serves it.";
  };

  options.forge.zellij.attach = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    default = sessionAttach;
    description = "Session attach for WezTerm spawns: retires servers from an ended login session, then attaches or rebuilds the named session.";
  };

  config = {
    programs.zellij.enable = true;

    home.activation.zellijPluginGrants = lib.hm.dag.entryAfter ["writeBoundary"] (let
      plugDir = "${config.xdg.configHome}/zellij/plugins";
      permsFile = "${config.home.homeDirectory}/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl";
      grantBlocks = pkgs.writeText "zellij-plugin-grants.kdl" (lib.concatStrings (lib.mapAttrsToList (name: row: ''
          "${plugDir}/${name}.wasm" {
          ${lib.concatMapStrings (p: "    ${p}\n") row.permissions}}
        '')
        pluginRows));
      pruneAwk = pkgs.writeText "zellij-grant-prune.awk" ''
        /^"/ { drop = (index($0, q dir) == 1) }
        !drop { print }
        /^}/ { drop = 0 }
      '';
    in ''
      run ${pkgs.runtimeShell} -c ${lib.escapeShellArg ''
        set -eu
        permsFile="${permsFile}"
        tmp="$permsFile.tmp"
        ${pkgs.coreutils}/bin/mkdir -p "''${permsFile%/*}"
        if [ -f "$permsFile" ]; then
          ${pkgs.gawk}/bin/awk -v dir="${plugDir}/" -v q='"' -f ${pruneAwk} "$permsFile" >"$tmp"
        else
          : >"$tmp"
        fi
        ${pkgs.coreutils}/bin/cat ${grantBlocks} >>"$tmp"
        ${pkgs.coreutils}/bin/mv "$tmp" "$permsFile"
      ''}
    '');

    # --- [PLUGIN_INSTALLATION]
    xdg.configFile = lib.mapAttrs' (name: row:
      lib.nameValuePair "zellij/plugins/${name}.wasm" {
        source =
          if row ? attr
          then pkgs.zellijPlugins.${row.attr}
          else pkgs.fetchurl {inherit (row) url hash;};
      })
    pluginRows;
  };
}
