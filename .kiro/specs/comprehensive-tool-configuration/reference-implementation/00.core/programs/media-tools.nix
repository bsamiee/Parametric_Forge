# Title         : media-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/media-tools.nix
# ----------------------------------------------------------------------------
# Media processing tools: ffmpeg (multimedia framework) for comprehensive
# audio, video, and image processing capabilities. Provides powerful media
# manipulation, conversion, and streaming functionality for development and
# content creation workflows.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- FFmpeg Multimedia Framework ----------------------------------
    # Comprehensive multimedia processing framework with extensive codec support
    # Provides audio/video conversion, streaming, filtering, and manipulation
    # TODO: No home-manager module available - requires config files and presets
    
    # ffmpeg = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- Global Settings ---------------------------------
    #     # Default behavior and preferences
    #     global = {
    #       # Default log level
    #       log_level = "info";  # quiet, panic, fatal, error, warning, info, verbose, debug
    #       
    #       # Overwrite output files without asking
    #       overwrite = true;
    #       
    #       # Hide banner information
    #       hide_banner = true;
    #       
    #       # Show progress during processing
    #       show_progress = true;
    #       
    #       # Number of threads for processing
    #       threads = 0;  # 0 = auto-detect optimal thread count
    #       
    #       # Hardware acceleration
    #       hardware_accel = "auto";  # auto, none, videotoolbox (macOS), vaapi (Linux)
    #     };
    #     
    #     # --- Video Configuration -----------------------------
    #     # Default video processing settings
    #     video = {
    #       # Default video codec
    #       codec = "libx264";  # libx264, libx265, libvpx-vp9, av1
    #       
    #       # Video quality settings
    #       quality = {
    #         # Constant Rate Factor (lower = better quality)
    #         crf = 23;  # 18-28 range, 23 is good default
    #         
    #         # Preset for encoding speed vs compression
    #         preset = "medium";  # ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
    #         
    #         # Profile for compatibility
    #         profile = "high";  # baseline, main, high
    #         
    #         # Level for device compatibility
    #         level = "4.0";
    #       };
    #       
    #       # Resolution and scaling
    #       scaling = {
    #         # Default scaling algorithm
    #         algorithm = "lanczos";  # bilinear, bicubic, lanczos, spline
    #         
    #         # Common resolution presets
    #         presets = {
    #           "4k" = "3840x2160";
    #           "1080p" = "1920x1080";
    #           "720p" = "1280x720";
    #           "480p" = "854x480";
    #         };
    #       };
    #       
    #       # Frame rate settings
    #       framerate = {
    #         # Default output frame rate
    #         default = 30;
    #         
    #         # Frame rate conversion method
    #         conversion = "fps";  # fps, minterpolate
    #       };
    #     };
    #     
    #     # --- Audio Configuration -----------------------------
    #     # Default audio processing settings
    #     audio = {
    #       # Default audio codec
    #       codec = "aac";  # aac, mp3, opus, flac, pcm_s16le
    #       
    #       # Audio quality settings
    #       quality = {
    #         # Bitrate for lossy codecs
    #         bitrate = "128k";  # 96k, 128k, 192k, 256k, 320k
    #         
    #         # Sample rate
    #         sample_rate = 44100;  # 22050, 44100, 48000, 96000
    #         
    #         # Channel configuration
    #         channels = 2;  # 1 (mono), 2 (stereo), 6 (5.1), 8 (7.1)
    #       };
    #       
    #       # Audio filters
    #       filters = {
    #         # Volume normalization
    #         normalize = true;
    #         
    #         # Noise reduction
    #         denoise = false;
    #         
    #         # Dynamic range compression
    #         compand = false;
    #       };
    #     };
    #     
    #     # --- Format Configuration ----------------------------
    #     # Container format settings
    #     formats = {
    #       # Default output format
    #       default = "mp4";
    #       
    #       # Format-specific settings
    #       mp4 = {
    #         # Fast start for web streaming
    #         faststart = true;
    #         
    #         # Metadata handling
    #         metadata = "preserve";
    #       };
    #       
    #       webm = {
    #         # WebM-specific optimizations
    #         optimize = true;
    #         
    #         # Dash compatibility
    #         dash = false;
    #       };
    #       
    #       gif = {
    #         # GIF optimization
    #         optimize = true;
    #         
    #         # Color palette optimization
    #         palette = "auto";
    #       };
    #     };
    #   };
    #   
    #   # --- Preset Configurations ------------------------------
    #   # Predefined encoding presets for common use cases
    #   presets = {
    #     # --- Web Optimization Presets -----------------------
    #     web_optimized = {
    #       video = {
    #         codec = "libx264";
    #         crf = 23;
    #         preset = "fast";
    #         profile = "high";
    #         max_bitrate = "2M";
    #         buffer_size = "4M";
    #       };
    #       audio = {
    #         codec = "aac";
    #         bitrate = "128k";
    #         sample_rate = 44100;
    #       };
    #       format = "mp4";
    #       options = [
    #         "-movflags" "+faststart"
    #         "-pix_fmt" "yuv420p"
    #       ];
    #     };
    #     
    #     # --- High Quality Archive Preset --------------------
    #     archive_quality = {
    #       video = {
    #         codec = "libx265";
    #         crf = 18;
    #         preset = "slow";
    #         profile = "main";
    #       };
    #       audio = {
    #         codec = "flac";
    #         sample_rate = 48000;
    #       };
    #       format = "mkv";
    #       options = [
    #         "-pix_fmt" "yuv420p10le"
    #       ];
    #     };
    #     
    #     # --- Social Media Presets ---------------------------
    #     instagram_story = {
    #       video = {
    #         codec = "libx264";
    #         crf = 23;
    #         preset = "fast";
    #         resolution = "1080x1920";  # 9:16 aspect ratio
    #         framerate = 30;
    #       };
    #       audio = {
    #         codec = "aac";
    #         bitrate = "128k";
    #       };
    #       format = "mp4";
    #       duration_limit = 15;  # seconds
    #     };
    #     
    #     youtube_1080p = {
    #       video = {
    #         codec = "libx264";
    #         crf = 21;
    #         preset = "slow";
    #         resolution = "1920x1080";
    #         framerate = 30;
    #       };
    #       audio = {
    #         codec = "aac";
    #         bitrate = "192k";
    #         sample_rate = 48000;
    #       };
    #       format = "mp4";
    #       options = [
    #         "-movflags" "+faststart"
    #         "-pix_fmt" "yuv420p"
    #       ];
    #     };
    #     
    #     # --- Audio-only Presets -----------------------------
    #     podcast = {
    #       audio = {
    #         codec = "mp3";
    #         bitrate = "128k";
    #         sample_rate = 44100;
    #         channels = 2;
    #       };
    #       format = "mp3";
    #       options = [
    #         "-af" "highpass=f=80,lowpass=f=15000"  # Audio filtering
    #       ];
    #     };
    #     
    #     music_archive = {
    #       audio = {
    #         codec = "flac";
    #         sample_rate = 96000;
    #         channels = 2;
    #       };
    #       format = "flac";
    #       options = [
    #         "-compression_level" "8"  # Maximum FLAC compression
    #       ];
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     # Basic conversion shortcuts
    #     "to-mp4" = "ffmpeg -i";
    #     "to-webm" = "ffmpeg -i input -c:v libvpx-vp9 -c:a opus";
    #     "to-gif" = "ffmpeg -i input -vf palettegen=reserve_transparent=0 -y palette.png && ffmpeg -i input -i palette.png -lavfi paletteuse";
    #     
    #     # Quality presets
    #     "web-encode" = "ffmpeg -i input -preset web_optimized";
    #     "archive-encode" = "ffmpeg -i input -preset archive_quality";
    #     "youtube-encode" = "ffmpeg -i input -preset youtube_1080p";
    #     
    #     # Audio extraction and conversion
    #     "extract-audio" = "ffmpeg -i input -vn -c:a copy";
    #     "to-mp3" = "ffmpeg -i input -c:a mp3 -b:a 192k";
    #     "to-flac" = "ffmpeg -i input -c:a flac";
    #     
    #     # Video manipulation
    #     "resize-720p" = "ffmpeg -i input -vf scale=1280:720";
    #     "resize-1080p" = "ffmpeg -i input -vf scale=1920:1080";
    #     "crop-16-9" = "ffmpeg -i input -vf crop=ih*16/9:ih";
    #     
    #     # Utility functions
    #     "video-info" = "ffprobe -v quiet -print_format json -show_format -show_streams";
    #     "video-duration" = "ffprobe -v quiet -show_entries format=duration -of csv=p=0";
    #     "video-fps" = "ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0";
    #   };
    # };
  };

  # --- Environment Variables for Manual Configuration -------------------
  # These environment variables configure FFmpeg until a home-manager module
  # is available. They should be moved to environment.nix in actual implementation.
  
  # FFmpeg configuration
  # FFMPEG_DATADIR = "${config.xdg.configHome}/ffmpeg";
  # FFMPEG_LOG_LEVEL = "info";
  
  # Hardware acceleration (macOS)
  # FFMPEG_VIDEOTOOLBOX = "1";  # Enable VideoToolbox on macOS
  
  # Performance settings
  # FFMPEG_THREADS = "0";  # Auto-detect thread count
  # FFMPEG_THREAD_QUEUE_SIZE = "512";
  
  # --- Integration Notes -----------------------------------------------
  # 1. FFmpeg requires preset files in configs/media/ffmpeg/presets/
  # 2. Configuration files can include custom filters and encoding profiles
  # 3. Shell aliases provide convenient shortcuts for common operations
  # 4. Integration with system hardware acceleration capabilities
  # 5. Package dependency: ffmpeg-full in packages/media-tools.nix
  # 6. Consider integration with media workflow automation tools
  
  # --- Shell Functions for Manual Configuration -----------------------
  # These functions provide enhanced media processing capabilities
  
  # Video conversion with preset
  # convert-video() {
  #   local input="$1"
  #   local output="$2"
  #   local preset="${3:-web_optimized}"
  #   
  #   if [[ -z "$input" || -z "$output" ]]; then
  #     echo "Usage: convert-video <input> <output> [preset]"
  #     echo "Available presets: web_optimized, archive_quality, youtube_1080p"
  #     return 1
  #   fi
  #   
  #   echo "Converting $input to $output using preset: $preset"
  #   
  #   case "$preset" in
  #     web_optimized)
  #       ffmpeg -i "$input" -c:v libx264 -crf 23 -preset fast -c:a aac -b:a 128k -movflags +faststart "$output"
  #       ;;
  #     archive_quality)
  #       ffmpeg -i "$input" -c:v libx265 -crf 18 -preset slow -c:a flac "$output"
  #       ;;
  #     youtube_1080p)
  #       ffmpeg -i "$input" -c:v libx264 -crf 21 -preset slow -vf scale=1920:1080 -c:a aac -b:a 192k -movflags +faststart "$output"
  #       ;;
  #     *)
  #       echo "Unknown preset: $preset"
  #       return 1
  #       ;;
  #   esac
  # }
  
  # Batch video processing
  # batch-convert() {
  #   local preset="${1:-web_optimized}"
  #   local input_ext="${2:-mp4}"
  #   local output_ext="${3:-mp4}"
  #   
  #   echo "Batch converting *.$input_ext files using preset: $preset"
  #   
  #   for file in *."$input_ext"; do
  #     if [[ -f "$file" ]]; then
  #       local output="${file%.*}_converted.$output_ext"
  #       echo "Processing: $file -> $output"
  #       convert-video "$file" "$output" "$preset"
  #     fi
  #   done
  # }
  
  # Video information extractor
  # video-analyze() {
  #   local input="$1"
  #   
  #   if [[ -z "$input" ]]; then
  #     echo "Usage: video-analyze <input>"
  #     return 1
  #   fi
  #   
  #   echo "Analyzing: $input"
  #   echo "----------------------------------------"
  #   
  #   # Basic information
  #   echo "Duration: $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$input" | cut -d. -f1)s"
  #   echo "Size: $(du -h "$input" | cut -f1)"
  #   
  #   # Video stream info
  #   echo "Video codec: $(ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$input")"
  #   echo "Resolution: $(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$input" | tr ',' 'x')"
  #   echo "Frame rate: $(ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$input")"
  #   
  #   # Audio stream info
  #   echo "Audio codec: $(ffprobe -v quiet -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$input")"
  #   echo "Sample rate: $(ffprobe -v quiet -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$input")Hz"
  #   echo "Channels: $(ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$input")"
  # }
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Create comprehensive preset library for different use cases
  # 2. Set up batch processing workflows for media production
  # 3. Integrate with cloud storage for media asset management
  # 4. Add support for live streaming and real-time processing
  # 5. Create templates for common video editing workflows
  # 6. Integrate with subtitle and caption processing tools
  # 7. Add support for HDR and advanced color processing
  # 8. Consider integration with media asset databases and metadata management
  
  # --- Usage Examples ------------------------------------------------
  # Common usage patterns for FFmpeg:
  
  # Basic conversion:
  # ffmpeg -i input.mov output.mp4              # Convert format
  # ffmpeg -i input.mp4 -c copy output.mkv     # Change container without re-encoding
  # ffmpeg -i input.mp4 -vn audio.mp3          # Extract audio only
  # ffmpeg -i input.mp4 -an video.mp4          # Remove audio track
  
  # Quality control:
  # ffmpeg -i input.mp4 -crf 23 output.mp4     # Constant quality encoding
  # ffmpeg -i input.mp4 -b:v 2M output.mp4     # Constant bitrate encoding
  # ffmpeg -i input.mp4 -preset slow output.mp4 # Slower encoding, better compression
  
  # Resolution and scaling:
  # ffmpeg -i input.mp4 -vf scale=1280:720 output.mp4      # Resize to 720p
  # ffmpeg -i input.mp4 -vf scale=-1:720 output.mp4        # Scale height to 720, maintain aspect ratio
  # ffmpeg -i input.mp4 -vf crop=1920:800:0:140 output.mp4 # Crop to cinematic aspect ratio
  
  # Audio processing:
  # ffmpeg -i input.mp4 -c:v copy -c:a aac -b:a 128k output.mp4  # Re-encode audio only
  # ffmpeg -i input.mp4 -af volume=0.5 output.mp4               # Reduce volume by 50%
  # ffmpeg -i input.mp4 -af highpass=f=200,lowpass=f=3000 output.mp4  # Audio filtering
  
  # Advanced operations:
  # ffmpeg -i input.mp4 -ss 00:01:00 -t 00:02:00 output.mp4     # Extract 2-minute clip starting at 1 minute
  # ffmpeg -i input.mp4 -vf fps=30 output.mp4                   # Change frame rate
  # ffmpeg -f concat -i filelist.txt -c copy output.mp4         # Concatenate multiple files
}