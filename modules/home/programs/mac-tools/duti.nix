# Title         : duti.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/duti.nix
# ----------------------------------------------------------------------------
# macOS default application associations via UTIs
{
  config,
  lib,
  pkgs,
  ...
}: let
  dutiConfig = ''
    # PDF Documents -> Adobe Acrobat Pro
    com.adobe.Acrobat.Pro	com.adobe.pdf	all
    com.adobe.Acrobat.Pro	.pdf	all

    # URL schemes -> Arc. A two-field row is duti's scheme grammar (LSSetDefaultHandlerForURLScheme); a role turns the scheme into a filename
    # extension, which resolves to a dynamic UTI Launch Services refuses (-50). The http row is the default-browser role — macOS carries https
    # and HTML with it and refuses a direct https write (-54) — and a browser change still routes through the system's consent dialog.
    company.thebrowser.Browser	http
    company.thebrowser.Browser	ftp

    # Development files -> Visual Studio Code. Every extension row must resolve to a declared UTI: an undeclared one (toml, nix) mints a dynamic
    # UTI Launch Services refuses (-50), so nix rides its declared UTI and toml rides VSCode's own Info.plist claim.
    com.microsoft.VSCode	public.plain-text	all
    com.microsoft.VSCode	public.source-code	all
    com.microsoft.VSCode	.txt	all
    com.microsoft.VSCode	.md	all
    com.microsoft.VSCode	.json	all
    com.microsoft.VSCode	.yaml	all
    com.microsoft.VSCode	.yml	all
    com.microsoft.VSCode	dev.nix.source	all
    com.microsoft.VSCode	.lua	all
    com.microsoft.VSCode	.py	all
    com.microsoft.VSCode	.js	all
    com.microsoft.VSCode	.ts	all
    com.microsoft.VSCode	.rs	all
    com.microsoft.VSCode	.sh	all
    com.microsoft.VSCode	org.n8gray.structured-query-language-source	all
    com.microsoft.VSCode	.sql	all
    com.microsoft.VSCode	public.comma-separated-values-text	all
    com.microsoft.VSCode	.csv	all
    com.microsoft.VSCode	com.apple.log	all
    com.microsoft.VSCode	.log	all

    # STL Files -> Rhino 9 BETA
    com.mcneel.rhinoceros.9	public.standard-tesselated-geometry-format	all
    com.mcneel.rhinoceros.9	.stl	all

    # Image Files -> Preview
    com.apple.Preview	public.image	all
    com.apple.Preview	.jpg	all
    com.apple.Preview	.jpeg	all
    com.apple.Preview	.png	all
    com.apple.Preview	.gif	all
    com.apple.Preview	.webp	all

    # Email -> Superhuman
    com.superhuman.electron	mailto
  '';
in {
  home.packages = [pkgs.duti];
  xdg.configFile."duti/settings".text = dutiConfig;

  # Apply on activation; the settings path derives from the XDG owner above.
  home.activation.setDefaultApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.duti}/bin/duti ${lib.escapeShellArg "${config.xdg.configHome}/duti/settings"}
  '';
}
