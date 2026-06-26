# Title         : forge-provision/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/forge-provision/default.nix
# ----------------------------------------------------------------------------
# Forge local provisioning command.
{
  coreutils,
  docker-client,
  docker-compose,
  duckdb,
  jq,
  lib,
  lsof,
  runCommand,
  sqlite-forge,
  writeShellApplication,
}: let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./forge-provision.sh
      ./bash
      ./data
      ./jq
      ./sql
    ];
  };
  app = writeShellApplication {
    name = "forge-provision";
    runtimeInputs = [
      coreutils
      docker-client
      docker-compose
      duckdb
      jq
      lsof
      sqlite-forge
    ];
    bashOptions = ["errexit" "errtrace" "nounset" "pipefail"];
    meta = {
      description = "Local Forge PostgreSQL provisioning command";
      mainProgram = "forge-provision";
      license = lib.licenses.mit;
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
    text = builtins.readFile "${src}/forge-provision.sh";
  };
in
  runCommand "forge-provision" {
    inherit (app) meta passthru;
  } ''
    mkdir -p "$out"
    cp -R ${app}/. "$out/"
    mkdir -p "$out/share/forge-provision"
    cp -R ${src}/bash "$out/share/forge-provision/bash"
    cp -R ${src}/data "$out/share/forge-provision/data"
    cp -R ${src}/jq "$out/share/forge-provision/jq"
    cp -R ${src}/sql "$out/share/forge-provision/sql"
  ''
