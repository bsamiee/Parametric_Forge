# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/provision/default.nix
# ----------------------------------------------------------------------------
# Local provisioning command.
{
  coreutils,
  docker-client,
  docker-compose,
  duckdb,
  gawk,
  git,
  jq,
  lib,
  lsof,
  runCommand,
  sqlite-extended,
  unixtools,
  writeShellApplication,
}: let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./provision.sh
      ./bash
      ./data
      ./jq
      ./sql
    ];
  };
  app = writeShellApplication {
    name = "provision";
    runtimeInputs = [
      coreutils
      docker-client
      docker-compose
      duckdb
      gawk
      git
      jq
      lsof
      sqlite-extended
      unixtools.ps
    ];
    bashOptions = ["errexit" "errtrace" "nounset" "pipefail"];
    meta = {
      description = "Local PostgreSQL provisioning command";
      mainProgram = "provision";
      license = lib.licenses.mit;
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
    # Read the local file, never "${src}/..." — interpolating the fileset copy just to read it back forces the store copy at eval time, and a
    # machine that has never built the package refuses the phantom path (lazy trees never materialize it).
    text = builtins.readFile ./provision.sh;
  };
in
  runCommand "provision" {
    inherit (app) meta passthru;
  } ''
    mkdir -p "$out"
    cp -R ${app}/. "$out/"
    mkdir -p "$out/share/provision"
    cp -R ${src}/bash "$out/share/provision/bash"
    cp -R ${src}/data "$out/share/provision/data"
    cp -R ${src}/jq "$out/share/provision/jq"
    cp -R ${src}/sql "$out/share/provision/sql"
  ''
