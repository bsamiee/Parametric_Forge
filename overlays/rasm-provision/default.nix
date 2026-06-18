# Title         : rasm-provision/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/rasm-provision/default.nix
# ----------------------------------------------------------------------------
# Rasm local provisioning command.
{
  coreutils,
  docker-client,
  docker-compose,
  jq,
  lib,
  lsof,
  writeShellApplication,
}:
writeShellApplication {
  name = "rasm-provision";
  runtimeInputs = [
    coreutils
    docker-client
    docker-compose
    jq
    lsof
  ];
  bashOptions = ["errexit" "errtrace" "nounset" "pipefail"];
  meta = {
    description = "Local Rasm PostgreSQL provisioning command";
    mainProgram = "rasm-provision";
    license = lib.licenses.mit;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
  text = builtins.readFile ./rasm-provision.sh;
}
