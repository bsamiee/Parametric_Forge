# Title         : watchexec.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/watchexec.nix
# ----------------------------------------------------------------------------
# watchexec owner: global ignore estate plus forge-watch, the packaged event rail. --events streams kernel filesystem events as JSON lines for
# agent consumption; both modes share the filter vocabulary (glob, jaq program, extensions, fs-event kinds), and run mode owns busy-policy,
# debounce, origin, postponement, and the child-process lifecycle knobs (stop signal/timeout, process wrapping) over a shell-free argv boundary.
{
  config,
  pkgs,
  ...
}: let
  forgeWatch = pkgs.writeShellApplication {
    name = "forge-watch";
    runtimeInputs = [pkgs.watchexec];
    text = ''
      # Pure printer: help requests route it to stdout with exit 0, usage errors to stderr with exit 64.
      usage() {
        cat <<'EOF'
      usage: forge-watch --events [FILTERS] [PATH ...]
             forge-watch [--busy queue|restart|signal|do-nothing] [--debounce MS]
                         [--origin DIR] [--stdin-quit] [FILTERS] [--postpone]
                         [--stop-signal SIG] [--stop-timeout DUR] [--wrap-process MODE]
                         [PATH ...] -- COMMAND ...
      FILTERS: [--filter GLOB]... [--filter-prog JAQ-EXPR] [--exts LIST] [--fs-events LIST]
      EOF
      }

      events=0 busy=queue debounce=50 origin="" stdin_quit=0 postpone=0
      filter_prog="" exts="" fs_events="" stop_signal="" stop_timeout="" wrap=""
      filters=() paths=() cmd=()
      while (($#)); do
        case "$1" in
          --events) events=1 ;;
          --busy) busy="''${2:?}"; shift ;;
          --debounce) debounce="''${2:?}"; shift ;;
          --origin) origin="''${2:?}"; shift ;;
          --stdin-quit) stdin_quit=1 ;;
          --filter) filters+=("''${2:?}"); shift ;;
          --filter-prog) filter_prog="''${2:?}"; shift ;;
          --exts) exts="''${2:?}"; shift ;;
          --fs-events) fs_events="''${2:?}"; shift ;;
          --stop-signal) stop_signal="''${2:?}"; shift ;;
          --stop-timeout) stop_timeout="''${2:?}"; shift ;;
          --wrap-process) wrap="''${2:?}"; shift ;;
          --postpone) postpone=1 ;;
          --help | -h) usage; exit 0 ;;
          --) shift; cmd=("$@"); break ;;
          --*) usage >&2; exit 64 ;;
          *) paths+=("$1") ;;
        esac
        shift
      done

      # Event-selection flags ride both modes; process-lifecycle flags belong to run mode only.
      argv=(--debounce "''${debounce}ms")
      [ -z "$origin" ] || argv+=(--project-origin "$origin")
      [ "$stdin_quit" = 0 ] || argv+=(--stdin-quit)
      for f in ''${filters[0]+"''${filters[@]}"}; do argv+=(--filter "$f"); done
      [ -z "$filter_prog" ] || argv+=(--filter-prog "$filter_prog")
      [ -z "$exts" ] || argv+=(--exts "$exts")
      [ -z "$fs_events" ] || argv+=(--fs-events "$fs_events")
      for p in ''${paths[0]+"''${paths[@]}"}; do argv+=(--watch "$p"); done

      if [ "$events" = 1 ]; then
        # Pure event stream: one JSON object per kernel event batch, no child process — the agent-facing form of the file-event rail.
        exec watchexec "''${argv[@]}" --only-emit-events --emit-events-to=json-stdio
      fi
      [ "''${#cmd[@]}" -gt 0 ] || { usage >&2; exit 64; }
      # --shell=none always: the -- COMMAND form already carries argv, so no shell reparses the boundary.
      argv+=(--shell=none --on-busy-update "$busy")
      [ -z "$stop_signal" ] || argv+=(--stop-signal "$stop_signal")
      [ -z "$stop_timeout" ] || argv+=(--stop-timeout "$stop_timeout")
      [ -z "$wrap" ] || argv+=(--wrap-process "$wrap")
      [ "$postpone" = 0 ] || argv+=(--postpone)
      exec watchexec "''${argv[@]}" -- "''${cmd[@]}"
    '';
  };
in {
  home.packages = [pkgs.watchexec forgeWatch];
  xdg.configFile."watchexec/ignore".text = config.forge.ignoreEstate.text; # noise taxonomy plus its rendering
}
