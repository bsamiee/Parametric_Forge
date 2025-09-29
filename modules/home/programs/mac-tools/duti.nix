# Title         : duti.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/duti.nix
# ----------------------------------------------------------------------------
# macOS default application associations via UTIs

{ config, lib, pkgs, ... }:

let
  # File associations configuration - all inline
  dutiConfig = ''
    # PDF Documents -> Adobe Acrobat Pro
    com.adobe.Acrobat.Pro	com.adobe.pdf	all
    com.adobe.Acrobat.Pro	.pdf	all

    # URL Schemes -> Arc Browser (HTML associations need manual setup due to macOS restrictions)
    company.thebrowser.Browser	http	all
    company.thebrowser.Browser	https	all
    company.thebrowser.Browser	ftp	all

    # Development Files -> Visual Studio Code
    com.microsoft.VSCode	public.plain-text	all
    com.microsoft.VSCode	public.source-code	all
    com.microsoft.VSCode	.txt	all
    com.microsoft.VSCode	.md	all
    com.microsoft.VSCode	.json	all
    com.microsoft.VSCode	.yaml	all
    com.microsoft.VSCode	.yml	all
    com.microsoft.VSCode	.toml	all
    com.microsoft.VSCode	dev.nix.source	all
    com.microsoft.VSCode	.nix	all
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

    # Torrent Files -> Transmission
    org.m0k.transmission	org.bittorrent.torrent	all
    org.m0k.transmission	.torrent	all

    # STL Files -> Rhino
    com.mcneel.rhinoceros.8	public.standard-tesselated-geometry-format	all
    com.mcneel.rhinoceros.8	.stl	all

    # Image Files -> Preview
    com.apple.Preview	public.image	all
    com.apple.Preview	.jpg	all
    com.apple.Preview	.jpeg	all
    com.apple.Preview	.png	all
    com.apple.Preview	.gif	all
    com.apple.Preview	.webp	all

    # Email -> Superhuman
    com.superhuman.electron	mailto	all
  '';
in
{
  home.packages = [ pkgs.duti ];
  xdg.configFile."duti/settings".text = dutiConfig;

  # Apply on activation
  home.activation.setDefaultApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -f "$HOME/.config/duti/settings" ]]; then
      $DRY_RUN_CMD ${pkgs.duti}/bin/duti "$HOME/.config/duti/settings"
    fi
  '';
}
