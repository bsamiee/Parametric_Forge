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
      username = config.home.username;
      xdgCacheHome = config.xdg.cacheHome;
    })
    designFontDirectory
    ;
  czkawkaCli = pkgs.czkawka.overrideAttrs {
    cargoBuildFlags = ["--package" "czkawka_cli"];
    buildInputs = [];
    postInstall = "";
    postFixup = "";
  };
  resvg = pkgs.symlinkJoin {
    inherit (pkgs.resvg) pname version meta;
    paths = [pkgs.resvg];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for command in resvg usvg; do
        wrapProgram "$out/bin/$command" --add-flags ${lib.escapeShellArg "--use-fonts-dir ${lib.escapeShellArg designFontDirectory}"}
      done
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
    pkgs.ab-av1
    czkawkaCli
    pkgs.exiftool
    pkgs.ffmpeg-full
    pkgs.ffmpeg-normalize
    pkgs.fonttools
    pkgs.gifski
    pkgs.graphviz
    pkgs.harfbuzz-current.dev
    pkgs.imagemagickBig
    pkgs.img2pdf
    pkgs.jpegli
    pkgs.ocrmypdf
    pkgs.officecli
    pkgs.oxipng
    pkgs.pdfcpu
    pkgs.poppler-utils
    pkgs.potrace
    resvg
    pkgs.ssimulacra2
    pkgs.typst
    pkgs.vl-convert
    pkgs.verapdf-current
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
