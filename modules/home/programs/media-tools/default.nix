{
  lib,
  pkgs,
  toolchainEnv,
  ...
}: let
  czkawkaCli = pkgs.czkawka.overrideAttrs {
    cargoBuildFlags = ["--package" "czkawka_cli"];
    buildInputs = [];
    postInstall = "";
    postFixup = "";
  };
  resvg = pkgs.symlinkJoin {
    inherit (pkgs.resvg-current) pname version meta;
    paths = [pkgs.resvg-current];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for command in resvg usvg; do
        wrapProgram "$out/bin/$command" --add-flags ${lib.escapeShellArg "--use-fonts-dir ${lib.escapeShellArg toolchainEnv.designFontDirectory}"}
      done
    '';
  };
  pins = builtins.fromJSON (builtins.readFile ../../../../overlays/_sources/generated.json);
  uvRun = name: package: command:
    pkgs.writeShellScriptBin name ''
      exec ${pkgs.uv}/bin/uv run -q --no-project --with ${package}==${pins.${package}.version} ${command} "$@"
    '';
  videoSheets = pkgs.writeShellApplication {
    name = "video-sheets";
    runtimeInputs = [pkgs.ffmpeg-full pkgs.gawk pkgs.imagemagickBig];
    text = ''
      video="$(realpath "''${1:?usage: video-sheets <video> <dir> [threshold] [gap] [floor]}")"
      out="''${2:?usage: video-sheets <video> <dir> [threshold] [gap] [floor]}"
      mkdir -p "$out/all" "$out/keep" "$out/sheets"
      cd "$out"
      ffmpeg -nostdin -v error -i "$video" -an -vf "fps=1,select='gte(scene,0)',metadata=print:key=lavfi.scene_score:file=scores.txt" \
        -fps_mode passthrough -start_number 0 -q:v 2 all/%05d.jpg
      awk -v T="''${3:-0.01}" -v G="''${4:-3}" -v F="''${5:-15}" -F= '
        /^frame:/ { n++ }
        /scene_score/ { score[n - 1] = $2 }
        END { last = -1e9; for (i = 0; i < n; i++) if ((score[i + 1] > T && i - last >= G) || i - last >= F || i == n - 1) { print i; last = i } }
      ' scores.txt | while read -r second; do
        printf -v name '%02d_%02d_%02d' $((second / 3600)) $((second % 3600 / 60)) $((second % 60))
        printf -v frame '%05d' "$second"
        cp "all/$frame.jpg" "keep/$name.jpg"
      done
      magick montage -label '%t' -pointsize 22 keep/*.jpg -tile 2x2 -geometry 960x+4+4 sheets/sheet_%03d.jpg
      find keep sheets -name '*.jpg' | awk -F/ '{ count[$1]++ } END { printf "%d frames kept, %d sheets\n", count["keep"], count["sheets"] }'
    '';
  };
in {
  imports = [
    ./gallery-dl.nix
    ./models.nix
    ./svgo.nix
    ./yt-dlp.nix
  ];

  home.packages = [
    # --- [FONTS]
    pkgs.diffenator3
    pkgs.fontc-current
    pkgs.fontforge-current
    pkgs.fontheight-cli
    pkgs.fontspector
    pkgs.fonttools-current
    pkgs.fribidi
    pkgs.gftools
    pkgs.harfbuzz-current.dev
    pkgs.opentype-sanitizer
    pkgs.shaperglot-cli
    pkgs.ttfautohint

    # --- [MEDIA_DOCUMENTS]
    pkgs.ab-av1
    videoSheets
    czkawkaCli
    pkgs.exiftool
    pkgs.ffmpeg-full
    pkgs.ffmpeg-normalize
    pkgs.gifski
    pkgs.graphviz
    pkgs.imagemagickBig
    pkgs.img2pdf
    pkgs.jpegli
    pkgs.jbig2enc
    pkgs.ocrmypdf-current
    pkgs.pngquant
    pkgs.unpaper
    pkgs.officecli-current
    pkgs.oxipng
    pkgs.pdfcpu
    pkgs.poppler-utils
    pkgs.potrace
    resvg
    pkgs.ssimulacra2
    pkgs.typst
    pkgs.vl-convert
    pkgs.verapdf-current

    # --- [MOTION_AND_DELIVERY]
    pkgs.asciinema
    pkgs.asciinema-agg
    pkgs.aubio
    pkgs.audiowaveform
    pkgs.auto-editor
    pkgs.charm-freeze
    pkgs.gifsicle
    pkgs.manim
    pkgs.opencolorio
    pkgs.openexr.bin
    pkgs.openimageio.bin
    pkgs.vhs

    # --- [3D_FILES]
    pkgs.assimp
    pkgs.ifcconvert
    pkgs.repak
    pkgs.retoc
    (uvRun "blender-asset-tracer" "blender-asset-tracer" "bat")
    (uvRun "ifctester" "ifctester" "python -I -m ifctester")
  ];

  programs = {
    # --- [MPV]
    mpv = {
      enable = true;
      config.input-ipc-server = "~~/socket";
    };

    # --- [PANDOC]
    pandoc = {
      enable = true;
      package = pkgs.pandoc-current;
      defaults.pdf-engine = "typst";
    };
  };

  # --- [EXIFTOOL]
  xdg.configFile."exiftool/.ExifTool_config".text = ''
    %Image::ExifTool::UserDefined::Shortcuts = (
        Provenance => [qw(XMP-dc:Creator XMP-dc:Source XMP-dc:Rights XMP-xmpRights:WebStatement XMP-xmpRights:UsageTerms
                          XMP-iptcExt:ArtworkTitle XMP-iptcExt:ArtworkCreator XMP-iptcExt:ArtworkDateCreated XMP-iptcExt:ArtworkSource
                          XMP-iptcExt:ArtworkSourceInventoryNo XMP-iptcExt:ArtworkSourceInvURL)],
        Inventory  => [qw(File:FileType File:MIMEType Composite:ImageSize EXIF:Orientation ICC_Profile:ProfileDescription
                          File:BitsPerSample File:YCbCrSubSampling XMP-dc:Creator XMP-dc:Source XMP-dc:Rights)],
    );
    1;
  '';
}
