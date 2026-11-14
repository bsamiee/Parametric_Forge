{self, ...}: {
  perSystem = {pkgs, ...}: {
    checks.statix = pkgs.runCommand "statix" {nativeBuildInputs = [pkgs.statix];} ''
      statix check --ignore 'overlays/_sources/**' ${self}
      touch "$out"
    '';
  };
}
