{
  host,
  lib,
  pkgs,
  ...
}: let
  exported = ["atuin" "fd" "gh" "hurl" "jq" "mise" "nix" "pulumi" "rg" "tailscale" "uv" "xh" "zellij"];
  walked = ["doppler" "hostinger" "op" "rclone"];
  shaped = {
    mise = "mise ls --json";
    tailscale = "tailscale status --json";
    zellij = "zellij list-sessions --short --no-formatting | head -1 | xargs -I{} zellij --session {} action list-panes --json --all";
  };
  shape = pkgs.writeText "json-shape.jq" ''
    [paths(scalars) as $path | "\($path | map(if type == "number" then "[]" else . end) | join(".")): \(getpath($path) | type)"] | unique[]
  '';
  cliContracts = pkgs.writeShellApplication {
    name = "cli-contracts";
    runtimeInputs = [pkgs.carapace pkgs.coreutils pkgs.diffutils pkgs.gnugrep pkgs.gnused pkgs.jq];
    text = ''
      out="''${1:-${host.flakeRoot}/docs/tooling/contracts}"
      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT
      walk() {
        local help sub
        help="$("$@" --help 2>/dev/null)" || return 0
        sed -n '/^\(Global \)\{0,1\}Flags:/,/^$/p' <<<"$help" | grep -o -- '--[a-z0-9][a-z0-9-]*' | sort -u | sed "s|^|$* |"
        while read -r sub; do
          [[ $sub == help || $sub == completion ]] || { printf '%s %s\n' "$*" "$sub"; walk "$@" "$sub"; }
        done < <(sed -n '/^Available Commands:/,/^$/p' <<<"$help" | sed -n 's/^  \([a-z0-9][a-z0-9-]*\) .*/\1/p')
      }
      for tool in ${lib.escapeShellArgs exported}; do
        carapace "$tool" export | jq -r 'def rows($path): $path, ((.LocalFlags // [])[] | "\($path) --\(.Longhand // .Shorthand)"), ((.Commands // [])[] | rows("\($path) \(.Name)")); rows(.Name)' | sort -u >"$work/$tool.flags"
      done
      for tool in ${lib.escapeShellArgs walked}; do
        walk "$tool" | sort -u >"$work/$tool.flags"
      done
      ${lib.concatStrings (lib.mapAttrsToList (tool: sample: ''
          { ${sample}; } 2>/dev/null | jq -r -f ${shape} >"$work/${tool}.shape" || true
        '')
        shaped)}
      mkdir -p "$out"
      for contract in "$work"/*; do
        name="''${contract##*/}"
        if [[ -f $out/$name ]]; then
          diff -u --label "$name before" --label "$name now" "$out/$name" "$contract" || true
        else
          printf 'new contract %s: %s lines\n' "$name" "$(wc -l <"$contract")"
        fi
        cp "$contract" "$out/$name"
      done
    '';
  };
in {
  home.packages = [cliContracts];
}
