# Title         : default-applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/default-applications.nix
# ----------------------------------------------------------------------------
# Application row owner and native association reconcile. One row per application (bundle id, path, handled extensions and schemes) feeds
# the handler reconcile, the Dock, and LinearMouse. At every switch a handler that differs from its row is set. A row names the app that opens
# the type: LaunchServices takes an app that never claims the type (Rhino for the CAD formats it imports) and an extension with no system type
# (a dynamic UTI such as .sln) alike, and utiluti raises no per-type consent dialog on macOS 26. utiluti exits non-zero on an application it
# cannot resolve, so a renamed bundle fails the switch by name.
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
  copyRoot = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}";
  app = id: path: extensions: schemes: {inherit id path extensions schemes;};
  apps = {
    # --- [DOCK_ONLY]
    heptabase = app "app.projectmeta.projectmeta" "/Applications/Heptabase.app" [] [];
    drafts = app "com.agiletortoise.Drafts-OSX" "/Applications/Drafts.app" [] [];
    chatgpt = app "com.openai.codex" "/Applications/ChatGPT.app" [] [];
    claude = app "com.anthropic.claudefordesktop" "/Applications/Claude.app" [] [];
    messages = app "com.apple.MobileSMS" "/System/Applications/Messages.app" [] [];
    creativeCloud = app "com.adobe.acc.AdobeCreativeCloud" "/Applications/Utilities/Adobe Creative Cloud/ACC/Creative Cloud.app" [] [];
    blender = app "org.blenderfoundation.blender" "/Applications/Blender.app" [] [];
    linearmouse = app "com.lujjjh.LinearMouse" "/Applications/LinearMouse.app" [] [];
    # --- [HANDLERS]
    # ICAP is an InCopy-bound package; InDesign explicitly declares role None. IDAP is its supported return package.
    indesign = app "com.adobe.InDesign" "/Applications/Adobe InDesign 2027 (Beta)/Adobe InDesign 2027 (Beta).app" ["indd" "indt" "indb" "idml" "idms" "indl" "icml" "icma" "idap"] [];
    illustrator = app "com.adobe.illustratorBeta" "/Applications/Adobe Illustrator (Beta)/Adobe Illustrator.app" ["ai" "ait" "aia" "svg" "svgz" "eps" "ase"] [];
    photoshop = app "com.adobe.Photoshop" "/Applications/Adobe Photoshop (Beta)/Adobe Photoshop (Beta).app" [
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
    ] [];
    acrobat = app "com.adobe.Acrobat.Pro" "/Applications/Adobe Acrobat DC/Adobe Acrobat.app" ["pdf" "fdf" "xfdf" "pdx" "sequ"] [];
    distiller = app "com.adobe.distiller" "/Applications/Adobe Acrobat DC/Acrobat Distiller.app" ["joboptions"] [];
    typeface = app "com.criminalbird.typeface.beta" "/Applications/Typeface-beta.app" ["otf" "ttf" "ttc" "otc" "woff" "woff2" "dfont" "typeface-license" "typeface-backup"] [];
    colorsync = app "com.apple.ColorSyncUtility" "/System/Applications/Utilities/ColorSync Utility.app" ["icc" "icm"] [];
    # .typ now resolves to its own dynamic type; never assign Oracle's older shared SQL declaration. .ts is MPEG transport; .vg.json shares JSON.
    # Do not broaden script editing into generic JSON/XML/data, or assign ambiguous Photoshop/CAD preset extensions.
    vscode = app "com.microsoft.VSCode" "/Applications/Visual Studio Code.app" [
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
    ] [];
    preview = app "com.apple.Preview" "/System/Applications/Preview.app" ["jpg" "jpeg" "png" "gif" "webp" "heic" "heif" "avif" "jxl"] [];
    # lrcat-data is a catalog companion with role None, not a separately openable catalog.
    lightroom = app "com.adobe.LightroomClassicCC7" "/Applications/Adobe Lightroom Classic/Adobe Lightroom Classic.app" ["lrcat"] [];
    # Rhino's own document types plus the formats its Import command reads (docs.mcneel.com/rhino/9 file formats index); dae, sat, and x3d
    # are export-only there and stay with the system viewers.
    rhino = app "com.mcneel.rhinoceros.9" rhinoApp ["stl" "dwg" "dxf" "obj" "fbx" "ply" "step" "stp" "iges" "igs" "skp" "3ds" "wrl" "3mf" "dgn"] [];
    # BetterZip's Archive Types tab claims the formats it lists; these three resolve through system type identifiers the tab cannot take
    # (com.sun.web-application-archive, org.gnu.gnu-tar-archive, com.microsoft.cab). ePub stays unchecked there so calibre keeps the type.
    betterzip = app "com.macitbetter.betterzip" "/Applications/BetterZip.app" ["war" "gtar" "cab"] [];
    calibre = app "net.kovidgoyal.calibre" "/Applications/calibre.app" ["epub"] [];
    # The one media player Forge installs, copied by Home Manager into its app directory.
    mpv = app "io.mpv" "${copyRoot}/mpv.app" [
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
    ] [];
    wezterm = app "com.github.wez.wezterm" "/Applications/WezTerm.app" ["command" "tool"] [];
    arc = app "company.thebrowser.Browser" "/Applications/Arc.app" [] ["http" "ftp"];
    superhuman = app "com.superhuman.electron" "/Applications/Superhuman.app" [] ["mailto"];
  };
  rows = lib.attrValues apps;
  roster = pkgs.writeText "default-applications.json" (builtins.toJSON rows);
  command = pkgs.writeShellApplication {
    name = "default-applications";
    runtimeInputs = [pkgs.jq pkgs.utiluti];
    # A bundle copyApps rewrote this generation reaches the LaunchServices database on its next Finder scan or launch; registering each
    # copied bundle first makes the handler read below current.
    text = ''
      ${lib.concatMapStrings (r: ''
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ${lib.escapeShellArg r.path}
      '') (lib.filter (r: lib.hasPrefix "${copyRoot}/" r.path) rows)}
      while IFS=$'\t' read -r kind key id path; do
        if [[ $kind == extension ]]; then
          getter=(type get "$key" --extension)
          setter=(type set "$key" --extension "$id")
        else
          getter=(url get "$key")
          setter=(url set "$key" "$id")
        fi
        if [[ $(utiluti "''${getter[@]}") != "$path" ]]; then
          printf 'setting %s %s → %s\n' "$kind" "$key" "$path"
          utiluti "''${setter[@]}"
        fi
      done < <(jq -r '.[] | . as $app | (.extensions[] | ["extension", ., $app.id, $app.path]), (.schemes[] | ["scheme", ., $app.id, $app.path]) | @tsv' ${roster})
    '';
  };
in {
  options.forge.apps = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = apps;
    description = "Application rows (bundle id, path, handled extensions and schemes) read by the handler reconcile, the Dock, and LinearMouse.";
  };

  config = {
    home.packages = [command];
    home.activation.setDefaultApplications = lib.hm.dag.entryAfter ["writeBoundary" "copyApps"] ''
      run ${command}/bin/default-applications
    '';
  };
}
