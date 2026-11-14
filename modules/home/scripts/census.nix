{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  state = "${config.xdg.stateHome}/forge/tool-census";
  census = pkgs.writeShellApplication {
    name = "tool-census";
    runtimeInputs = [config.programs.mise.package pkgs.coreutils pkgs.jq];
    text = ''
      shopt -s nullglob
      declare -A machine
      described() {
        local real
        real="$(realpath "$1" 2>/dev/null)" || real="$1"
        case "$real" in
          ${builtins.storeDir}/*)
            real="''${real#${builtins.storeDir}/}"
            real="''${real%%/*}"
            if [[ $real =~ -([0-9].*)$ ]]; then
              real="''${BASH_REMATCH[1]}"
              printf 'Nix %s' "''${real%-bin}"
            else
              printf 'Nix'
            fi
            ;;
          ${osConfig.homebrew.prefix}/Cellar/* | ${osConfig.homebrew.prefix}/Caskroom/*)
            real="''${real#${osConfig.homebrew.prefix}/*/*/}"
            printf 'Homebrew %s' "''${real%%/*}"
            ;;
          ${config.xdg.dataHome}/mise/installs/*)
            real="''${real#${config.xdg.dataHome}/mise/installs/*/}"
            printf 'mise %s' "''${real%%/*}"
            ;;
          *) printf '%s' "''${1%/*}" ;;
        esac
      }
      for dir in ${lib.escapeShellArgs ["${config.home.homeDirectory}/.local/bin" "/etc/profiles/per-user/${config.home.username}/bin" "/run/current-system/sw/bin" "${osConfig.homebrew.prefix}/bin" "/usr/local/bin"]}; do
        for file in "$dir"/*; do
          [[ -x $file && -z ''${machine[''${file##*/}]:-} ]] || continue
          machine[''${file##*/}]="$file"
        done
      done
      {
        for manifest in ${config.home.homeDirectory}/Developer/*/{mise.toml,.mise.toml,.config/mise.toml}; do
          root="''${manifest%/*}"
          root="''${root%/.config}"
          while IFS= read -r dir; do
            for file in "$dir"/*; do
              name="''${file##*/}"
              [[ -x $file && -n ''${machine[$name]:-} ]] || continue
              inside="$(described "$file")"
              outside="$(described "''${machine[$name]}")"
              [[ ''${inside#* } == "''${outside#* }" ]] || printf '%s\t%s\t%s\t%s\n' "$inside" "$outside" "$name" "''${root##*/}"
            done
          done < <(mise -C "$root" bin-paths 2>/dev/null || true)
        done | sort -u | jq -Rrs '
          [split("\n")[] | select(length > 0) | split("\t")] | group_by(.[0:2])[]
          | "shadow \(map(.[2]) | unique | join(", ")): \(.[0][0]) runs in \(map(.[3]) | unique | join(", ")); \(.[0][1]) elsewhere"
        '
        jq -r --argjson declared ${lib.escapeShellArg (builtins.toJSON (map (brew: brew.name or brew) osConfig.homebrew.brews))} '
          select(.installed_on_request == true)
          | (input_filename | split("/")) as $path
          | select($declared | index($path[-3]) | not)
          | "undeclared \($path[-3]): ${osConfig.homebrew.prefix}/bin \($path[-2]), no Forge Homebrew row"
        ' ${osConfig.homebrew.prefix}/Cellar/*/*/INSTALL_RECEIPT.json
      } | sort
    '';
  };
in {
  home.packages = [census];

  # --- [TWO_OWNER_CENSUS]
  home.activation.toolCensus = lib.hm.dag.entryAfter ["installPackages" "injectSecretsFromVault"] ''
    run mkdir -p ${lib.escapeShellArg (dirOf state)}
    if [[ ! -v DRY_RUN ]]; then
      ${lib.getExe census} >${lib.escapeShellArg state} 2>&1 || echo "tool-census: did not finish, see ${state}" >&2
      cat ${lib.escapeShellArg state}
    fi
  '';
}
