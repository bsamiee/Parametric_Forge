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
    devShells.default = forgePkgs.mkShell {
      packages = with forgePkgs; [
        git
        alejandra
        statix
        deadnix
        nix-output-monitor
        nix-update
        nix-init
        nixpkgs-review
        nurl
        nix-fast-build
        bats
        shellcheck
        shfmt
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
          "checks/*.bats"
          "overlays/forge-provision/*.sh"
          "overlays/forge-provision/**/*.sh"
        ];
      };
    };
  };
}
