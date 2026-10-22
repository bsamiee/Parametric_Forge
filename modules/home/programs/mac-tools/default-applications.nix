# Title         : default-applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/default-applications.nix
# ----------------------------------------------------------------------------
# One native association owner, reconciled at every switch: a handler that differs from its row is set. A row names the app that opens the
# type: LaunchServices takes an app that never claims the type (Rhino for the CAD formats it imports) and an extension with no system type (a
# dynamic UTI such as .sln) alike, and utiluti raises no per-type consent dialog on macOS 26.
{
  config,
  lib,
  pkgs,
  toolchainEnvFor,
  ...
}: let
  inherit
    (toolchainEnvFor {
      home = config.home.homeDirectory;
      inherit (config.home) username;
      xdgCacheHome = config.xdg.cacheHome;
    })
    rhinoApp
    ;
  app = id: path: extensions: schemes: {inherit id path extensions schemes;};
  applications = [
    # ICAP is an InCopy-bound package; InDesign explicitly declares role None. IDAP is its supported return package.
    (app "com.adobe.InDesign" "/Applications/Adobe InDesign 2027 (Beta)/Adobe InDesign 2027 (Beta).app" ["indd" "indt" "indb" "idml" "idms" "indl" "icml" "icma" "idap"] [])
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
    (app "com.criminalbird.typeface.beta" "/Applications/Typeface-beta.app" ["otf" "ttf" "ttc" "otc" "woff" "woff2" "dfont" "typeface-license" "typeface-backup"] [])
    (app "com.aescripts.ZXP-Installer" "/Applications/ZXP Installer.app" ["zxp" "ccx"] [])
    (app "com.apple.ColorSyncUtility" "/System/Applications/Utilities/ColorSync Utility.app" ["icc" "icm"] [])
    # .typ now resolves to its own dynamic type; never assign Oracle's older shared SQL declaration. .ts is MPEG transport; .vg.json shares JSON.
    # Do not broaden script editing into generic JSON/XML/data, or assign ambiguous Photoshop/CAD preset extensions.
    (app "com.microsoft.VSCode" "/Applications/Visual Studio Code.app" [
      "txt"
      "md"
      "mdx"
      "yaml"
      "yml"
      "nix"
      "lua"
      "py"
      "js"
      "jsx"
      "idjs"
      "psjs"
      "typ"
      "rs"
      "sh"
      "zsh"
      "bash"
      "rb"
      "php"
      "pl"
      "c"
      "h"
      "cpp"
      "hpp"
      "kt"
      "css"
      "jsonc"
      "json5"
      "conf"
      "bib"
      "env"
      "sql"
      "csv"
      "tsv"
      "log"
      "sln"
      "slnx"
      "props"
      "targets"
      "resolved"
    ] [])
    (app "com.apple.Preview" "/System/Applications/Preview.app" ["jpg" "jpeg" "png" "gif" "webp" "heic" "heif" "avif" "jxl"] [])
    # lrcat-data is a catalog companion with role None, not a separately openable catalog.
    (app "com.adobe.LightroomClassicCC7" "/Applications/Adobe Lightroom Classic/Adobe Lightroom Classic.app" ["lrcat"] [])
    # Rhino's own document types plus the formats its Import command reads (docs.mcneel.com/rhino/9 file formats index); dae, sat, and x3d
    # are export-only there and stay with the system viewers.
    (app "com.mcneel.rhinoceros.9" rhinoApp ["stl" "dwg" "dxf" "obj" "fbx" "ply" "step" "stp" "iges" "igs" "skp" "3ds" "wrl" "3mf" "dgn"] [])
    # BetterZip's Archive Types tab claims the formats it lists; these three resolve through system type identifiers the tab cannot take
    # (com.sun.web-application-archive, org.gnu.gnu-tar-archive, com.microsoft.cab). ePub stays unchecked there so calibre keeps the type.
    (app "com.macitbetter.betterzip" "/Applications/BetterZip.app" ["war" "gtar" "cab"] [])
    (app "net.kovidgoyal.calibre" "/Applications/calibre.app" ["epub"] [])
    # The one media player Forge installs, projected by Home Manager as an app bundle.
    (app "io.mpv" "${config.home.homeDirectory}/Applications/Home Manager Apps/mpv.app" [
      "mp3"
      "m4a"
      "aac"
      "wav"
      "aiff"
      "aif"
      "caf"
      "ogg"
      "opus"
      "mid"
      "midi"
      "mp4"
      "m4v"
      "mov"
      "avi"
      "wmv"
      "mpg"
      "mpeg"
      "mts"
      "m2ts"
      "webm"
    ] [])
    (app "com.github.wez.wezterm" "/Applications/WezTerm.app" ["command" "tool"] [])
    (app "company.thebrowser.Browser" "/Applications/Arc.app" [] ["http" "ftp"])
    (app "com.superhuman.electron" "/Applications/Superhuman.app" [] ["mailto"])
  ];
  roster = pkgs.writeText "default-applications.json" (builtins.toJSON applications);
  command = pkgs.writeShellApplication {
    name = "default-applications";
    runtimeInputs = [pkgs.jq pkgs.utiluti];
    text = ''
      declare -A skip=()
      # An application that is not installed is a skipped row, so a renamed Beta bundle never aborts a switch.
      while IFS=$'\t' read -r id path; do
        if [[ ! -d $path ]]; then
          printf 'skipping absent application: %s\n' "$path" >&2
          skip[$id]=1
          continue
        fi
        # A bundle copyApps wrote this generation reaches the LaunchServices database on its next Finder scan or launch; registering it here
        # makes the for-identifier read below current for a Home Manager Apps copy that changed its store path.
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$path"
        # A second real copy makes the handler ambiguous (LaunchServices may bind either), so the row is skipped. A mounted disk image (an
        # installer or an updater staging volume) is never an installation, and a Nix store bundle is the source a Home Manager Apps copy
        # resolves to when it launches, so neither competes.
        while IFS= read -r candidate; do
          if [[ -d $candidate && $candidate != "$path" && $candidate != "$path/"* && $candidate != /Volumes/* && $candidate != /nix/store/* ]]; then
            printf 'skipping %s: competing installed application %s\n' "$id" "$candidate" >&2
            skip[$id]=1
          fi
        done < <(utiluti app for-identifier "$id")
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
          printf 'setting %s %s → %s\n' "$kind" "$key" "$path"
          utiluti "''${setter[@]}"
        fi
      done < <(jq -r '.[] | . as $app | (.extensions[] | ["extension", ., $app.id, $app.path]), (.schemes[] | ["scheme", ., $app.id, $app.path]) | @tsv' ${roster})
    '';
  };
in {
  home.packages = [command];
  home.activation.setDefaultApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${command}/bin/default-applications
  '';
}
