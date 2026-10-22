# Title         : qa.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa.nix
# ----------------------------------------------------------------------------
# Flake checks: Nix static analysis and every host's eval; treefmt-nix lands its own `treefmt` check. redeploy's per-host build builds the packages.
{self, ...}: {
  perSystem = {overlaidPkgs, ...}: let
    inherit (overlaidPkgs.lib) fileset mapAttrs' nameValuePair;
    # .nix-only projection: binaries and prose never invalidate the check.
    nixSources = fileset.toSource {
      root = ../.;
      fileset = fileset.unions ([../flake.nix]
        ++ map (fileset.fileFilter (file: file.hasExt "nix")) [
          ../flake-modules
          ../hosts
          ../modules
        ]
        ++ [
          (fileset.difference
            (fileset.fileFilter (file: file.hasExt "nix") ../overlays)
            ../overlays/_sources)
        ]);
    };
    # Every host's toplevel must evaluate; drvPath context is discarded so the row proves eval, never builds a host.
    hostEvals =
      mapAttrs' (
        name: host:
          nameValuePair "host-eval-${name}" (overlaidPkgs.runCommand "host-eval-${name}" {
            drvPath = builtins.unsafeDiscardStringContext host.config.system.build.toplevel.drvPath;
          } ''printf '%s\n' "$drvPath" >"$out"'')
      )
      self.darwinConfigurations;
  in {
    checks =
      hostEvals
      // {
        nix-static = overlaidPkgs.runCommand "nix-static" {nativeBuildInputs = [overlaidPkgs.deadnix overlaidPkgs.statix];} ''
          deadnix --fail ${nixSources}
          statix check ${nixSources}
          touch "$out"
        '';
      };
  };
}
