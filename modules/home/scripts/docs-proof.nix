{
  config,
  host,
  launchdAgent,
  lib,
  pkgs,
  ...
}: let
  docs = "${host.flakeRoot}/docs/tooling";
  docsProof = pkgs.writeShellApplication {
    name = "docs-proof";
    runtimeInputs = [pkgs.diffutils pkgs.mdsh];
    text = ''
      if [[ -z ''${DOCS_PROOF_SHELL:-} ]]; then
        cd "$HOME"
        exec /usr/bin/env -i HOME="$HOME" USER="$USER" TERM=dumb DOCS_PROOF_SHELL=1 ${config.forge.shell} -lc "exec \"\$0\" \"\$@\"" "$0" "$@"
      fi
      write=0
      if [[ ''${1:-} == --write ]]; then
        write=1
        shift
      fi
      (($#)) || set -- ${docs}/access/*.md ${docs}/GUIDE.md
      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT
      drifted=0
      printf 'docs-proof %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)"
      for file in "$@"; do
        rm -f "$work/proved"
        if ! mdsh --work_dir "$HOME" -i "$file" -o "$work/proved" 2>"$work/errors"; then
          printf 'unproved %s\n' "$file"
          sed -n '/^ERROR/,$p' "$work/errors"
          drifted=$((drifted + 1))
        elif [[ -e $work/proved ]] && ! diff -u "$file" "$work/proved"; then
          drifted=$((drifted + 1))
          ((write == 0)) || cat "$work/proved" >"$file"
        fi
      done
      printf 'docs-proof: %d of %d files drifted\n' "$drifted" "$#"
      ((drifted == 0))
    '';
  };
in {
  home.packages = [docsProof pkgs.mdsh];

  # --- [DAILY_PROOF]
  launchd.agents.docs-proof = launchdAgent {
    name = "docs-proof";
    argv = [(lib.getExe docsProof)];
    StartCalendarInterval = [
      {
        Hour = 9;
        Minute = 15;
      }
    ];
  };
}
