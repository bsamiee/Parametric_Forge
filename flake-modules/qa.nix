# Title         : qa.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa.nix
# ----------------------------------------------------------------------------
# Flake checks: Nix static analysis, both hosts' evals, and public-output build smoke; treefmt-nix lands its own `treefmt` check.
{self, ...}: {
  perSystem = {
    config,
    overlaidPkgs,
    system,
    ...
  }: let
    inherit (overlaidPkgs.lib) fileset mapAttrs' nameValuePair optionalAttrs;
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
    # Both-OS static gate as check rows: every context host's toplevel must evaluate, deriving from the context rows so any system a host runs
    # proves every host's eval and a new host or OS joins with zero edits. drvPath context is discarded so the row proves eval, never builds a host.
    # Scar: a dead VPS eval once shipped through Darwin-only switches.
    hostContext = import ../hosts/context.nix;
    hostEvals = optionalAttrs (builtins.elem system (map (host: host.system) (builtins.attrValues hostContext))) (mapAttrs' (
        name: host:
          nameValuePair "host-eval-${name}" (overlaidPkgs.runCommand "host-eval-${name}" {
            drvPath =
              builtins.unsafeDiscardStringContext
              self."${host.os}Configurations".${name}.config.system.build.toplevel.drvPath;
          } ''printf '%s\n' "$drvPath" >"$out"'')
      )
      hostContext);
  in {
    checks =
      hostEvals
      // {
        nix-static = overlaidPkgs.runCommand "nix-static" {nativeBuildInputs = [overlaidPkgs.deadnix overlaidPkgs.statix];} ''
          deadnix --fail ${nixSources}
          statix check ${nixSources}
          touch "$out"
        '';
      }
      # Every named public output gets build smoke; new packages join with zero edits here.
      // mapAttrs' (name: nameValuePair "pkg-${name}") config.packages;
  };
}
