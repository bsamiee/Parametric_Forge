# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/yazi/default.nix
# ----------------------------------------------------------------------------
# Yazi plugin packages

{ lib, stdenvNoCC, fetchFromGitHub }:

let
  sourceRepo = {
    owner = "sharklasers996";
    repo = "eza-preview.yazi";
    rev = "7ca4c2558e17bef98cacf568f10ec065a1e5fb9b";
    sha256 = "sha256-ncOOCj53wXPZvaPSoJ5LjaWSzw1omHadKDrXdIb7G5U=";
  };

in {
  eza-preview = stdenvNoCC.mkDerivation {
    pname = "yazi-plugin-eza-preview";
    version = "2024-06-13"; # upstream master at time of packaging

    src = fetchFromGitHub sourceRepo;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r ./. "$out"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Yazi plugin that previews directories with eza";
      homepage = "https://github.com/sharklasers996/eza-preview.yazi";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };
}
