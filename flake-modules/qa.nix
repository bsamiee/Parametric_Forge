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
    system,
    ...
  }: let
    inherit (forgePkgs.lib) fileset findFirst getName mapAttrs' nameValuePair optionalAttrs;
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
    # .jq-only projection checked through the fmt front door: its jq lane owns
    # the compile gate (empty stdin, pre-bound $vars), so one implementation
    # serves the CLI and this check, and CI proves the CLI on every run.
    jqSources = fileset.toSource {
      root = ../.;
      fileset = fileset.fileFilter (file: file.hasExt "jq") ../overlays;
    };
    # Name-keyed lookup: the fmt roster can grow or reorder without breaking this seam.
    fmtCli =
      findFirst (p: getName p == "fmt" || (p.meta.mainProgram or "") == "fmt")
      (throw "scripts/fmt.nix no longer exports the fmt CLI")
      (import ../modules/home/scripts/fmt.nix {pkgs = forgePkgs;}).home.packages;
    # Both-OS static gate as check rows: every context host's toplevel must
    # evaluate (scar: a dead maghz eval shipped through darwin-only switches).
    # The gate derives from the context rows — any system a host runs proves
    # every host's eval, so each operator seat carries the full pair and a new
    # host or OS joins with zero edits here. drvPath context is discarded so
    # the row proves eval, never builds a host.
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
        formatting = config.treefmt.build.check self;

        nix-static = forgePkgs.runCommand "forge-nix-static" {nativeBuildInputs = [forgePkgs.deadnix forgePkgs.statix];} ''
          deadnix --fail ${nixSources}
          statix check ${nixSources}
          touch "$out"
        '';

        jq-syntax = forgePkgs.runCommand "forge-jq-syntax" {} ''
          ${fmtCli}/bin/fmt --self-test
          ${fmtCli}/bin/fmt --check ${jqSources}
          touch "$out"
        '';
      }
      // mapAttrs' (name: nameValuePair "pkg-${name}") publicPackages;
  };
}
