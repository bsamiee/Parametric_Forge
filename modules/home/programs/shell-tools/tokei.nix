# Title         : tokei.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/tokei.nix
# ----------------------------------------------------------------------------
# Fast code statistics tool

{ config, lib, pkgs, ... }:

let
  tokeiConfig = {
    sort = "code";
    treat_doc_strings_as_comments = true;
  };
in
{
  home.packages = [ pkgs.tokei ];
  xdg.configFile."tokei.toml".source = (pkgs.formats.toml {}).generate "tokei-config" tokeiConfig;
}
