{
  config,
  lib,
  pkgs,
  toolchainEnv,
  ...
}: let
  toolRows = (import ../../../../overlays/manifest.nix).extensions.npm-tools.rows;
  commands = lib.concatMapAttrs (package: row:
    lib.genAttrs row.commands (command:
      pkgs.writeShellScriptBin command ''
        ${lib.concatStrings (lib.mapAttrsToList (name: value: ''
            export ${name}="''${${name}-${value}}"
          '')
          ({inherit (toolchainEnv.sharedEnv) NPM_CONFIG_CACHE;} // row.env or {}))}PATH=${pkgs.nodejs_latest}/bin:$PATH exec npx --prefix=${pkgs.emptyDirectory} --yes --package=${lib.escapeShellArg "${package}@${row.version}"} ${command} "$@"
      ''))
  toolRows;
  chromiumMajor = lib.versions.major (lib.findFirst (browser: browser.name == "chromium") null toolRows.playwright.browsers).browserVersion;
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

  # --- [PLAYWRIGHT_CLI]
  home.file.".playwright/cli.config.json".text = builtins.toJSON {
    allowUnrestrictedFileAccess = true;
    background = true;
    browser = {
      browserName = "chromium";
      contextOptions = {
        bypassCSP = true;
        ignoreHTTPSErrors = true;
        permissions = [
          "accelerometer"
          "ambient-light-sensor"
          "background-sync"
          "camera"
          "clipboard-read"
          "clipboard-write"
          "geolocation"
          "gyroscope"
          "local-fonts"
          "local-network-access"
          "magnetometer"
          "microphone"
          "midi"
          "midi-sysex"
          "notifications"
          "payment-handler"
          "screen-wake-lock"
          "storage-access"
        ];
        userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${chromiumMajor}.0.0.0 Safari/537.36";
      };
    };
    console.level = "debug";
    filePaths = "absolute";
    outputDir = "${config.xdg.stateHome}/playwright/cli";
    outputMaxSize = 268435456;
    timeouts.idle = 3600000;
  };
  home.activation.installPlaywrightBrowsers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run --silence ${lib.getExe commands.playwright} install \
      || echo "playwright: browser builds of ${toolRows.playwright.version} are not installed (the download failed), the next switch retries" >&2
  '';

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
