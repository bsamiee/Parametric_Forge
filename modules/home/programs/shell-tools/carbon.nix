# Title         : carbon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/carbon.nix
# ----------------------------------------------------------------------------
# Beautiful code screenshot generation themed from the estate palette owner

{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  fonts = config.forge.fonts;

  carbonConfig = {
    latest-preset = {
      backgroundColor = palette.background.hex;
      # The custom map below is the active theme; the CLI renders it under this id.
      theme = "carbon-now-cli-theme";
      windowTheme = "macos";
      windowControls = true;
      fontFamily = fonts.projections.cssMono;
      fontSize = "16px";
      lineNumbers = false;
      firstLineNumber = 1;
      selectedLines = "*";
      dropShadow = true;
      dropShadowOffsetY = "20px";
      dropShadowBlurRadius = "68px";
      widthAdjustment = true;
      width = "680px";
      lineHeight = fonts.metrics.cssLineHeight;
      paddingVertical = "48px";
      paddingHorizontal = "48px";
      squaredImage = false;
      watermark = false;
      exportSize = "2x";
      type = "png";

      # Custom theme: CodeMirror token vocabulary mapped onto the master scope palette.
      custom = {
        background = palette.background.rgba "1";
        text = palette.foreground.rgba "1";
        variable = palette.blue.rgba "1";
        variable2 = palette.blue.rgba "1";
        variable3 = palette.purple.rgba "1";
        attribute = palette.magenta.rgba "1";
        definition = palette.green.rgba "1";
        keyword = palette.pink.rgba "1";
        operator = palette.subtle.rgba "1";
        property = palette.blue.rgba "1";
        number = palette.purple.rgba "1";
        string = palette.yellow.rgba "1";
        comment = palette.comment.rgba "1";
        meta = palette.orange.rgba "1";
        tag = palette.magenta.rgba "1";
      };
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
