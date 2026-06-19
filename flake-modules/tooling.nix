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
    pkgs,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
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

    formatter = pkgs.writeShellApplication {
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
    };
  };
}
