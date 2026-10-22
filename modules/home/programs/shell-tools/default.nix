# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/default.nix
# ----------------------------------------------------------------------------
# Shell tool inventory; imports carry real configuration only.
{pkgs, ...}: {
  imports = [
    ./1password.nix
    ./act.nix
    ./aria2.nix
    ./atuin.nix
    ./bat.nix
    ./bottom.nix
    ./carapace.nix
    ./dust.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./redeploy.nix
    ./fzf.nix
    ./jnv.nix
    ./mise.nix
    ./pik.nix
    ./posting.nix
    ./process-compose.nix
    ./procs.nix
    ./rclone.nix
    ./rsync.nix
    ./serpl.nix
    ./ssh.nix
    ./starship.nix
    ./tlrc.nix
    ./trippy.nix
    ./watchexec.nix
    ./xh.nix
    ./zoxide.nix
  ];

  home.packages = [
    pkgs._7zz-rar # 7-Zip with RAR support for Yazi archive preview/extraction
    pkgs.bandwhich # Per-process bandwidth monitor
    pkgs.choose # Human-friendly column extraction
    pkgs.dua # Interactive disk usage analyzer
    pkgs.duf # Disk free overview
    pkgs.dust # Directory size tree; config owned by dust.nix
    pkgs.fq # jq for binary formats; structured decode of media, executables, captures
    pkgs.gawk # GNU awk on the interactive PATH; macOS ships BSD awk only, scripts carry gawk via runtimeInputs
    pkgs.grex # Regex generator from test cases
    pkgs.hexyl # Hex viewer
    pkgs.oha # HTTP load generator with real-time TUI and JSON/CSV output
    pkgs.ookla-speedtest # Official Ookla speed test CLI
    pkgs.ouch # Archive compression and extraction
    pkgs.posting # Terminal API workspace; config owned by posting.nix
    pkgs.process-compose # Non-container process orchestrator; config owned by process-compose.nix
    pkgs.ratchet # GitHub Actions version pinning
    pkgs.rich-cli # Rich terminal rendering
    pkgs.sshs # Interactive SSH host picker
  ];
}
