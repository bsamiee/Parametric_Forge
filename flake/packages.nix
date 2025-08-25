# Title         : flake/packages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake/packages.nix
# ----------------------------------------------------------------------------
# Custom packages and runnable apps

{ inputs, myLib, ... }:

{
  perSystem =
    {
      self',
      pkgs,
      system,
      lib,
      ...
    }:
    let
      # --- Rust Overlay Configuration ---------------------------------------
      pkgsWithRust = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.rust-overlay.overlays.default ];
      };
      # --- Pin Rust Toolchain -----------------------------------------------
      rustToolchain = pkgsWithRust.rust-bin.stable."1.89.0".default.override {
        extensions = [
          "rust-src"
          "rust-analyzer"
        ];
        targets = [
          "aarch64-apple-darwin"
          "x86_64-apple-darwin"
          "x86_64-unknown-linux-gnu"
          "aarch64-unknown-linux-gnu"
        ];
      };
      # --- Create Rust Platform ---------------------------------------------
      rustPlatform = pkgsWithRust.makeRustPlatform {
        cargo = rustToolchain;
        rustc = rustToolchain;
      };
    in
    {
      packages = {
        # --- Bootstrap Script -----------------------------------------------
        forge-bootstrap = pkgs.writeShellApplication {
          name = "forge-bootstrap";
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            git
          ];
          text = ''
            set -euo pipefail

            # Parse arguments
            APPLY=false
            INIT=false
            while [[ $# -gt 0 ]]; do
              case $1 in
                --apply) APPLY=true; shift ;;
                --init) INIT=true; shift ;;
                --help)
                  echo "Parametric Forge Bootstrap"
                  echo ""
                  echo "Usage: forge-bootstrap [OPTIONS]"
                  echo ""
                  echo "Options:"
                  echo "  --apply    Apply the detected configuration immediately"
                  echo "  --init     Initialize user configuration if missing"
                  echo "  --help     Show this help message"
                  exit 0
                  ;;
                *) echo "Unknown option: $1"; exit 1 ;;
              esac
            done

            echo "🚀 Parametric Forge Bootstrap"
            echo "═══════════════════════════════════════════════════════════════"
            echo ""

            # Detect platform and configuration
            CONFIG=""
            REBUILD_CMD=""

            if [[ "$OSTYPE" == "darwin"* ]]; then
              # Detect architecture
              if [[ "$(uname -m)" == "arm64" ]]; then
                CONFIG="default"  # aarch64-darwin
                echo "✓ Platform: macOS (Apple Silicon)"
              else
                CONFIG="x86_64"
                echo "✓ Platform: macOS (Intel)"
              fi
              REBUILD_CMD="darwin-rebuild switch --flake .#$CONFIG"

            elif [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
              CONFIG="container"
              echo "✓ Platform: Container environment"
              REBUILD_CMD="nixos-rebuild switch --flake .#container"

            elif [[ "$OSTYPE" == "linux"* ]]; then
              # Check architecture for Linux
              if [[ "$(uname -m)" == "aarch64" ]]; then
                CONFIG="aarch64-vm"
                echo "✓ Platform: Linux/VM (ARM64)"
              else
                CONFIG="vm"
                echo "✓ Platform: Linux/VM (x86_64)"
              fi
              REBUILD_CMD="nixos-rebuild switch --flake .#$CONFIG"

            else
              echo "⚠ Unknown platform: $OSTYPE"
              echo "Manual configuration required"
              exit 1
            fi

            echo "✓ Configuration: $CONFIG"
            echo "✓ User: $USER"
            echo ""

            # Initialize user config if requested
            if [ "$INIT" = true ]; then
              echo "Initializing user configuration..."

              # Check if we're in a git repo
              if ! git rev-parse --git-dir > /dev/null 2>&1; then
                echo "  → Initializing git repository..."
                git init
                git add .
                git commit -m "Initial Parametric Forge configuration"
              fi

              echo "  ✓ User configuration initialized"
              echo ""
            fi

            # Show or apply configuration
            if [ "$APPLY" = true ]; then
              echo "Applying configuration..."
              echo "  → Running: $REBUILD_CMD"
              echo ""
              echo "═══════════════════════════════════════════════════════════════"

              # Execute the rebuild command
              if command -v nix >/dev/null 2>&1; then
                eval "$REBUILD_CMD"
                echo ""
                echo "═══════════════════════════════════════════════════════════════"
                echo "✓ Configuration applied successfully!"
              else
                echo "⚠ Nix is not installed. Please install Nix first."
                echo "  Visit: https://nixos.org/download"
                exit 1
              fi
            else
              echo "Configuration detected. To apply:"
              echo ""
              echo "  $REBUILD_CMD"
              echo ""
              echo "Or run bootstrap with --apply flag:"
              echo ""
              echo "  nix run .#bootstrap -- --apply"
            fi

            echo ""
            echo "Development commands:"
            echo "  nix develop        # Enter development shell"
            echo "  nix flake check    # Run quality checks"
            echo "  nix fmt            # Format code"
          '';
        };
        # --- System Check Script --------------------------------------------
        check-system = pkgs.writeShellApplication {
          name = "check-system";
          runtimeInputs = with pkgs; [
            coreutils
            nix
            gnugrep
          ];
          text = ''
            set -euo pipefail

            echo "═══════════════════════════════════════════════════════════════"
            echo "                 Parametric Forge System Check                 "
            echo "═══════════════════════════════════════════════════════════════"
            echo ""

            echo "System Information:"
            echo "  OS Type:      $OSTYPE"
            echo "  Architecture: $(uname -m)"
            echo "  Hostname:     $(hostname)"
            echo "  User:         $USER"
            echo "  Home:         $HOME"
            echo "  Nix System:   ${system}"
            echo ""

            echo "Nix Configuration:"
            echo "  Version: $(nix --version)"

            if command -v nix >/dev/null 2>&1; then
              echo "  Store:   $(nix store ping --json | ${pkgs.jq}/bin/jq -r .url 2>/dev/null || echo '/nix/store')"

              echo ""
              echo "Experimental Features:"
              nix show-config | grep "experimental-features" | sed 's/^/  /' || echo "  None enabled"
            fi

            echo ""
            echo "Environment Detection:"

            if [[ -f /.dockerenv ]]; then
              echo "  ✓ Docker container detected"
            elif [[ -f /run/.containerenv ]]; then
              echo "  ✓ Podman container detected"
            elif [[ "$OSTYPE" == "darwin"* ]]; then
              echo "  ✓ macOS system detected"
            elif [[ "$OSTYPE" == "linux"* ]]; then
              if [[ -d /sys/class/dmi/id ]] && grep -q "VirtualBox\|VMware\|QEMU\|Hyper-V" /sys/class/dmi/id/product_name 2>/dev/null; then
                echo "  ✓ Virtual machine detected"
              else
                echo "  ✓ Native Linux system detected"
              fi
            fi

            echo ""
            echo "═══════════════════════════════════════════════════════════════"
          '';
        };
        # --- Setup Script ---------------------------------------------------
        setup = pkgs.writeShellApplication {
          name = "parametric-forge-setup";
          runtimeInputs = with pkgs; [
            coreutils
            curl
            bash
          ];
          text = ''
            echo "═══════════════════════════════════════════════════════════════"
            echo "                    Parametric Forge Setup                     "
            echo "═══════════════════════════════════════════════════════════════"
            echo ""

            # Check if we're in a Parametric Forge directory
            if [[ -f "./setup.sh" && -f "flake.nix" ]]; then
              echo "✓ Found Parametric Forge setup script in current directory"
              echo "  Running: ./setup.sh $*"
              echo ""
              exec ./setup.sh "$@"
            else
              echo "⚠ This command should be run from a Parametric Forge directory"
              echo ""
              echo "To get started:"
              echo "  1. Clone the repository:"
              echo "     git clone <parametric-forge-repo>"
              echo "  2. Change to the directory:"
              echo "     cd parametric-forge"
              echo "  3. Run the setup:"
              echo "     ./setup.sh"
              echo ""
              echo "Or run directly from the repository:"
              echo "  nix run github:bsamiee/parametric-forge#setup"
              echo ""
              exit 1
            fi
          '';
        };
        # --- Interactive Interface ------------------------------------------
        # Development version with faster rebuilds
        interface-dev = myLib.build.rust pkgs (
          rustPlatform.buildRustPackage {
            pname = "parametric-forge-interface-dev";
            version = "0.1.0-dev";
            src = lib.cleanSourceWith {
              src = ../interface;
              filter = path: _type: !(lib.hasSuffix "target" path || lib.hasSuffix "result" path);
            };
            cargoLock = {
              lockFile = ../interface/Cargo.lock;
              allowBuiltinFetchGit = true;
            };
            # Faster dev build settings
            env = {
              CARGO_BUILD_RUSTFLAGS = "-C opt-level=1";
            };
            # Skip unnecessary inputs for faster builds
            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs =
              with pkgs;
              [
                libiconv
              ]
              ++ lib.optionals pkgs.stdenv.isDarwin [
                pkgs.darwin.apple_sdk.frameworks.Security
                pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
                pkgs.darwin.apple_sdk.frameworks.CoreFoundation
              ]
              ++ lib.optionals pkgs.stdenv.isLinux [
                openssl
              ];
          }
        );

        # Production version with optimizations
        interface = myLib.build.rust pkgs (
          rustPlatform.buildRustPackage {
            pname = "parametric-forge-interface";
            version = "0.1.0";
            src = lib.cleanSourceWith {
              src = ../interface;
              filter = path: _type: !(lib.hasSuffix "target" path || lib.hasSuffix "result" path);
            };
            cargoLock = {
              lockFile = ../interface/Cargo.lock;
              allowBuiltinFetchGit = true;
            };
            # Native build inputs for compilation
            nativeBuildInputs = with pkgs; [
              pkg-config
            ];
            # Runtime and build dependencies
            buildInputs =
              with pkgs;
              [
                libiconv
              ]
              ++ lib.optionals pkgs.stdenv.isDarwin [
                # Darwin framework dependencies (using system frameworks)
                pkgs.darwin.apple_sdk.frameworks.Security
                pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
                pkgs.darwin.apple_sdk.frameworks.CoreFoundation
              ]
              ++ lib.optionals pkgs.stdenv.isLinux [
                # Linux-specific dependencies
                openssl
              ];
            # Environment variables for optimization
            env = {
              CARGO_BUILD_RUSTFLAGS = "-C target-cpu=native";
            };
            # Comprehensive meta attributes
            meta = with lib; {
              description = "Interactive TUI for Parametric Forge configuration management";
              longDescription = ''
                A modern terminal user interface for configuring and managing
                Parametric Forge Nix-based system configurations. Provides an
                intuitive way to select packages, configure system settings,
                and apply configurations without needing to understand Nix syntax.
              '';
              homepage = "https://github.com/bsamiee/parametric-forge";
              license = licenses.mit;
              maintainers = [ "Bardia Samiee <b.samiee93@gmail.com>" ];
              platforms = platforms.unix;
              mainProgram = "forge-interface";
            };
          }
        );
      };
      # --- Apps -------------------------------------------------------------
      apps = {
        setup = {
          type = "app";
          program = "${self'.packages.setup}/bin/parametric-forge-setup";
          meta.description = "Zero-friction entry point for Parametric Forge setup";
        };
        bootstrap = {
          type = "app";
          program = "${self'.packages.forge-bootstrap}/bin/forge-bootstrap";
          meta.description = "Bootstrap Parametric Forge configuration";
        };
        check-system = {
          type = "app";
          program = "${self'.packages.check-system}/bin/check-system";
          meta.description = "Check system configuration and environment";
        };
        interface = {
          type = "app";
          program = "${self'.packages.interface}/bin/forge-interface";
          meta.description = "Interactive TUI for Parametric Forge configuration management";
        };
        interface-dev = {
          type = "app";
          program = "${self'.packages.interface-dev}/bin/forge-interface";
          meta.description = "Development version of interface (faster builds)";
        };
      };
    };
}
