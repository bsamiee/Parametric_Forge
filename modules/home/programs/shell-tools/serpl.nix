{pkgs, ...}: let
  tomlFormat = pkgs.formats.toml {};
in {
  home.packages = [pkgs.serpl];
  xdg.configFile."serpl/config.toml".source = tomlFormat.generate "serpl-config" {
    keybindings = {
      "<Ctrl-q>" = "Quit";
      "<Ctrl-h>" = "ShowHelp";
    };
  };
}
