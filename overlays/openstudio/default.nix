{
  bash,
  fetchurl,
  lib,
  stdenvNoCC,
}: let
  version = "3.11.0";
  build = "241b8abb4d";
  system = stdenvNoCC.hostPlatform.system;
  platformAsset =
    if system == "aarch64-darwin"
    then {
      platform = "Darwin-arm64";
      hash = "sha256-t/hZA44pYjcf8eEv/lCSNfAafVT2MfBLRY37XXvjZGQ=";
    }
    else
      (
        throw "openstudio: unsupported platform ${system}"
      );
in
  stdenvNoCC.mkDerivation {
    pname = "openstudio";
    inherit version;

    src = fetchurl {
      url = "https://github.com/NatLabRockies/OpenStudio/releases/download/v${version}/OpenStudio-${version}%2B${build}-${platformAsset.platform}.tar.gz";
      inherit (platformAsset) hash;
    };

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
      export OPENSTUDIO_VERSION="${version}"
      export OPENSTUDIO_RUBY_ROOT="$runtime/Ruby"
      export OPENSTUDIO_PYTHON_ROOT="$runtime/Python"
      export OPENSTUDIO_RADIANCE_ROOT="$runtime/Radiance"
      if [[ "\''${FORGE_OPENSTUDIO_EXTERNAL_ENERGYPLUS:-0}" != "1" ]]; then
        export ENERGYPLUSDIR="$runtime/EnergyPlus"
        export ENERGYPLUS_DIR="$runtime/EnergyPlus"
        export ENERGYPLUS_EXE="$runtime/EnergyPlus/energyplus"
      fi
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
      export OPENSTUDIO_VERSION="${version}"
      export OPENSTUDIO_RUBY_ROOT="$runtime/Ruby"
      export OPENSTUDIO_PYTHON_ROOT="$runtime/Python"
      export OPENSTUDIO_RADIANCE_ROOT="$runtime/Radiance"
      if [[ "\''${FORGE_OPENSTUDIO_EXTERNAL_ENERGYPLUS:-0}" != "1" ]]; then
        export ENERGYPLUSDIR="$runtime/EnergyPlus"
        export ENERGYPLUS_DIR="$runtime/EnergyPlus"
        export ENERGYPLUS_EXE="$runtime/EnergyPlus/energyplus"
      fi
      exec "$runtime/bin/install_utility" "\$@"
      EOF
              chmod 0755 "$out/bin/openstudio-install-utility"
            fi

            runHook postInstall
    '';

    meta = {
      description = "OpenStudio SDK and CLI for whole-building energy modeling";
      homepage = "https://openstudio.net";
      license = lib.licenses.bsd3;
      mainProgram = "openstudio";
      platforms = ["aarch64-darwin"];
    };
  }
