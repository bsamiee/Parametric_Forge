# Title         : tooling.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/tooling.nix
# ----------------------------------------------------------------------------
# Developer shell and formatting surfaces.
_: {
  perSystem = {
    config,
    forgePkgs,
    ...
  }: {
    # Repository-maintenance shell: formatter plus flake proof/update helpers.
    # Machine tooling (git, shellcheck, shfmt, LSPs) is Home Manager-owned.
    devShells.default = forgePkgs.mkShell {
      packages = [
        config.formatter
        forgePkgs.deadnix
        forgePkgs.statix
        forgePkgs.nix-fast-build
        forgePkgs.nix-init
        forgePkgs.nix-output-monitor
        forgePkgs.nix-update
        forgePkgs.nixpkgs-review
        forgePkgs.nurl
      ];
    };

    formatter = forgePkgs.writeShellApplication {
      name = "forge-fmt";
      runtimeInputs = [config.treefmt.build.wrapper];
      text = ''
        args=()
        for arg in "$@"; do
          if [[ "$arg" == "--check" ]]; then
            args+=("--ci")
          else
            args+=("$arg")
          fi
        done
        exec treefmt "''${args[@]}"
      '';
    };

    treefmt = {
      flakeCheck = false;
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;
      settings.formatter.shfmt = {
        command = "${forgePkgs.shfmt}/bin/shfmt";
        options = ["-w" "-i" "2" "-ci"];
        includes = [
          "overlays/forge-provision/*.sh"
          "overlays/forge-provision/**/*.sh"
        ];
      };
    };
  };
}
