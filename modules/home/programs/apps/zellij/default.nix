{
  config,
  lib,
  pkgs,
  ...
}: let
  statusbar = pkgs.pkgsCross.wasm32-wasip1.callPackage ./statusbar/package.nix {};
  plugins =
    lib.mapAttrs (_: row: row // {source = pkgs.fetchurl {inherit (row) url hash;};})
    (import ../../../../../overlays/manifest.nix).extensions.zellij-plugins.rows
    // {
      statusbar = {
        source = "${statusbar}/bin/statusbar.wasm";
        permissions = ["ReadApplicationState" "ChangeApplicationState" "RunActionsAsUser"];
      };
    };

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

  # --- [AGENT_RESUME]
  agentResume = pkgs.writeShellApplication {
    name = "zellij-agent-resume";
    runtimeInputs = [config.programs.zellij.package pkgs.jq];
    text = ''
      harness=''${1:?usage: zellij-agent-resume claude|codex|agy}
      input=$(cat)
      [[ $harness == agy ]] && printf '{}\n'
      [[ -n ''${ZELLIJ_PANE_ID-} ]] || exit 0
      read -r group foreground < <(/bin/ps -o pgid=,tpgid= -p "$PPID")
      [[ $group == "$foreground" ]] || exit 0
      read -ra argv < <(/bin/ps -o args= -p "$PPID")
      for word in "''${argv[@]:1}"; do
        case $harness/$word in
          claude/-p | claude/--print | codex/exec | agy/-p | agy/-p=* | agy/--print | agy/--print=* | agy/--prompt | agy/--prompt=*) exit 0 ;;
        esac
      done
      { read -r event; read -r id; read -r cwd; } < <(jq -r '.hook_event_name // .hookEventName, .session_id // .conversationId, .cwd' <<<"$input")
      case $harness in
        claude) resume="claude --resume $id" ;;
        codex) resume="codex resume --no-daemon $id" ;;
        agy) resume="agy --remote-control --conversation=$id" ;;
      esac
      declare_pane() {
        if [[ $event == SessionEnd ]]; then
          [[ $(zellij action dump-layout) == *"$resume"* ]] || return 0
          zellij action set-resurrect-command --clear
        else
          zellij action set-resurrect-command --cwd "$cwd" -- ${config.forge.shell} -ic "$resume; exec ${config.forge.shell}"
        fi
        zellij action save-session
      }
      if [[ $harness == agy ]]; then
        declare_pane >/dev/null 2>&1 &
      else
        declare_pane
      fi
    '';
  };
in {
  imports = [
    ./config.nix
    ./themes/forge-dracula.nix
    ./layouts/default.nix
  ];

  options.forge.zellij.attach = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    default = sessionAttach;
    description = "Session attach for WezTerm spawns: retires servers from an ended login session, then attaches or rebuilds the named session.";
  };

  config = {
    programs.zellij.enable = true;
    home.packages = [agentResume];

    home.activation.zellijPluginGrants = lib.hm.dag.entryAfter ["writeBoundary"] (let
      plugDir = "${config.xdg.configHome}/zellij/plugins";
      permsFile = "${config.home.homeDirectory}/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl";
      grantBlocks = pkgs.writeText "zellij-plugin-grants.kdl" (lib.concatStrings (lib.mapAttrsToList (name: row: ''
          "${plugDir}/${name}.wasm" {
          ${lib.concatMapStrings (p: "    ${p}\n") row.permissions}}
        '')
        plugins));
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
    xdg.configFile = lib.mapAttrs' (name: row: lib.nameValuePair "zellij/plugins/${name}.wasm" {inherit (row) source;}) plugins;
  };
}
