{
  config,
  pkgs,
  ...
}: let
  dotnetRoot = "${config.xdg.dataHome}/mise/dotnet-root";
in {
  programs.mise = {
    enable = true;
    package = pkgs.mise-current;
    enableZshIntegration = false;
    globalConfig = {
      settings = {
        experimental = true;
        trusted_config_paths = ["~/Developer"];
        shims.fallback_to_installed = true;
        ignored_config_paths = ["/private/tmp" "/private/var/folders"];
        disable_hints = ["*"];
        disable_update_warning = true;
        dotnet.dotnet_root = dotnetRoot;
      };
      hooks.preinstall = ''
        if [ -f "${dotnetRoot}/dotnet" ]; then
          cp -p "${dotnetRoot}/dotnet" "${dotnetRoot}/dotnet.next"
          mv -f "${dotnetRoot}/dotnet.next" "${dotnetRoot}/dotnet"
        fi
      '';
    };
  };
}
