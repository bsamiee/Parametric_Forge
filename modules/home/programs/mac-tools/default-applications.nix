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
      xdgDataHome = config.xdg.dataHome;
    })
    rhinoBin
    ;
  rhinoMajor = "9";
  unrealBinaries = "/Users/Shared/Epic Games/UE_5.8/Engine/Binaries/Mac";
  adobeYear = "2027";
  adobeBeta = true;
  adobeLine =
    if adobeBeta
    then "(Beta)"
    else adobeYear;
  adobeDatedLine =
    if adobeBeta
    then "${adobeYear} (Beta)"
    else adobeYear;
  copyRoot = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}";
  app = id: path: extensions: schemes: {inherit id path extensions schemes;};
  apps = {
    # --- [DOCK_ONLY]
    drafts = app "com.agiletortoise.Drafts-OSX" "/Applications/Drafts.app" [] [];
    chatgpt = app "com.openai.codex" "/Applications/ChatGPT.app" [] [];
    claude = app "com.anthropic.claudefordesktop" "/Applications/Claude.app" [] [];
    messages = app "com.apple.MobileSMS" "/System/Applications/Messages.app" [] [];
    epic = app "com.epicgames.EpicGamesLauncher" "/Applications/Epic Games Launcher.app" [] [];
    creativeCloud = app "com.adobe.acc.AdobeCreativeCloud" "/Applications/Utilities/Adobe Creative Cloud/ACC/Creative Cloud.app" [] [];
    blender = app "org.blenderfoundation.blender" null [] [];
    # --- [BUNDLED_CLI]
    tailscale = app "io.tailscale.ipn.macsys" "/Applications/Tailscale.app" [] [];
    sfSymbols = app "com.apple.SFSymbols" "/Applications/SF Symbols.app" [] [];
    suspiciousPackage = app "com.mothersruin.SuspiciousPackageApp" "/Applications/Suspicious Package.app" [] [];
    spotify = app "com.spotify.client" "/Applications/Spotify.app" [] [];
    afterEffects = app "com.adobe.AfterEffects${lib.optionalString adobeBeta "Beta"}.application" "/Applications/Adobe After Effects ${adobeLine}/Adobe After Effects ${adobeLine}.app" [] [];
    bambuStudio = app "com.bambulab.bambu-studio" "/Applications/BambuStudio.app" [] [];
    orcaSlicer = app "com.orcaslicer.OrcaSlicer" "/Applications/OrcaSlicer.app" [] [];
    pluginInstaller = app "Adobe.UnifiedPluginInstallerAgent" "/Library/Application Support/Adobe/Adobe Desktop Common/RemoteComponents/UPI/UnifiedPluginInstallerAgent/UnifiedPluginInstallerAgent.app" [] [];
    # --- [HANDLERS]
    indesign = app "com.adobe.InDesign" "/Applications/Adobe InDesign ${adobeDatedLine}/Adobe InDesign ${adobeDatedLine}.app" ["indd" "indt" "indb" "idml" "idms" "indl" "icml" "icma" "idap"] [];
    illustrator = app "com.adobe.illustrator${lib.optionalString adobeBeta "Beta"}" "/Applications/Adobe Illustrator ${adobeLine}/Adobe Illustrator.app" ["ai" "ait" "aia" "svg" "svgz" "eps" "ase"] [];
    photoshop = app "com.adobe.Photoshop" "/Applications/Adobe Photoshop ${adobeLine}/Adobe Photoshop ${adobeLine}.app" [
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
    distiller = app "com.adobe.distiller" null ["joboptions"] [];
    typeface = app "com.criminalbird.typeface.beta" null ["otf" "ttf" "ttc" "otc" "woff" "woff2" "dfont" "typeface-license" "typeface-backup"] [];
    colorsync = app "com.apple.ColorSyncUtility" null ["icc" "icm"] [];
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
    preview = app "com.apple.Preview" null ["jpg" "jpeg" "png" "gif" "webp" "heic" "heif" "avif" "jxl"] [];
    rhino = app "com.mcneel.rhinoceros.${rhinoMajor}" "/Applications/Rhino ${rhinoMajor}.app" ["stl" "dwg" "dxf" "obj" "fbx" "ply" "step" "stp" "iges" "igs" "skp" "3ds" "wrl" "3mf" "dgn"] [];
    betterzip = app "com.macitbetter.betterzip" null ["war" "gtar" "cab"] [];
    calibre = app "net.kovidgoyal.calibre" null ["epub"] [];
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
    arc = app "company.thebrowser.Browser" "/Applications/Arc.app" [] [];
    chrome = app "com.google.Chrome" "/Applications/Google Chrome.app" [] ["http" "ftp"];
    superhuman = app "com.superhuman.electron" "/Applications/Superhuman.app" [] ["mailto"];
  };
  bundledCli = lib.mapAttrsToList (name: path: pkgs.writeShellScriptBin name ''exec ${lib.escapeShellArg path} "$@"'') {
    sfsymbols = "${apps.sfSymbols.path}/Contents/Executables/sfsymbols";
    spkg = "${apps.suspiciousPackage.path}/Contents/SharedSupport/spkg";
    spotify_cli = "${apps.spotify.path}/Contents/MacOS/spotify_cli";
    save-to-spotify = "${apps.spotify.path}/Contents/MacOS/save-to-spotify";
    aerender = "${dirOf apps.afterEffects.path}/aerender";
    UnifiedPluginInstallerAgent = "${apps.pluginInstaller.path}/Contents/MacOS/UnifiedPluginInstallerAgent";
    bambu-studio = "${apps.bambuStudio.path}/Contents/MacOS/BambuStudio";
    orca-slicer = "${apps.orcaSlicer.path}/Contents/MacOS/OrcaSlicer";
    UnrealPak = "${unrealBinaries}/UnrealPak";
    UnrealEditor-Cmd = "${unrealBinaries}/UnrealEditor-Cmd";
    zen = "${unrealBinaries}/zen";
  };
  rows = lib.attrValues apps;
  roster = pkgs.writeText "default-applications.json" (builtins.toJSON rows);
  command = pkgs.writeShellApplication {
    name = "default-applications";
    runtimeInputs = [pkgs.jq pkgs.utiluti];
    text = ''
      ${lib.concatMapStrings (r: ''
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ${lib.escapeShellArg r.path}
      '') (lib.filter (r: lib.hasPrefix "${copyRoot}/" (toString r.path)) rows)}
      while IFS=$'\t' read -r kind key id; do
        if [[ $kind == extension ]]; then
          getter=(type get "$key" --extension --bundle-id)
          setter=(type set "$key" --extension "$id")
        else
          getter=(url get "$key" --bundle-id)
          setter=(url set "$key" "$id")
        fi
        if [[ $(utiluti "''${getter[@]}") != "$id" ]]; then
          printf 'setting %s %s → %s\n' "$kind" "$key" "$id"
          utiluti "''${setter[@]}"
        fi
      done < <(jq -r '.[] | . as $app | (.extensions[] | ["extension", ., $app.id]), (.schemes[] | ["scheme", ., $app.id]) | @tsv' ${roster})
    '';
  };
in {
  config = {
    _module.args.applications = apps;
    home = {
      packages = [command] ++ bundledCli;
      file.${rhinoBin}.source = config.lib.file.mkOutOfStoreSymlink "${apps.rhino.path}/Contents/Resources/bin";
      activation.setDefaultApplications = lib.hm.dag.entryAfter ["writeBoundary" "copyApps"] ''
        run ${command}/bin/default-applications
      '';
    };
  };
}
