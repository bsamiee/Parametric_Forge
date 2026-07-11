# Title         : watchexec.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/watchexec.nix
# ----------------------------------------------------------------------------
# watchexec owner: global ignore estate plus forge-watch, the packaged event rail. --events streams kernel filesystem events as JSON lines for
# agent consumption; run mode owns busy-policy, debounce, and origin knobs.
{
  config,
  pkgs,
  ...
}: let
  forgeWatch = pkgs.writeShellApplication {
    name = "forge-watch";
    runtimeInputs = [pkgs.watchexec];
    text = ''
      usage() {
        cat >&2 <<'EOF'
      usage: forge-watch --events [PATH ...]
             forge-watch [--busy queue|restart|signal|do-nothing] [--debounce MS]
                         [--origin DIR] [--stdin-quit] [PATH ...] -- COMMAND ...
      EOF
        exit 64
      }

      events=0 busy=queue debounce=50 origin="" stdin_quit=0
      paths=() cmd=()
      while (($#)); do
        case "$1" in
          --events) events=1 ;;
          --busy) busy="''${2:?}"; shift ;;
          --debounce) debounce="''${2:?}"; shift ;;
          --origin) origin="''${2:?}"; shift ;;
          --stdin-quit) stdin_quit=1 ;;
          --help | -h) usage ;;
          --) shift; cmd=("$@"); break ;;
          *) paths+=("$1") ;;
        esac
        shift
      done

      argv=(--debounce "''${debounce}ms")
      [ -z "$origin" ] || argv+=(--project-origin "$origin")
      [ "$stdin_quit" = 0 ] || argv+=(--stdin-quit)
      for p in ''${paths[0]+"''${paths[@]}"}; do argv+=(--watch "$p"); done

      if [ "$events" = 1 ]; then
        # Pure event stream: one JSON object per kernel event batch, no child process — the agent-facing form of the file-event rail.
        exec watchexec "''${argv[@]}" --only-emit-events --emit-events-to=json-stdio
      fi
      [ "''${#cmd[@]}" -gt 0 ] || usage
      exec watchexec "''${argv[@]}" --on-busy-update "$busy" -- "''${cmd[@]}"
    '';
  };
in {
  home.packages = [pkgs.watchexec forgeWatch];
  xdg.configFile."watchexec/ignore".text = config.forge.ignoreEstate.text; # noise taxonomy plus its rendering
}
