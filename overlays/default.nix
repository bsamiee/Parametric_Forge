# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Package overlays
final: prev: {
  bats = prev.stdenvNoCC.mkDerivation {
    pname = "bats";
    version = "1.13.0";
    src = prev.fetchurl {
      url = "https://github.com/bats-core/bats-core/archive/refs/tags/v1.13.0.tar.gz";
      hash = "sha256-qF4SuIKCcaFSszjKgQmqI0k7V5UJh8jm3/l7pJJ3L/M=";
    };
    nativeBuildInputs = [prev.bash];
    dontConfigure = true;
    dontBuild = true;
    patchPhase = ''
      runHook prePatch
      patchShebangs .
      runHook postPatch
    '';
    installPhase = ''
      runHook preInstall
      ./install.sh "$out"
      runHook postInstall
    '';
    meta =
      prev.bats.meta
      // {
        mainProgram = "bats";
      };
  };
  duckdb = prev.callPackage ./duckdb {};
  forge-provision = final.callPackage ./forge-provision {};
  sqlean = prev.callPackage ./sqlean {};
}
