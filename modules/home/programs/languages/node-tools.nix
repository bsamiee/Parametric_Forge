# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/node-tools.nix
# ----------------------------------------------------------------------------
# Node-hosted machine tool: mermaid-cli. The Node runtime, pnpm, and the TypeScript compiler are rows of each project's mise.toml and
# package.json, never a machine package.
{pkgs, ...}: let
  # nixpkgs pins mmdc's browser only where its chromium builds, never on darwin. The Nix chrome-headless-shell is a bare Mach-O that never
  # registers with LaunchServices, so a render failure never raises the macOS "quit unexpectedly" dialog; the full Chrome-for-Testing .app
  # aborts at _RegisterApplication when spawned headless from an agent shell.
  headlessShell = pkgs.playwright-driver.browsers.override {
    withChromium = false;
    withChromiumHeadlessShell = true;
    withFfmpeg = false;
    withFirefox = false;
    withWebkit = false;
  };
  headlessShellRevision = pkgs.playwright-driver.browsersJSON."chromium-headless-shell".revision;
  mermaidCli = pkgs.symlinkJoin {
    name = "mermaid-cli-${pkgs.mermaid-cli.version}";
    paths = [pkgs.mermaid-cli];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/mmdc" --set-default PUPPETEER_EXECUTABLE_PATH \
        "${headlessShell}/chromium_headless_shell-${headlessShellRevision}/chrome-headless-shell-mac-arm64/chrome-headless-shell"
    '';
  };
in {
  home.packages = [mermaidCli];
}
