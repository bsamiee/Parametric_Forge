# Title         : apple-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/apple-tools.nix
# ----------------------------------------------------------------------------
# Apple-platform code quality: Swift format/lint and the OSA (AppleScript/JXA)
# compile gate plus canonical formatter.
{
  config,
  lib,
  pkgs,
  ...
}: let
  style = import ../../../style.nix;
  swiftformatConfig = "${config.xdg.configHome}/swiftformat/config";
  swiftlintConfig = "${config.xdg.configHome}/swiftlint/config.yml";
  # --base-config seeds house style while every discovered project .swiftformat
  # still applies on top; an explicit caller config suppresses the injection.
  # The Swift version is derived from the live toolchain per call and rides the
  # seeded config, keeping it the weakest layer: project .swiftformat and
  # .swift-version files still win, and no toolchain means no injection.
  swiftformat = pkgs.writeShellApplication {
    name = "swiftformat";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      for arg in "$@"; do
        case "$arg" in
          --config | --config=* | --base-config | --base-config=*)
            exec ${pkgs.swiftformat}/bin/swiftformat "$@"
            ;;
        esac
      done
      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT
      cat "${swiftformatConfig}" >"$tmp/config"
      # BASH_REMATCH, never sed|head: head's early exit would SIGPIPE sed under
      # pipefail and drop the version injection on a race.
      ver_re='Swift version ([0-9]+\.[0-9]+)'
      if [[ "$(/usr/bin/swift --version 2>/dev/null || true)" =~ $ver_re ]]; then
        printf -- '--swift-version %s\n' "''${BASH_REMATCH[1]}" >>"$tmp/config"
      fi
      ${pkgs.swiftformat}/bin/swiftformat --base-config "$tmp/config" "$@"
    '';
  };
  # swiftlint reads .swiftlint.yml from the working directory only. The wrapper
  # keeps stock semantics when the cwd carries a config, promotes the nearest
  # ancestor config on subdirectory invocations, and falls back to the house
  # config only when no project law exists and the caller passes none.
  # SourceKitten loads sourcekitdInProc from the active developer toolchain,
  # which the nixpkgs binary cannot see without DYLD_FRAMEWORK_PATH.
  swiftlint = pkgs.writeShellApplication {
    name = "swiftlint";
    text = ''
      if [[ -z "''${DYLD_FRAMEWORK_PATH:-}" ]]; then
        dev="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
        for lib in "$dev/usr/lib" "$dev/Toolchains/XcodeDefault.xctoolchain/usr/lib"; do
          if [[ -d "$lib/sourcekitdInProc.framework" ]]; then
            export DYLD_FRAMEWORK_PATH="$lib"
            break
          fi
        done
      fi

      ${style.walkUp}
      _lint() {
        [[ -f "$PWD/.swiftlint.yml" ]] && exec ${pkgs.swiftlint}/bin/swiftlint "$@"
        for arg in "$@"; do
          case "$arg" in
            --config | --config=*) exec ${pkgs.swiftlint}/bin/swiftlint "$@" ;;
          esac
        done
        local cfg
        cfg="$(_walk_up .swiftlint.yml)" \
          && exec ${pkgs.swiftlint}/bin/swiftlint "$@" --config "$cfg"
        exec ${pkgs.swiftlint}/bin/swiftlint "$@" --config "${swiftlintConfig}"
      }

      # Option-first and path-first invocations are implicit lint; named
      # subcommands other than lint/analyze keep raw passthrough.
      case "''${1:-lint}" in
        lint | analyze | -*) _lint "$@" ;;
        *) if [[ -e "$1" ]]; then _lint "$@"; fi ;;
      esac
      exec ${pkgs.swiftlint}/bin/swiftlint "$@"
    '';
  };
  # osacompile is the only OSA syntax gate Apple ships; compile -> osadecompile
  # round-trip is the canonical, comment-preserving AppleScript formatter.
  # JXA compiles through the same gate; its formatting is prettier/biome-owned.
  forge-osa = pkgs.writeShellApplication {
    name = "forge-osa";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      usage() {
        printf 'usage: forge-osa <check|fmt> <file.applescript|file.jxa|file.js>...\n' >&2
        exit 2
      }
      [ "$#" -ge 2 ] || usage
      mode="$1"
      shift
      case "$mode" in check | fmt) ;; *) usage ;; esac
      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT
      status=0
      processed=0
      for src in "$@"; do
        case "$src" in
          *.applescript) lang=AppleScript ;;
          *.jxa | *.js) lang=JavaScript ;;
          *)
            printf '[SKIP] %s: not an OSA source\n' "$src" >&2
            continue
            ;;
        esac
        processed=$((processed + 1))
        out="$tmp/compiled-$processed.scpt"
        if ! /usr/bin/osacompile -l "$lang" -o "$out" "$src"; then
          status=1
          continue
        fi
        if [ "$mode" = fmt ] && [ "$lang" = AppleScript ]; then
          if ! /usr/bin/osadecompile "$out" >"$tmp/fmt"; then
            printf '[FAIL] %s: osadecompile\n' "$src" >&2
            status=1
            continue
          fi
          # $(<file) strips trailing newlines; printf restores exactly one, so
          # repeated fmt is byte-stable. Sibling temp + mv keeps the write atomic.
          printf '%s\n' "$(<"$tmp/fmt")" >"$src.fmt.$$"
          mv "$src.fmt.$$" "$src"
          printf '[FMT] %s\n' "$src"
        else
          printf '[OK] %s\n' "$src"
        fi
      done
      if [ "$processed" -eq 0 ]; then
        printf 'forge-osa: no OSA sources among arguments\n' >&2
        exit 2
      fi
      exit "$status"
    '';
  };
in
  lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    xdg.configFile = {
      # Style only — the wrapper appends the toolchain-derived --swift-version.
      "swiftformat/config".text = ''
        --indent ${toString style.indent}
        --max-width ${toString style.width}
        --linebreaks lf
      '';
      # indentation_width is opt-in; line_length warns at the house width.
      "swiftlint/config.yml".text = ''
        opt_in_rules:
          - indentation_width
        line_length:
          warning: ${toString style.width}
          error: 200
        indentation_width:
          indentation_width: ${toString style.indent}
      '';
    };

    home.packages = [
      # --- [SWIFT_CODE_QUALITY]
      swiftformat # Swift formatter (nicklockwood; house base-config injected)
      swiftlint # Swift linter (project config promoted, house config fallback)

      # --- [APPLESCRIPT_JXA]
      forge-osa # OSA syntax gate + canonical AppleScript formatter
    ];
  }
