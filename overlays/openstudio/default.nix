# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/openstudio/default.nix
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
    or (throw "openstudio: no asset row for ${system}");
in
  stdenvNoCC.mkDerivation {
    pname = "openstudio";
    inherit (row) version;

    src = fetchurl {inherit (asset) url hash;};

    nativeBuildInputs = [bash];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin" "$out/opt"
            cp -R . "$out/opt/openstudio"
            patchShebangs "$out/opt/openstudio/bin"
            runtime="$out/opt/openstudio"

            cat >"$out/bin/openstudio" <<EOF
      #!${bash}/bin/bash
      set -euo pipefail
      export OPENSTUDIO_ROOT="$runtime"
      export OPENSTUDIO_DIR="$runtime"
      export OPENSTUDIO_EXE="$runtime/bin/openstudio"
      export OPENSTUDIO_VERSION="${row.version}"
      export OPENSTUDIO_RUBY_ROOT="$runtime/Ruby"
      export OPENSTUDIO_PYTHON_ROOT="$runtime/Python"
      export OPENSTUDIO_RADIANCE_ROOT="$runtime/Radiance"
      exec "$runtime/bin/openstudio" "\$@"
      EOF
            chmod 0755 "$out/bin/openstudio"

            if [ -x "$runtime/bin/install_utility" ]; then
              cat >"$out/bin/openstudio-install-utility" <<EOF
      #!${bash}/bin/bash
      set -euo pipefail
      export OPENSTUDIO_ROOT="$runtime"
      export OPENSTUDIO_DIR="$runtime"
      export OPENSTUDIO_EXE="$runtime/bin/openstudio"
      export OPENSTUDIO_VERSION="${row.version}"
      export OPENSTUDIO_RUBY_ROOT="$runtime/Ruby"
      export OPENSTUDIO_PYTHON_ROOT="$runtime/Python"
      export OPENSTUDIO_RADIANCE_ROOT="$runtime/Radiance"
      exec "$runtime/bin/install_utility" "\$@"
      EOF
              chmod 0755 "$out/bin/openstudio-install-utility"
            fi

            runHook postInstall
    '';

    meta = {
      inherit (row) description homepage mainProgram;
      license = lib.licenses.${row.license};
      platforms = builtins.attrNames row.assets;
    };
  }
