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

  carbonConfig = {
    latest-preset = {
      backgroundColor = palette.background.hex;
      # The custom map below is the active theme; the CLI renders it under this id.
      theme = "carbon-now-cli-theme";
      windowTheme = "macos";
      windowControls = true;
      fontFamily = "GeistMono Nerd Font, Geist Mono, Fira Code";
      fontSize = "16px";
      lineNumbers = false;
      firstLineNumber = 1;
      selectedLines = "*";
      dropShadow = true;
      dropShadowOffsetY = "20px";
      dropShadowBlurRadius = "68px";
      widthAdjustment = true;
      width = "680px";
      lineHeight = "140%";
      paddingVertical = "48px";
      paddingHorizontal = "48px";
      squaredImage = false;
      watermark = false;
      exportSize = "2x";
      type = "png";

      # Custom theme: CodeMirror vocabulary mapped onto the owner's syntax roles
      custom = {
        background = palette.background.rgba "1";
        text = palette.foreground.rgba "1";
        variable = palette.cyan.rgba "1";
        variable2 = palette.purple.rgba "1";
        variable3 = palette.pink.rgba "1";
        attribute = palette.green.rgba "1";
        definition = palette.green.rgba "1";
        keyword = palette.magenta.rgba "1";
        operator = palette.magenta.rgba "1";
        property = palette.cyan.rgba "1";
        number = palette.purple.rgba "1";
        string = palette.yellow.rgba "1";
        comment = palette.comment.rgba "1";
        meta = palette.orange.rgba "1";
        tag = palette.red.rgba "1";
      };
    };
  };

  carbonConfigJson = builtins.toJSON carbonConfig;
  carbonCli = pkgs.carbon-now-cli;

  # Helper script to download Playwright browsers if missing.
  playwrightEnsure = pkgs.writeShellScriptBin "carbon-playwright-install.sh" ''
    set -euo pipefail
    export PLAYWRIGHT_BROWSERS_PATH="''${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright"
    mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
    # Detect any chromium build that playwright installs
    if find "$PLAYWRIGHT_BROWSERS_PATH" -maxdepth 1 -name 'chromium-*' -type d | grep -q .; then
      exit 0
    fi
    exec ${pkgs.nodejs}/bin/node \
      ${carbonCli}/lib/node_modules/carbon-now-cli/node_modules/playwright/cli.js \
      install chromium --with-deps
  '';

  # Wrapper that refreshes the preset, ensures Playwright, and runs with current Node.
  carbonWrapped = pkgs.writeShellScriptBin "carbon-now.sh" ''
        set -euo pipefail
        export PLAYWRIGHT_BROWSERS_PATH="''${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright"
        # Refresh preset each run so Carbon uses the curated Dracula config.
        cat > "$HOME/.carbon-now.json" <<'JSON'
    ${carbonConfigJson}
    JSON
        carbon-playwright-install.sh || true
        # Derive language from the first non-flag path when --language is not supplied.
        lang_flag=""
        for arg in "$@"; do
          case "$arg" in
            --language|-l) lang_flag="set"; break ;;
            --language=*|-l=*) lang_flag="set"; break ;;
            --*) ;;  # skip flags
            *)
              ext="''${arg##*.}"
              case "$ext" in
                nix) lang_flag="--language nix" ;;
                zsh) lang_flag="--language zsh" ;;
                sh|bash) lang_flag="--language bash" ;;
                lua) lang_flag="--language lua" ;;
              esac
              break
              ;;
          esac
        done
        exec ${pkgs.nodejs}/bin/node \
          ${carbonCli}/lib/node_modules/carbon-now-cli/dist/cli.js \
          ''${lang_flag:-} "$@"
  '';
in {
  home.packages = [carbonWrapped playwrightEnsure];
}
