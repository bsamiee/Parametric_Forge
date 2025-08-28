# Title         : sysadmin.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/sysadmin.nix
# ----------------------------------------------------------------------------
# System administration aliases for network and system monitoring

_:

{
  # --- File Watching & Monitoring -------------------------------------------
  watch-exec = ''watchexec -c -r''; # Clear screen, restart on change
  watch-js = ''watchexec -e js,jsx,ts,tsx -c -r''; # Watch JavaScript/TypeScript files
  watch-py = ''watchexec -e py -c -r''; # Watch Python files
  watch-nix = ''watchexec -e nix -c -r''; # Watch Nix files

  # --- Network Bandwidth Monitoring -----------------------------------------
  bandwhich-simple = ''bandwhich -i en0''; # Default interface monitoring
  bandwhich-raw = ''bandwhich -r''; # Machine-readable output
  bandwhich-no-dns = ''bandwhich -n''; # Skip DNS resolution

  # --- Network Information --------------------------------------------------
  whois-clean = ''whois -B''; # Skip legal disclaimers

  # --- Network Performance Testing ------------------------------------------
  iperf-server = ''iperf3 -s''; # Start iperf3 server
  iperf-client = ''f() { iperf3 -c "$1" "''${@:2}"; }; f''; # iperf3 client (usage: iperf-client <host> [options])
  iperf-json = ''iperf3 -J''; # iperf3 with JSON output
  iperf-reverse = ''f() { iperf3 -c "$1" -R "''${@:2}"; }; f''; # Reverse test (server sends to client)
  iperf-dual = ''f() { iperf3 -c "$1" --bidir "''${@:2}"; }; f''; # Bidirectional test

  # --- DNS Tools ------------------------------------------------------------
  dig-short = ''dig +short''; # Short output format
  dig-trace = ''dig +trace''; # Trace query path
  dig-clean = ''dig +noall +answer''; # Clean answer-only output

  # --- Speed Testing --------------------------------------------------------
  speedtest-simple = ''speedtest-cli --simple''; # Basic speed test output
  speedtest-json = ''speedtest-cli --json''; # JSON formatted output
  speedtest-secure = ''speedtest-cli --secure --simple''; # Secure connection test
  speedtest-fast = ''speedtest-cli --no-upload --simple''; # Download only test

  # --- Documentation Tools --------------------------------------------------
  tldr-update = ''tldr --update''; # Update tldr page database

  # --- GNU Parallel Shortcuts -----------------------------------------------
  parallel-all = ''parallel -j+0''; # Use all CPU cores
  parallel-keep = ''parallel -k''; # Keep output order
  parallel-progress = ''parallel --bar --eta''; # Show progress bar and ETA

  # --- Smart System Operations ----------------------------------------------
  log-tail = ''f() { [[ -f docker-compose.yml ]] && docker compose logs -f || [[ $# -gt 0 ]] && tail -f "$@" || journalctl -f 2>/dev/null || tail -f /var/log/system.log 2>/dev/null || echo "No logs found"; }; f''; # Context-aware log following
  clean-dev = ''f() { fd -H -t d -E .git 'node_modules|target/debug|\.pytest_cache|\.venv|__pycache__|\.mypy_cache' . --max-depth 4 | parallel -j+0 rm -rf {} && echo "Cleaned development artifacts"; }; f''; # Clean common dev artifacts safely
  disk-hogs = ''fd -t f -S +100M --max-depth 3 | head -20 | xargs -I {} du -h {} | sort -hr''; # Find large files efficiently
}