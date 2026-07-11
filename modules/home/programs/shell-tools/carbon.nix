# Title         : carbon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/carbon.nix
# ----------------------------------------------------------------------------
# Beautiful code screenshot generation themed from the estate palette owner
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) roles syntaxScopes;
  fonts = config.forge.fonts;

  # CodeMirror token -> master scope pivot: each token names its owning syntaxScopes row, so a hue rebind in the theme owner lands here with
  # zero edits; an unknown row name faults at eval. Chrome (background/text) rides the surface and text roles like every editor projection.
  scopeOf = name: (lib.findFirst (r: r.name == name) (throw "carbon: no syntax scope row named ${name}") syntaxScopes).color;
  tokenRows = {
    variable = "Variable";
    variable2 = "Variable";
    variable3 = "Constant";
    attribute = "Attribute";
    definition = "Function";
    keyword = "Keyword";
    operator = "Operator";
    property = "Variable";
    number = "Number";
    string = "String";
    comment = "Comment";
    meta = "Escape";
    tag = "Tag";
  };

  carbonConfig = {
    latest-preset = {
      backgroundColor = roles.surface.base.hex;
      # The custom map below is the active theme; the CLI renders it under this id.
      theme = "carbon-now-cli-theme";
      windowTheme = "macos";
      windowControls = true;
      fontFamily = fonts.projections.cssMono;
      fontSize = fonts.projections.screenshotSize;
      lineNumbers = false;
      firstLineNumber = 1;
      selectedLines = "*";
      dropShadow = true;
      dropShadowOffsetY = "20px";
      dropShadowBlurRadius = "68px";
      widthAdjustment = true;
      width = "680px";
      lineHeight = fonts.projections.screenshotLeading;
      paddingVertical = "48px";
      paddingHorizontal = "48px";
      squaredImage = false;
      watermark = false;
      exportSize = "2x";
      type = "png";

      # Custom theme: CodeMirror token vocabulary folded from the master scope pivot rows.
      custom =
        {
          background = roles.surface.base.rgba "1";
          text = roles.text.primary.rgba "1";
        }
        // lib.mapAttrs (_: name: (scopeOf name).rgba "1") tokenRows;
    };
  };

  carbonConfigJson = builtins.toJSON carbonConfig;
  carbonCli = pkgs.carbon-now-cli;
  carbonModules = "${carbonCli}/lib/node_modules/carbon-now-cli";

  # One browser-provisioning vocabulary: every Playwright consumer exports this.
  browsersPath = ''export PLAYWRIGHT_BROWSERS_PATH="''${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright"'';

  # Idempotent Chromium provisioner: exits 0 on a warm cache, otherwise defers to Carbon's embedded Playwright CLI; failure propagates to the caller.
  playwrightEnsure = pkgs.writeShellApplication {
    name = "carbon-playwright-install.sh";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.nodejs];
    text = ''
      ${browsersPath}
      mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
      # Warm means COMPLETE: key on playwright's own INSTALLATION_COMPLETE marker (written after extraction), so a signal-killed install never fakes a
      # warm cache; -print -quit, never a grep pipe (pipefail turns grep -q's early exit into a SIGPIPE'd find).
      if [ -n "$(find "$PLAYWRIGHT_BROWSERS_PATH" -maxdepth 2 -path '*/chromium-*/INSTALLATION_COMPLETE' -print -quit)" ]; then
        exit 0
      fi
      exec node ${carbonModules}/node_modules/playwright/cli.js install chromium --with-deps
    '';
  };

  carbonWrapped = pkgs.writeShellApplication {
    name = "carbon-now.sh";
    runtimeInputs = [pkgs.coreutils pkgs.nodejs playwrightEnsure];
    text = ''
      ${browsersPath}
      # Refresh the preset each run so Carbon renders the curated palette map; temp-plus-rename keeps a concurrent render off a half-written preset.
      preset_tmp="$(mktemp "$HOME/.carbon-now.json.XXXXXX")"
      cat >"$preset_tmp" <<'JSON'
      ${carbonConfigJson}
      JSON
      mv -f "$preset_tmp" "$HOME/.carbon-now.json"
      # Degraded branch, never a mask: a warm browser cache can still render, and the final Carbon process owns the real exit code.
      if ! carbon-playwright-install.sh; then
        printf 'carbon-now.sh: warning: Playwright Chromium install failed; continuing with existing browser cache\n' >&2
      fi
      # Derive language from the first non-flag path when --language is absent.
      lang_args=()
      for arg in "$@"; do
        case "$arg" in
          --language | -l | --language=* | -l=*) break ;;
          --*) ;;
          *)
            case "''${arg##*.}" in
              nix) lang_args=(--language nix) ;;
              zsh) lang_args=(--language zsh) ;;
              sh | bash) lang_args=(--language bash) ;;
              lua) lang_args=(--language lua) ;;
            esac
            break
            ;;
        esac
      done
      exec node ${carbonModules}/dist/cli.js "''${lang_args[@]}" "$@"
    '';
  };
in {
  home.packages = [carbonWrapped playwrightEnsure];
}
