# Title         : db-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/db-tools.nix
# ----------------------------------------------------------------------------
# Database and SQL tooling: PostgreSQL clients, the SQL linter and language server, and the extended SQLite shell.
{
  lib,
  pkgs,
  ...
}: let
  style = import ../../../style.nix;

  # PostgreSQL 18 client commands alone; the package's server binaries stay off PATH.
  postgres18ClientTools = pkgs.linkFarm "postgres18-client-tools" (map (bin: {
      name = "bin/${bin}";
      path = "${pkgs.postgresql_18}/bin/${bin}";
    }) [
      "psql"
      "pg_dump"
      "pg_dumpall"
      "pg_restore"
      "pg_isready"
      "pgbench"
      "pg_amcheck"
      "createdb"
      "dropdb"
      "createuser"
      "dropuser"
      "vacuumdb"
      "reindexdb"
      "clusterdb"
    ]);
in {
  home.packages = [
    postgres18ClientTools # PostgreSQL 18 client commands
    pkgs.sqruff # SQL linter/formatter
    pkgs.postgres-language-server # Postgres LSP; bundles postgrestools
    pkgs.sqlite-extended # Explicit SQLite shell with SQLean, sqlite-vec, and SpatiaLite loaded
  ];

  # sqruff reads no user-level config: each file is an explicit `sqruff --config` target carrying the style vocabulary for its dialect.
  xdg.configFile = lib.genAttrs' ["postgres" "duckdb"] (d: lib.nameValuePair "sqruff/${d}.cfg" {text = style.sqruff d;});
}
