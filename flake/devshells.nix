# Title         : flake/devshells.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake/devshells.nix
# ----------------------------------------------------------------------------
# Development shell environments

{ myLib, ... }:

{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells = {
        # --- Default Nix Development Shell ---------------------------------
        default = pkgs.mkShell {
          name = "parametric-forge-dev";

          packages = with pkgs; [
            # --- Package Management and Review -----------------------------
            nix-eval-jobs # Parallel evaluation
            nixpkgs-review # Review nixpkgs changes
            flake-checker # Check flake health
            nix-fast-build # Fast parallel building
            home-manager # Home-manager CLI

            # --- Code Quality Tools ----------------------------------------
            nixfmt-rfc-style # Nix code formatter
            deadnix # Find dead code
            statix # Nix linter
            nil # Nix language server

            # --- Nix Analysis and Visualization ----------------------------
            nix-tree # Interactive dependency explorer
            nix-du # Store space analyzer
            nix-diff # Derivation-level comparison
            nvd # Generation-level comparison
            nix-visualize # Static dependency graphs
            graphviz # Graph visualization (dependency for nix-visualize)

            # --- Additional Tools -------------------------------------------
            nix-output-monitor
            nix-direnv
            cachix
          ];

          shellHook = ''
            echo "═══════════════════════════════════════════════════════"
            echo "  Parametric Forge Development Environment"
            echo "═══════════════════════════════════════════════════════"
            echo ""
            echo "📦 System: ${system}"
            echo "👤 User: $USER"
            echo ""

            echo "Checking Nix configuration..."
            if nix show-config | grep -q "experimental-features.*flakes"; then
              echo "  ✓ Flakes enabled"
            else
              echo "  ⚠ Flakes not enabled in system config"
            fi

            if nix show-config | grep -q "experimental-features.*nix-command"; then
              echo "  ✓ Nix command enabled"
            else
              echo "  ⚠ Nix command not enabled in system config"
            fi

            echo ""
            echo "🔍 Analysis Tools (occasional use):"
            echo "  nix-tree          - Interactive dependency browser"
            echo "  nix-du            - Store space analyzer"
            echo "  nix-diff          - Compare derivations"
            echo "  nvd               - Compare generations"
            echo "  nix-visualize     - Generate dependency graphs"
            echo ""
            echo "📦 Package Tools:"
            echo "  nixpkgs-review    - Review nixpkgs changes"
            echo "  flake-checker     - Check flake health"
            echo "  nix-eval-jobs     - Parallel evaluation"
            echo ""
            echo "🚀 Commands:"
            ${
              if myLib.isDarwin system then
                ''
                  echo "  darwin-rebuild switch --flake .    # Apply Darwin configuration"
                ''
              else
                ''
                  echo "  nixos-rebuild switch --flake .     # Apply NixOS configuration"
                ''
            }
            echo "  home-manager switch --flake .      # Apply Home configuration"
            echo "  nix flake update                   # Update all inputs"
            echo "  nix flake check                    # Run all quality checks"
            echo "  nix fmt                            # Format all code"
            echo "  nom build .#<output>               # Build with better output"
            echo "  nix run .#bootstrap                # Run bootstrap script"
            echo "  nix run .#check-system             # Check system details"
            echo ""
            echo "💡 Available development shells:"
            echo "  nix develop .#python               # Python development"
            echo "  nix develop .#rust                 # Rust development"
            echo "  nix develop .#lua                  # Lua development"
            echo "  nix develop .#minimal              # Minimal Nix tools"
            echo ""
          '';
        };

        # --- Specialized Shells ---------------------------------------------
        minimal = pkgs.mkShell {
          name = "minimal-nix";
          packages = with pkgs; [
            nixfmt-rfc-style
            nil
          ];
        };

        # --- Language-Specific Development Shells --------------------------
        python = import ../devshells/python.nix { inherit pkgs myLib; };
        rust = import ../devshells/rust.nix { inherit pkgs myLib; };
        lua = import ../devshells/lua.nix { inherit pkgs myLib; };
      };
    };
}
