# Title         : carbon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/carbon.nix
# ----------------------------------------------------------------------------
# Beautiful code screenshot generation with Dracula theme

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475A
# foreground    #F8F8F2
# comment       #6272A4
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #FF5555
# magenta       #d82f94
# pink          #E98FBE

let
  # Carbon config with Dracula theme
  carbonConfig = {
    latest-preset = {
      backgroundColor = "#15131F";
      theme = "dracula";
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

      # Custom Dracula color mappings for syntax highlighting
      custom = {
        background = "rgba(21, 19, 31, 1)";      # #15131F
        text = "rgba(248, 248, 242, 1)";         # #F8F8F2
        variable = "rgba(148, 242, 232, 1)";     # #94F2E8 cyan
        variable2 = "rgba(160, 114, 198, 1)";    # #A072C6 purple
        variable3 = "rgba(233, 143, 190, 1)";    # #E98FBE pink
        attribute = "rgba(80, 250, 123, 1)";     # #50FA7B green
        definition = "rgba(80, 250, 123, 1)";    # #50FA7B green
        keyword = "rgba(216, 47, 148, 1)";       # #d82f94 magenta
        operator = "rgba(216, 47, 148, 1)";      # #d82f94 magenta
        property = "rgba(148, 242, 232, 1)";     # #94F2E8 cyan
        number = "rgba(160, 114, 198, 1)";       # #A072C6 purple
        string = "rgba(241, 250, 140, 1)";       # #F1FA8C yellow
        comment = "rgba(98, 114, 164, 1)";       # #6272A4 comment
        meta = "rgba(249, 115, 89, 1)";          # #F97359 orange
        tag = "rgba(255, 85, 85, 1)";            # #FF5555 red
      };
    };
  };

  carbonConfigJson = builtins.toJSON carbonConfig;
  carbonCli = pkgs.nodePackages.carbon-now-cli;

  # Helper script to download Playwright browsers if missing.
  # Uses XDG cache to keep things tidy.
  playwrightEnsure = pkgs.writeShellScriptBin "carbon-playwright-install" ''
    set -euo pipefail
    export PLAYWRIGHT_BROWSERS_PATH="''${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright"
    mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
    # Detect any chromium build that playwright installs
    if find "$PLAYWRIGHT_BROWSERS_PATH" -maxdepth 1 -name 'chromium-*' -type d | grep -q .; then
      exit 0
    fi
    exec ${pkgs.nodejs_20}/bin/node \
      ${carbonCli}/lib/node_modules/carbon-now-cli/node_modules/playwright/cli.js \
      install chromium --with-deps
  '';

  # Wrapper that refreshes the preset, ensures Playwright, and runs with Node 20.
  carbonWrapped = pkgs.writeShellScriptBin "carbon-now" ''
    set -euo pipefail
    export PLAYWRIGHT_BROWSERS_PATH="''${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright"
    # Refresh preset each run so Carbon uses the curated Dracula config.
    cat > "$HOME/.carbon-now.json" <<'JSON'
${carbonConfigJson}
JSON
    carbon-playwright-install || true
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
    exec ${pkgs.nodejs_20}/bin/node \
      ${carbonCli}/lib/node_modules/carbon-now-cli/dist/cli.js \
      ''${lang_flag:-} "$@"
  '';
in
{
  # Expose only the wrapper + Playwright helper to avoid duplicate bins.
  home.packages = [ carbonWrapped playwrightEnsure ];
  # Note: .carbon-now.json is created by the wrapper on each run, not managed declaratively
}
