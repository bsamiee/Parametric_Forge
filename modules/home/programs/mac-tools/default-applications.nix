# Title         : default-applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/default-applications.nix
# ----------------------------------------------------------------------------
# One native association owner. Exact installed bundle identities and paths are checked before and after changes.
{
  config,
  lib,
  pkgs,
  ...
}: let
  app = id: path: extensions: schemes: {inherit id path extensions schemes;};
  applications = [
    # ICAP is an InCopy-bound package; InDesign explicitly declares role None. IDAP is its supported return package.
    (app "com.adobe.InDesign" "/Applications/Adobe InDesign 2026 (Beta)/Adobe InDesign 2026 (Beta).app" ["indd" "indt" "indb" "idml" "idms" "indl" "icml" "icma" "idap"] [])
    (app "com.adobe.illustratorBeta" "/Applications/Adobe Illustrator (Beta)/Adobe Illustrator.app" ["ai" "ait" "aia" "svg" "svgz" "eps" "ase"] [])
    (app "com.adobe.Photoshop" "/Applications/Adobe Photoshop (Beta)/Adobe Photoshop (Beta).app" [
      "psd"
      "psb"
      "psdt"
      "psdc"
      "tif"
      "tiff"
      "exr"
      "hdr"
      "3fr"
      "arw"
      "cr2"
      "cr3"
      "crw"
      "dcr"
      "dng"
      "erf"
      "fff"
      "gpr"
      "iiq"
      "kdc"
      "mef"
      "mfw"
      "mos"
      "mrw"
      "nef"
      "nefx"
      "nrw"
      "orf"
      "ori"
      "pef"
      "raf"
      "rw2"
      "rwl"
      "srf"
      "srw"
      "x3f"
    ] [])
    (app "com.adobe.Acrobat.Pro" "/Applications/Adobe Acrobat DC/Adobe Acrobat.app" ["pdf" "fdf" "xfdf" "pdx" "sequ"] [])
    (app "com.adobe.distiller" "/Applications/Adobe Acrobat DC/Acrobat Distiller.app" ["joboptions"] [])
    (app "com.criminalbird.typeface.beta" "/Applications/Typeface-beta.app" ["otf" "ttf" "ttc" "otc" "woff" "woff2" "typeface-license" "typeface-backup"] [])
    (app "com.aescripts.ZXP-Installer" "/Applications/ZXP Installer.app" ["zxp" "ccx"] [])
    (app "com.apple.ColorSyncUtility" "/System/Applications/Utilities/ColorSync Utility.app" ["icc" "icm"] [])
    # .typ now resolves to its own dynamic type; never assign Oracle's older shared SQL declaration. .ts is MPEG transport; .vg.json shares JSON.
    # Do not broaden script editing into generic JSON/XML/data, or assign ambiguous Photoshop/CAD preset extensions.
    (app "com.microsoft.VSCode" "/Applications/Visual Studio Code.app" ["txt" "md" "yaml" "yml" "nix" "lua" "py" "js" "jsx" "idjs" "psjs" "typ" "rs" "sh" "sql" "csv" "log"] [])
    (app "com.apple.Preview" "/System/Applications/Preview.app" ["jpg" "jpeg" "png" "gif" "webp" "heic" "heif" "avif" "jxl"] [])
    # lrcat-data is a catalog companion with role None, not a separately openable catalog.
    (app "com.adobe.LightroomClassicCC7" "/Applications/Adobe Lightroom Classic/Adobe Lightroom Classic.app" ["lrcat"] [])
    (app "com.mcneel.rhinoceros.9" "/Applications/RhinoBETA.app" ["stl"] [])
    (app "company.thebrowser.Browser" "/Applications/Arc.app" [] ["http" "ftp"])
    (app "com.superhuman.electron" "/Applications/Superhuman.app" [] ["mailto"])
  ];
  roster = pkgs.writeText "forge-default-applications.json" (builtins.toJSON applications);
  receipts = import ../../../common/receipts.nix;
  command = pkgs.writeShellApplication {
    name = "forge-default-applications";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.utiluti];
    text = ''
      mode="''${1:-apply}"
      [[ $# -le 1 && ( $mode == apply || $mode == check ) ]] || { echo 'usage: forge-default-applications [apply|check]' >&2; exit 2; }
      receipt_log=${lib.escapeShellArg "${config.home.homeDirectory}/Library/Logs/forge-default-applications.receipts.log"}
      receipt_surface="forge-default-applications"
      ${receipts.fold}
      changed=0
      checked=0
      skipped=0
      failures=0
      declare -A skip=()
      finish() {
        local result=$1
        append_receipt "$(printf 'verb=%s\tchecked=%s\tchanged=%s\tskipped=%s\tfailures=%s\tresult=%s' "$mode" "$checked" "$changed" "$skipped" "$failures" "$result")"
      }
      trap 'association_status=$?; if (( association_status == 0 )); then finish ok; else finish failed; fi' EXIT
      # Preflight every destination before changing any handler. Nested Adobe helpers are part of the intended bundle. An application that is
      # not installed is a skipped row under apply — the activation runs under set -e and a renamed Beta bundle must never abort a switch —
      # and a hard failure under check, where the operator asked for the full roster.
      while IFS=$'\t' read -r id path; do
        if [[ ! -d $path ]]; then
          [[ $mode == apply ]] || { printf 'application not installed: %s\n' "$path" >&2; exit 1; }
          printf 'skipping absent application: %s\n' "$path" >&2
          skip[$id]=1
          ((++skipped))
          continue
        fi
        actual=$(utiluti app identifier "$path")
        [[ $actual == "$id" ]] || { printf 'bundle identity mismatch: %s\n' "$path" >&2; exit 1; }
        registered=$(utiluti app for-identifier "$id")
        found=0
        competing=""
        while IFS= read -r candidate; do
          [[ $candidate != "$path" ]] || found=1
          # A mounted disk image (an installer or an updater staging volume) is never an installation, so /Volumes copies never compete.
          if [[ -d $candidate && $candidate != "$path" && $candidate != "$path/"* && $candidate != /Volumes/* ]]; then
            competing=$candidate
          fi
        done <<<"$registered"
        # A second real copy makes the handler ambiguous: the row is skipped under apply (LaunchServices may bind either copy) and fails check.
        if [[ -n $competing ]]; then
          printf 'competing installed application: %s (%s)\n' "$competing" "$id" >&2
          [[ $mode == apply ]] || exit 1
          skip[$id]=1
          ((++skipped))
          continue
        fi
        [[ $found == 1 ]] || { printf 'application is not registered at expected path: %s\n' "$path" >&2; exit 1; }
      done < <(jq -r '.[] | [.id, .path] | @tsv' ${roster})
      while IFS=$'\t' read -r kind key id path; do
        [[ -z ''${skip[$id]:-} ]] || continue
        if [[ $kind == extension ]]; then
          args=(type get "$key" --extension)
          setter=(type set "$key" --extension "$id")
        else
          args=(url get "$key")
          setter=(url set "$key" "$id")
        fi
        actual_path=$(utiluti "''${args[@]}" 2>/dev/null) || actual_path=""
        actual_id=$(utiluti "''${args[@]}" --bundle-id 2>/dev/null) || actual_id=""
        if [[ $actual_path != "$path" || $actual_id != "$id" ]]; then
          if [[ $mode == apply ]]; then
            printf 'setting %s %s → %s\n' "$kind" "$key" "$path"
            utiluti "''${setter[@]}"
            actual_path=$(utiluti "''${args[@]}")
            actual_id=$(utiluti "''${args[@]}" --bundle-id)
            ((++changed))
          fi
          if [[ $actual_path != "$path" || $actual_id != "$id" ]]; then
            printf 'handler mismatch: %s %s; wanted %s (%s); found %s (%s)\n' "$kind" "$key" "$path" "$id" "$actual_path" "$actual_id" >&2
            ((++failures))
          fi
        fi
        ((++checked))
      done < <(jq -r '.[] | . as $app | (.extensions[] | ["extension", ., $app.id, $app.path]), (.schemes[] | ["scheme", ., $app.id, $app.path]) | @tsv' ${roster})
      [[ $failures == 0 ]] || exit 1
      printf 'default applications: %s verified, %s changed, %s applications skipped\n' "$checked" "$changed" "$skipped"
    '';
  };
in {
  home.packages = [command];
  home.activation.setDefaultApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${command}/bin/forge-default-applications apply
  '';
}
