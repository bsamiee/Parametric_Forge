# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/default.nix
# ----------------------------------------------------------------------------
# Shell tool inventory; imports carry real configuration only. Monitor and
# proof-lane admissions arrive as manifest roster rows, never bare entries.
{
  lib,
  pkgs,
  ...
}: let
  manifest = import ../../../../overlays/manifest.nix;
  rosterPackages = roster:
    map (row: pkgs.${row.attr})
    (lib.filter (row: row.install == "hm-roster" && row.roster == roster)
      (lib.attrValues manifest.admissions));
in {
  imports = [
    ./1password.nix
    ./act.nix
    ./aria2.nix
    ./atuin.nix
    ./bat.nix
    ./bottom.nix
    ./browsers.nix
    ./carapace.nix
    ./carbon.nix
    ./dust.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./forge-tools.nix
    ./fzf.nix
    ./heptabase.nix
    ./jnv.nix
    ./mcp-launchers.nix
    ./pik.nix
    ./posting.nix
    ./process-compose.nix
    ./procs.nix
    ./rclone.nix
    ./ripgrep.nix
    ./rsync.nix
    ./serpl.nix
    ./ssh.nix
    ./starship.nix
    ./tlrc.nix
    ./trippy.nix
    ./watchexec.nix
    ./webhook.nix
    ./xh.nix
    ./zoxide.nix
  ];

  # Manifest roster groups: monitors (viddy), proof lane (presenterm, vhs).
  home.packages =
    rosterPackages "monitors"
    ++ rosterPackages "proof"
    ++ [
      pkgs._7zz-rar # 7-Zip with RAR support for Yazi archive preview/extraction
      pkgs.actionlint # GitHub Actions workflow linter
      pkgs.ast-grep # Structural code search and rewrite
      pkgs.bandwhich # Per-process bandwidth monitor
      pkgs.choose # Human-friendly column extraction
      pkgs.curlie # Curl-compatible HTTP client
      pkgs.doggo # DNS lookup client
      pkgs.doppler # Doppler secrets CLI; zsh completion ships in share/zsh/site-functions
      pkgs.dua # Interactive disk usage analyzer
      pkgs.duf # Disk free overview
      pkgs.dust # Directory size tree; config owned by dust.nix
      pkgs.fq # jq for binary formats; structured decode of media, executables, captures
      pkgs.gping # Graphing ping
      pkgs.grex # Regex generator from test cases
      pkgs.hexyl # Hex viewer
      pkgs.hyperfine # Command benchmarking
      pkgs.mise # Runtime version manager
      pkgs.oha # HTTP load generator with real-time TUI and JSON/CSV output
      pkgs.ookla-speedtest # Official Ookla speed test CLI
      pkgs.ouch # Archive compression and extraction
      pkgs.posting # Terminal API workspace; config owned by posting.nix
      pkgs.process-compose # Non-container process orchestrator; config owned by process-compose.nix
      pkgs.ratchet # GitHub Actions version pinning
      pkgs.rich-cli # Rich terminal rendering
      pkgs.sd # Structural find and replace
      pkgs.sshs # Interactive SSH host picker
      pkgs.trash-cli # FreeDesktop trash suite
      pkgs.zizmor # GitHub Actions security auditor
    ];
}
