# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/media.nix
# ----------------------------------------------------------------------------
# Media processing tool aliases - unified namespace for audio, video, image, and document processing

{ lib, ... }:

let
  # --- Media Tool Commands (dynamically prefixed with 'm') -----------------
  mediaCommands = {
    # --- FFmpeg Video/Audio Processing ------------------------------------
    # Video format conversion with optimal defaults
    convert = "f() { ffmpeg -i \"\$1\" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k \"\${2:-\${1%.*}_converted.mp4}\"; }; f";
    compress = "f() { ffmpeg -i \"\$1\" -c:v libx264 -preset slow -crf 28 -c:a aac -b:a 96k \"\${2:-\${1%.*}_compressed.mp4}\"; }; f";
    audio = "f() { ffmpeg -i \"\$1\" -vn -c:a mp3 -b:a 192k \"\${2:-\${1%.*}.mp3}\"; }; f";
    gif = "f() { start=\${3:-0}; duration=\${4:-10}; ffmpeg -ss \$start -t \$duration -i \"\$1\" -vf \"fps=15,scale=720:-1:flags=lanczos,palettegen\" palette.png && ffmpeg -ss \$start -t \$duration -i \"\$1\" -i palette.png -filter_complex \"fps=15,scale=720:-1:flags=lanczos[v];[v][1:v]paletteuse\" \"\${2:-\${1%.*}.gif}\" && rm palette.png; }; f";
    thumbnail = "f() { time=\${3:-00:00:01}; ffmpeg -i \"\$1\" -ss \$time -vframes 1 -q:v 2 \"\${2:-\${1%.*}_thumb.jpg}\"; }; f";

    # Video analysis and information
    info = "f() { ffprobe -v quiet -print_format json -show_format -show_streams \"\$1\" | jq '{format: .format | {filename, duration, size, bit_rate}, streams: [.streams[] | {codec_type, codec_name, width, height, duration}]}'; }; f";
    duration = "f() { ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 \"\$1\"; }; f";

    # Advanced video operations
    concat = "f() { echo 'Creating file list...'; printf \"file '%s'\n\" \"\$@\" > /tmp/ffmpeg_files.txt && ffmpeg -f concat -safe 0 -i /tmp/ffmpeg_files.txt -c copy \"merged_\$(date +%Y%m%d_%H%M%S).mp4\" && rm /tmp/ffmpeg_files.txt; }; f";
    trim = "f() { start=\$2; end=\$3; ffmpeg -i \"\$1\" -ss \$start -to \$end -c copy \"\${4:-\${1%.*}_trimmed.mp4}\"; }; f";
    loop = "f() { times=\${3:-5}; ffmpeg -stream_loop \$times -i \"\$1\" -c copy \"\${2:-\${1%.*}_loop.mp4}\"; }; f";

    # --- HandBrake Video Transcoding --------------------------------------
    # Professional video transcoding with presets and hardware acceleration
    handbrake = "f() { HandBrakeCLI \"\$@\"; }; f"; # General HandBrake CLI wrapper
    transcode = "f() { HandBrakeCLI -i \"\$1\" -o \"\${2:-\${1%.*}_transcoded.mp4}\" \"\${@:3}\"; }; f"; # Basic transcode
    h264 = "f() { HandBrakeCLI -i \"\$1\" -o \"\${2:-\${1%.*}_h264.mp4}\" -e x264 -q \${3:-23} \"\${@:4}\"; }; f"; # H.264 encode
    h265 = "f() { HandBrakeCLI -i \"\$1\" -o \"\${2:-\${1%.*}_h265.mp4}\" -e x265 -q \${3:-28} \"\${@:4}\"; }; f"; # H.265/HEVC encode
    preset = "f() { preset=\${2:-\"Fast 1080p30\"}; HandBrakeCLI -i \"\$1\" -o \"\${3:-\${1%.*}_\${preset// /_}.mp4}\" -Z \"\$preset\" \"\${@:4}\"; }; f"; # Use preset
    scan = "f() { HandBrakeCLI -i \"\$1\" --scan \"\${@:2}\"; }; f"; # Scan source for info

    # --- ImageMagick Image Processing -------------------------------------
    # Basic image operations with quality defaults
    img = "f() { magick \"\$1\" -quality 85 \"\${2:-\${1%.*}_converted.\${2##*.}}\"; }; f";
    resize = "f() { size=\${2:-50%}; magick \"\$1\" -resize \$size -quality 85 \"\${3:-\${1%.*}_resized.\${1##*.}}\"; }; f";
    crop = "f() { geometry=\$2; magick \"\$1\" -crop \$geometry -quality 85 \"\${3:-\${1%.*}_cropped.\${1##*.}}\"; }; f";
    rotate = "f() { angle=\${2:-90}; magick \"\$1\" -rotate \$angle -quality 85 \"\${3:-\${1%.*}_rotated.\${1##*.}}\"; }; f";

    # Image format conversions with optimization
    jpg = "f() { magick \"\$1\" -quality 85 -format jpg \"\${2:-\${1%.*}.jpg}\"; }; f";
    png = "f() { magick \"\$1\" -quality 95 -format png \"\${2:-\${1%.*}.png}\"; }; f";
    webp = "f() { magick \"\$1\" -quality 80 -format webp \"\${2:-\${1%.*}.webp}\"; }; f";

    # Image analysis and batch operations
    identify = "f() { magick identify -verbose \"\$1\" | head -20; }; f";
    batch = "f() { operation=\$1; shift; for img in \"\$@\"; do echo \"Processing: \$img\"; m\$operation \"\$img\"; done; }; f";

    # Image optimization
    optimize = "f() { magick \"\$1\" -strip -interlace Plane -quality 85 \"\${2:-\${1%.*}_optimized.\${1##*.}}\"; }; f";
    thumbnail-img = "f() { size=\${2:-200x200}; magick \"\$1\" -thumbnail \$size -quality 85 \"\${3:-\${1%.*}_thumb.\${1##*.}}\"; }; f";

    # --- libvips High-Performance Image Processing ---------------------------
    # Fast, low-memory image operations (4-5x faster than ImageMagick)
    vips = "f() { vips \"\$@\"; }; f"; # General vips command wrapper
    vipsthumbnail = "f() { vipsthumbnail \"\$1\" --size \${2:-256} -o \"\${3:-tn_%s.jpg}\"; }; f"; # Fast thumbnail generation
    vipsheader = "f() { vipsheader \"\$1\"; }; f"; # Image metadata inspection
    vipsresize = "f() { vips resize \"\$1\" \"\${2:-\${1%.*}_resized.\${1##*.}}\" \${3:-0.5}; }; f"; # High-performance resize
    vipsshrink = "f() { vips shrink \"\$1\" \"\${2:-\${1%.*}_shrunk.\${1##*.}}\" \${3:-2} \${4:-2}; }; f"; # Smart downsampling

    # --- Pandoc Document Processing ---------------------------------------
    # Document conversion using configured defaults
    doc = "f() { pandoc \"\$1\" --defaults defaults -o \"\${2:-\${1%.*}.\${2##*.}}\"; }; f";
    html = "f() { pandoc \"\$1\" --defaults defaults -t html5 -o \"\${2:-\${1%.*}.html}\"; }; f";
    pdf = "f() { pandoc \"\$1\" --defaults defaults -t pdf -o \"\${2:-\${1%.*}.pdf}\"; }; f";
    docx = "f() { pandoc \"\$1\" --defaults defaults -t docx -o \"\${2:-\${1%.*}.docx}\"; }; f";

    # Specialized document operations
    slides = "f() { pandoc \"\$1\" -t revealjs -s --defaults defaults -o \"\${2:-\${1%.*}_slides.html}\"; }; f";
    epub = "f() { pandoc \"\$1\" --defaults defaults -t epub3 -o \"\${2:-\${1%.*}.epub}\"; }; f";

    # Document analysis
    docinfo = "f() { pandoc \"\$1\" --print-default-data-file reference.docx >/dev/null 2>&1 && echo 'Pandoc ready' || echo 'Pandoc not configured'; file \"\$1\"; }; f";

    # --- Graphviz Graph Generation ----------------------------------------
    # Graph layout engines with output format options
    dot = "f() { format=\${2:-png}; dot -T\$format \"\$1\" -o \"\${3:-\${1%.*}.\$format}\"; }; f";
    neato = "f() { format=\${2:-png}; neato -T\$format \"\$1\" -o \"\${3:-\${1%.*}.\$format}\"; }; f";
    fdp = "f() { format=\${2:-png}; fdp -T\$format \"\$1\" -o \"\${3:-\${1%.*}.\$format}\"; }; f";
    circo = "f() { format=\${2:-png}; circo -T\$format \"\$1\" -o \"\${3:-\${1%.*}.\$format}\"; }; f";

    # Multi-format graph generation
    graph = "f() { base=\${1%.*}; for fmt in png svg pdf; do echo \"Generating \$base.\$fmt\"; dot -T\$fmt \"\$1\" -o \"\$base.\$fmt\"; done; }; f";

    # --- D2 Modern Diagram Generation ------------------------------------
    # Modern diagram scripting language with beautiful themes
    diagram = "f() { d2 \"\$1\" \"\${2:-\${1%.*}.svg}\" \"\${@:3}\"; }; f"; # Generate diagram (default SVG)
    d2svg = "f() { d2 \"\$1\" \"\${2:-\${1%.*}.svg}\" \"\${@:3}\"; }; f"; # Generate SVG diagram
    d2png = "f() { d2 \"\$1\" \"\${2:-\${1%.*}.png}\" \"\${@:3}\"; }; f"; # Generate PNG diagram
    d2pdf = "f() { d2 \"\$1\" \"\${2:-\${1%.*}.pdf}\" \"\${@:3}\"; }; f"; # Generate PDF diagram
    d2watch = "f() { d2 -w \"\$1\" \"\${2:-\${1%.*}.svg}\" \"\${@:3}\"; }; f"; # Watch mode for development
    d2theme = "f() { d2 --theme \${1:-0} \"\$2\" \"\${3:-\${2%.*}.svg}\" \"\${@:4}\"; }; f"; # Apply theme (0-7)
    d2layout = "f() { d2 --layout \${1:-dagre} \"\$2\" \"\${3:-\${2%.*}.svg}\" \"\${@:4}\"; }; f"; # Set layout engine

    # --- yt-dlp Video Downloading -----------------------------------------
    # Leverage configured settings from programs/media-tools.nix
    download = "f() { yt-dlp \"\$1\" \"\${@:2}\"; }; f";
    audioonly = "f() { yt-dlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 \"\$1\" \"\${@:2}\"; }; f";
    playlist = "f() { yt-dlp --yes-playlist \"\$1\" \"\${@:2}\"; }; f";
    quality = "f() { quality=\${2:-720p}; yt-dlp -f \"best[height<=\${quality%p}]\" \"\$1\" \"\${@:3}\"; }; f";

    # Download with metadata and subtitles
    archive = "f() { yt-dlp --write-description --write-info-json --write-thumbnail --write-subs --sub-langs en \"\$1\" \"\${@:2}\"; }; f";

    # Download information without downloading
    dlinfo = "f() { yt-dlp --list-formats \"\$1\"; }; f";

    # --- Workflow Helpers ------------------------------------------------
    # Development environment
    dl = "nix develop .#default";

    # Batch processing workflows
    process = "f() { echo 'Media processing workflow:'; echo '1. minfo - file information'; echo '2. mconvert - format conversion'; echo '3. mcompress - size optimization'; echo '4. mthumbnail - create preview'; echo 'Usage: m<command> input [output] [options]'; }; f";

    # Quality assurance
    validate = "f() { echo 'Checking media file integrity...'; ffprobe -v error \"\$1\" >/dev/null 2>&1 && echo '✓ Valid media file' || echo '✗ Corrupted or invalid file'; }; f";

    # Documentation & help
    help = "echo 'Media tools: ffmpeg, imagemagick, libvips, pandoc, graphviz, d2, handbrake, yt-dlp | Configs: XDG-compliant with security policies'";
    version = "ffmpeg -version | head -1 && magick -version | head -1 && vips --version && pandoc --version | head -1 && dot -V 2>&1 | head -1 && d2 version && HandBrakeCLI --version | head -1 && yt-dlp --version";
  };

in
{
  aliases = lib.mapAttrs' (name: value: {
    name = "m${name}";
    inherit value;
  }) mediaCommands;
}
