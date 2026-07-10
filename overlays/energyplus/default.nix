# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/energyplus/default.nix
# ----------------------------------------------------------------------------
# Hand-authored install kernel; overlays/manifest.nix owns every version,
# asset, and hash fact through the `row` argument.
{
  bash,
  fetchurl,
  lib,
  stdenvNoCC,
  row,
}: let
  system = stdenvNoCC.hostPlatform.system;
  asset =
    row.assets.${system}
    or (throw "energyplus: no asset row for ${system} (declared: ${lib.concatStringsSep " " (builtins.attrNames row.assets)})");
  runtime = "${placeholder "out"}/opt/energyplus";
  env = {
    ENERGYPLUSDIR = runtime;
    ENERGYPLUS_DIR = runtime;
    ENERGYPLUS_EXE = "${runtime}/energyplus";
    ENERGYPLUS_VERSION = row.version;
  };
  wrappers = lib.genAttrs [
    "energyplus"
    "energyplus-${row.version}"
    "runenergyplus"
    "runepmacro"
    "runreadvars"
    "EPMacro"
    "ExpandObjects"
    "ConvertInputFormat"
    "ConvertInputFormat-${row.version}"
  ] (tool: tool);
  wrapperText = target:
    lib.concatLines (
      ["#!${lib.getExe bash}" "set -euo pipefail"]
      ++ lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") env
      ++ [''exec "${runtime}/${target}" "$@"'']
    );
  # A missing tool is upstream layout drift (patch_drift); fail the build
  # loudly, never ship a silently thinner bin/.
  installWrapper = name: target: ''
    [ -x ${lib.escapeShellArg "${runtime}/${target}"} ] || {
      echo "energyplus: expected tool '${target}' missing from the release layout" >&2
      exit 1
    }
    printf '%s' ${lib.escapeShellArg (wrapperText target)} >"$out/bin/${name}"
    chmod 0755 "$out/bin/${name}"
  '';
in
  stdenvNoCC.mkDerivation {
    pname = "energyplus";
    inherit (row) version;

    src = fetchurl {inherit (asset) url hash;};

    nativeBuildInputs = [bash];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/opt"
      cp -R . "$out/opt/energyplus"
      patchShebangs "$out/opt/energyplus"

      ${lib.concatStrings (lib.mapAttrsToList installWrapper wrappers)}
      runHook postInstall
    '';

    meta = {
      inherit (row) description homepage mainProgram;
      license = lib.licenses.${row.license};
      platforms = builtins.attrNames row.assets;
    };
  }
