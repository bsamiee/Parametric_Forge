# Title         : qa.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa.nix
# ----------------------------------------------------------------------------
# Flake checks: Nix static analysis, jq syntax, both hosts' evals, and public-output build smoke; treefmt-nix lands its own `treefmt` check.
{self, ...}: {
  perSystem = {
    config,
    forgePkgs,
    system,
    ...
  }: let
    inherit (forgePkgs.lib) fileset mapAttrs' nameValuePair optionalAttrs;
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
        ]
        ++ [
          (fileset.difference
            (fileset.fileFilter (file: file.hasExt "nix") ../overlays)
            ../overlays/_sources)
        ]);
    };
    # .jq-only projection: jq has no formatter, so the compile gate below is the whole static surface for these programs.
    jqSources = fileset.toSource {
      root = ../.;
      fileset = fileset.fileFilter (file: file.hasExt "jq") ../overlays;
    };
    # Both-OS static gate as check rows: every context host's toplevel must evaluate, deriving from the context rows so any system a host runs
    # proves every host's eval and a new host or OS joins with zero edits. drvPath context is discarded so the row proves eval, never builds a host.
    # Scar: a dead VPS eval once shipped through Darwin-only switches.
    hostContext = import ../hosts/context.nix;
    hostEvals = optionalAttrs (builtins.elem system (map (host: host.system) (builtins.attrValues hostContext))) (mapAttrs' (
        name: host:
          nameValuePair "host-eval-${name}" (forgePkgs.runCommand "host-eval-${name}" {
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
        nix-static = forgePkgs.runCommand "forge-nix-static" {nativeBuildInputs = [forgePkgs.deadnix forgePkgs.statix];} ''
          deadnix --fail ${nixSources}
          statix check ${nixSources}
          touch "$out"
        '';

        # Compile gate: empty stdin, so the body never runs and the gate cannot hang. Programs written for `jq --arg` reference variables that
        # are compile errors when unbound, so every referenced $name is bound before the compile; jq's own $ENV, $__loc__, and $__prog__ stay.
        jq-syntax = forgePkgs.runCommand "forge-jq-syntax" {nativeBuildInputs = [forgePkgs.jq];} ''
          find ${jqSources} -name '*.jq' | LC_ALL=C sort | while IFS= read -r program; do
            defs=()
            while IFS= read -r name; do
              case "$name" in ENV | __loc__ | __prog__) continue ;; esac
              defs+=(--arg "$name" "")
            done < <(grep -o '\$[A-Za-z_][A-Za-z0-9_]*' "$program" | cut -c2- | sort -u)
            jq "''${defs[@]}" -f "$program" </dev/null >/dev/null || exit 1
          done
          touch "$out"
        '';
      }
      // mapAttrs' (name: nameValuePair "pkg-${name}") publicPackages;
  };
}
