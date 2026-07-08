# Title         : forge-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools.nix
# ----------------------------------------------------------------------------
# Agent-safe Forge maintenance entrypoints.
{pkgs, ...}: let
  forgeRedeploy = pkgs.writeShellApplication {
    name = "forge-redeploy";
    # No pkgs.nix: Determinate nix resolves from PATH so eval-cores/lazy-trees stay known settings.
    runtimeInputs = [pkgs.coreutils pkgs.git pkgs.nh pkgs.nix-output-monitor pkgs.dix pkgs.nvd pkgs.cachix];
    text = ''
      mode="check"
      case "''${1:-}" in
        --check-only | "")
          mode="check"
          ;;
        --build)
          mode="build"
          ;;
        --switch)
          mode="switch"
          ;;
        --help | -h)
          printf 'Usage: forge-redeploy [--check-only|--build|--switch]\n'
          exit 0
          ;;
        *)
          printf 'forge-redeploy: unknown argument: %s\n' "$1" >&2
          exit 2
          ;;
      esac

      forge_root="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}"
      host="''${FORGE_DARWIN_HOST:-macbook}"
      cache="''${CACHIX_CACHE:-bsamiee}"
      elevation="''${FORGE_REDEPLOY_ELEVATION:-''${NH_ELEVATION_STRATEGY:-auto}}"
      secrets_file="''${FORGE_SECRETS_FILE:-''${XDG_CONFIG_HOME:-$HOME/.config}/hm-op-session.sh}"

      [ -f "$forge_root/flake.nix" ] || {
        printf 'forge-redeploy: missing flake root: %s\n' "$forge_root" >&2
        exit 1
      }
      cd "$forge_root"

      printf 'forge-redeploy: nix=%s\n' "$(command -v nix)"
      nix flake check --print-build-logs

      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-redeploy.XXXXXX")"
      trap 'rm -rf "$tmpdir"' EXIT
      out_link="$tmpdir/system"

      # Token via single env indirection: ambient CACHIX_AUTH_TOKEN wins, secrets file
      # (FORGE_SECRETS_FILE) is the fallback, absence degrades to a skipped push.
      push_cache() {
        if [ -z "''${CACHIX_AUTH_TOKEN:-}" ] && [ -f "$secrets_file" ]; then
          # shellcheck source=/dev/null
          . "$secrets_file" || true
        fi
        if [ -z "''${CACHIX_AUTH_TOKEN:-}" ]; then
          printf 'forge-redeploy: cache push skipped: CACHIX_AUTH_TOKEN unset\n' >&2
          return 0
        fi
        cachix push "$cache" "$1"
      }

      diff_closure() {
        [ -e /run/current-system ] || return 0
        dix /run/current-system "$1" || nvd diff /run/current-system "$1" || true
      }

      case "$mode" in
        check | build)
          nh darwin build --hostname "$host" --out-link "$out_link" --diff never "$forge_root"
          system_path="$(readlink -f "$out_link")"
          diff_closure "$system_path"
          if [ "$mode" = "build" ]; then
            push_cache "$system_path"
          fi
          printf 'forge-redeploy: %s ok system=%s\n' "$mode" "$system_path"
          ;;
        switch)
          nh darwin switch --hostname "$host" --out-link "$out_link" --diff always \
            --show-activation-logs --elevation-strategy "$elevation" "$forge_root"
          system_path="$(readlink -f "$out_link")"
          push_cache "$system_path"
          printf 'forge-redeploy: switch ok system=%s\n' "$system_path"
          ;;
      esac
    '';
  };

  forgeContainerDoctor = pkgs.writeShellApplication {
    name = "forge-container-doctor";
    runtimeInputs = [pkgs.coreutils pkgs.docker-client pkgs.docker-compose pkgs.jq];
    text = ''
      socket="''${DOCKER_HOST:-unix://$HOME/.local/share/colima/default/docker.sock}"
      config="''${DOCKER_CONFIG:-$HOME/.config/docker}"
      printf 'container-doctor\tendpoint_kind=%s\n' "''${socket%%://*}"
      if [[ "$socket" == unix://* ]]; then
        socket_path="''${socket#unix://}"
        [ -S "$socket_path" ] || {
          printf 'container-doctor\tok=false\treason=missing-socket\n'
          exit 1
        }
      fi
      if [ -f "$config/config.json" ]; then
        helper_count="$(jq -r '((.credsStore // .credStore // "") != "") as $store | (($store | if . then 1 else 0 end) + ((.credHelpers // {}) | length))' "$config/config.json")"
      else
        helper_count=0
      fi
      DOCKER_HOST="$socket" DOCKER_CONFIG="$config" docker version >/dev/null
      DOCKER_HOST="$socket" DOCKER_CONFIG="$config" docker compose version >/dev/null
      printf 'container-doctor\tok=true\tcredential_helpers=%s\n' "$helper_count"
    '';
  };
in {
  home.packages = [
    forgeRedeploy
    forgeContainerDoctor
  ];
}
