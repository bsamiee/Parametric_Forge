# Title         : qa.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa.nix
# ----------------------------------------------------------------------------
# Flake checks: formatting, Nix static analysis, and public-output build smoke.
{self, ...}: {
  perSystem = {
    config,
    forgePkgs,
    ...
  }: let
    inherit (forgePkgs.lib) fileset mapAttrs' nameValuePair;
    # Every named public output gets build smoke; new packages join with zero edits here.
    publicPackages = removeAttrs config.packages ["default"];
    # .nix-only projection: binaries and prose never invalidate the check.
    nixSources = fileset.toSource {
      root = ../.;
      fileset = fileset.unions ([../flake.nix]
        ++ map (fileset.fileFilter (file: file.hasExt "nix")) [
          ../flake-modules
          ../hosts
          ../modules
          ../overlays
        ]);
    };
    # .jq-only projection: `jq -f <file> </dev/null` compiles without running
    # the body; named args bind at compile time, so the gate predefines them.
    jqSources = fileset.toSource {
      root = ../.;
      fileset = fileset.fileFilter (file: file.hasExt "jq") ../overlays;
    };
  in {
    checks =
      {
        formatting = config.treefmt.build.check self;

        nix-static = forgePkgs.runCommand "forge-nix-static" {nativeBuildInputs = [forgePkgs.deadnix forgePkgs.statix];} ''
          deadnix --fail ${nixSources}
          statix check ${nixSources}
          touch "$out"
        '';

        jq-syntax = forgePkgs.runCommand "forge-jq-syntax" {nativeBuildInputs = [forgePkgs.jq];} ''
          fail=0
          for f in $(find ${jqSources} -type f -name '*.jq' | sort); do
            args=()
            for v in $(grep -oE '\$[A-Za-z_][A-Za-z0-9_]*' "$f" | sort -u); do
              name=''${v:1}
              case "$name" in ENV | __loc__ | __prog__) continue ;; esac
              args+=(--arg "$name" "")
            done
            jq "''${args[@]}" -f "$f" </dev/null >/dev/null || {
              echo "[SYNTAX] ''${f#${jqSources}/}" >&2
              fail=1
            }
          done
          test "$fail" -eq 0
          touch "$out"
        '';
      }
      // mapAttrs' (name: nameValuePair "pkg-${name}") publicPackages;
  };
}
