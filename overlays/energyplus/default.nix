{
  bash,
  fetchurl,
  lib,
  stdenvNoCC,
}: let
  version = "26.1.0";
  build = "6f2e40d102";
  system = stdenvNoCC.hostPlatform.system;
  platformAsset =
    if system == "aarch64-darwin"
    then {
      platform = "Darwin-macOS13-arm64";
      hash = "sha256-fy7EJeZ/XXHGaORQTbGxDZHcTYy4Aumo7nDE8CpG03k=";
    }
    else
      (
        throw "energyplus: unsupported platform ${system}"
      );
  archiveRoot = "EnergyPlus-${version}-${build}-${platformAsset.platform}";
in
  stdenvNoCC.mkDerivation {
    pname = "energyplus";
    inherit version;

    src = fetchurl {
      url = "https://github.com/NatLabRockies/EnergyPlus/releases/download/v${version}/${archiveRoot}.tar.gz";
      inherit (platformAsset) hash;
    };

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
      export ENERGYPLUS_VERSION="${version}"
      exec "$runtime/$tool" "\$@"
      EOF
              chmod 0755 "$out/bin/$tool"
            }

            for tool in \
              energyplus \
              energyplus-${version} \
              runenergyplus \
              runepmacro \
              runreadvars \
              EPMacro \
              ExpandObjects \
              ConvertInputFormat \
              ConvertInputFormat-${version}
            do
              if [ -x "$runtime/$tool" ]; then
                install_tool "$tool"
              fi
            done

            runHook postInstall
    '';

    meta = {
      description = "Whole building energy simulation runtime";
      homepage = "https://energyplus.net";
      license = lib.licenses.bsd3;
      mainProgram = "energyplus";
      platforms = ["aarch64-darwin"];
    };
  }
