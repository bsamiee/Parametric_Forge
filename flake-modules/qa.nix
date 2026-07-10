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
    # .jq-only projection checked through the fmt front door: its jq lane owns
    # the compile gate (empty stdin, pre-bound $vars), so one implementation
    # serves the CLI and this check, and CI proves the CLI on every run.
    jqSources = fileset.toSource {
      root = ../.;
      fileset = fileset.fileFilter (file: file.hasExt "jq") ../overlays;
    };
    fmtCli = builtins.head (import ../modules/home/scripts/fmt.nix {pkgs = forgePkgs;}).home.packages;
  in {
    checks =
      {
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
