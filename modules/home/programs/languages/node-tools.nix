{
  lib,
  pkgs,
  ...
}: let
  toolRows = (import ../../../../overlays/manifest.nix).extensions.npm-tools.rows;
  commands = lib.concatMapAttrs (package: row:
    lib.genAttrs row.commands (command:
      pkgs.writeShellScriptBin command ''
        PATH=${pkgs.nodejs}/bin:$PATH exec npx --prefix=${pkgs.emptyDirectory} --yes --package=${lib.escapeShellArg "${package}@${row.version}"} ${command} "$@"
      ''))
  toolRows;
  headlessShell = pkgs.playwright-driver.browsers.override {
    withChromium = false;
    withChromiumHeadlessShell = true;
    withFfmpeg = false;
    withFirefox = false;
    withWebkit = false;
  };
  headlessShellRevision = pkgs.playwright-driver.browsersJSON."chromium-headless-shell".revision;
  mermaidConfig = (pkgs.formats.json {}).generate "mermaid.json" {
    htmlLabels = false;
    flowchart.htmlLabels = false;
  };
  mermaidCli = pkgs.symlinkJoin {
    name = "mermaid-cli-${pkgs.mermaid-cli.version}";
    paths = [pkgs.mermaid-cli];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/mmdc" --add-flags "--configFile ${mermaidConfig}" --set-default PUPPETEER_EXECUTABLE_PATH \
        "${headlessShell}/chromium_headless_shell-${headlessShellRevision}/chrome-headless-shell-mac-arm64/chrome-headless-shell"
    '';
  };
in {
  home.packages = [mermaidCli] ++ lib.attrValues commands;

  # --- [M365_CLI]
  xdg.configFile."configstore/cli-m365-config.json".text = builtins.toJSON {
    autoOpenLinksInBrowser = false;
    copyDeviceCodeToClipboard = false;
    disableTelemetry = true;
    errorOutput = "stderr";
    output = "json";
    printErrorsAsPlainText = false;
    prompt = false;
    showHelpOnFailure = false;
  };
}
