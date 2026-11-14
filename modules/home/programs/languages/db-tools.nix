{pkgs, ...}: let
  style = import ../../../style.nix;

  postgresClientTools = pkgs.linkFarm "postgres-client-tools" (map (bin: {
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
    postgresClientTools
    pkgs.sqruff
    pkgs.sqlite-extended
  ];

  xdg.configFile = {
    "sqruff/.sqruff".text = style.sqruff;
    "psql/psqlrc".text = ''
      \set ON_ERROR_STOP on
    '';
  };
}
