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
  jq,
  lib,
  lsof,
  runCommand,
  writeShellApplication,
}: let
  app = writeShellApplication {
    name = "forge-provision";
    runtimeInputs = [
      coreutils
      docker-client
      docker-compose
      jq
      lsof
    ];
    bashOptions = ["errexit" "errtrace" "nounset" "pipefail"];
    meta = {
      description = "Local Forge PostgreSQL provisioning command";
      mainProgram = "forge-provision";
      license = lib.licenses.mit;
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
    text = builtins.readFile ./forge-provision.sh;
  };
in
  runCommand "forge-provision" {
    inherit (app) meta passthru;
  } ''
    mkdir -p "$out"
    cp -R ${app}/. "$out/"
    mkdir -p "$out/share/forge-provision"
    cp -R ${./bash} "$out/share/forge-provision/bash"
    cp -R ${./data} "$out/share/forge-provision/data"
    cp -R ${./jq} "$out/share/forge-provision/jq"
    cp -R ${./sql} "$out/share/forge-provision/sql"
  ''
