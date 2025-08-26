# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/core.nix
# ----------------------------------------------------------------------------
# Core shell aliases for enhanced functionality

{ ... }:

{
  # --- SQLite with Extensions ----------------------------------------------
  sqlite3 = ''sqlite3 -init ~/.sqliterc'';

  # --- Node.js CLI Tools ---------------------------------------------------
  # http-server
  httpserve = "http-server";
  httpservedev = "http-server -c-1 -o";  # No cache, auto-open
  httpservecors = "http-server --cors";   # Enable CORS

  # concurrently shorthand
  conc = "concurrently";

  # YAML/JSON conversion
  yaml2json = "js-yaml";
  json2yaml = "js-yaml";  # Works with piped input

  # JSON manipulation
  prettyjson = "json";
  jval = "json --validate";
  jkeys = "json -ka";
  jstream = "json -ga";
  jmerge = "json --merge";
  jfilter = "json -c";

  # serve
  servedev = "serve -c-1 -o";  # Development mode (no cache, auto-open)
  servecors = "serve --cors";   # Enable CORS headers
  servessl = "serve -S";        # Enable SSL/TLS
}
