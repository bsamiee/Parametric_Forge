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
    or (throw "energyplus: no asset row for ${system}");
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
            runtime="$out/opt/energyplus"

            install_tool() {
              tool="$1"
              cat >"$out/bin/$tool" <<EOF
      #!${bash}/bin/bash
      set -euo pipefail
      export ENERGYPLUSDIR="$runtime"
      export ENERGYPLUS_DIR="$runtime"
      export ENERGYPLUS_EXE="$runtime/energyplus"
      export ENERGYPLUS_VERSION="${row.version}"
      exec "$runtime/$tool" "\$@"
      EOF
              chmod 0755 "$out/bin/$tool"
            }

            for tool in \
              energyplus \
              energyplus-${row.version} \
              runenergyplus \
              runepmacro \
              runreadvars \
              EPMacro \
              ExpandObjects \
              ConvertInputFormat \
              ConvertInputFormat-${row.version}
            do
              if [ -x "$runtime/$tool" ]; then
                install_tool "$tool"
              fi
            done

            runHook postInstall
    '';

    meta = {
      inherit (row) description homepage mainProgram;
      license = lib.licenses.${row.license};
      platforms = builtins.attrNames row.assets;
    };
  }
