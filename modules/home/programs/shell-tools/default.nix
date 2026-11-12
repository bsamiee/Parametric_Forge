# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/default.nix
# ----------------------------------------------------------------------------
# Shell tool inventory; imports carry real configuration only, and each imported file declares its own package. The table holds tools with
# no configuration.
{pkgs, ...}: {
  imports = [
    ./1password.nix
    ./act.nix
    ./atuin.nix
    ./bat.nix
    ./bottom.nix
    ./carapace.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./fzf.nix
    ./jnv.nix
    ./mise.nix
    ./posting.nix
    ./process-compose.nix
    ./procs.nix
    ./redeploy.nix
    ./serpl.nix
    ./ssh.nix
    ./starship.nix
    ./tlrc.nix
    ./trippy.nix
    ./xh.nix
    ./zoxide.nix
  ];

  home.packages = [
    pkgs._7zz-rar # 7-Zip with RAR support: the one RAR extractor, since nixpkgs builds ouch without unrar
    pkgs.ast-grep # Structural code search and rewrite; a project's mise pin shadows it inside its tree
    pkgs.difftastic # Syntax-tree diff (`difft`)
    pkgs.dua # Interactive disk usage analyzer
    pkgs.duckdb-current # SQL over CSV, Parquet, and JSON files in place; the upstream CLI release, ahead of nixpkgs' library package
    pkgs.dysk # Mounted filesystems as a table with filters, sort keys, and JSON or CSV output
    pkgs.flock # Native command execution under an interprocess file lock
    pkgs.fq # jq for binary formats; structured decode of media, executables, captures
    pkgs.gawk # GNU awk on the interactive PATH; macOS ships BSD awk only, scripts carry gawk via runtimeInputs
    pkgs.grex # Regex generator from test cases
    pkgs.hexyl # Hex viewer
    pkgs.hyperfine # Command benchmarking under the same controls
    pkgs.jq # JSON processor; the profile copy precedes the older one macOS ships at /usr/bin/jq
    pkgs.oha # HTTP load generator with real-time TUI and JSON/CSV output
    pkgs.ouch # Archive compression and extraction
    pkgs.parallel # GNU parallel: batch runner with a job log, resume, retries, progress, and per-job output grouping
    pkgs.pinact # GitHub Actions refs pinned to full commit SHAs and updated in place
    pkgs.rclone # Cloud storage sync; a move that removes emptied source directories is `rclone move --delete-empty-src-dirs` (aliases `rcmv`)
    pkgs.ripgrep # Text search on every PATH, in and outside a project
    pkgs.rsync # File transfer and mirroring
    pkgs.sd # Find and replace by line, `-A` across lines
    pkgs.sshs # Interactive SSH host picker
    pkgs.uv # Python package and tool runner on every PATH, so `uvx <tool>` runs anywhere; a project's mise pin shadows it inside its tree
    pkgs.watchexec # File-watch runner; each project's .gitignore and .ignore files steer what it watches
    pkgs.yq-go # YAML, TOML, and XML processor with jq syntax (`yq`)
  ];
}
