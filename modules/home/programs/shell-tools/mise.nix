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
        use_versions_host_track = false;
        jobs = 16;
        dotnet.dotnet_root = dotnetRoot;
      };
      env = {
        PLAYWRIGHT_CLI_SESSION = "{{ env.CLAUDE_CODE_SESSION_ID | default(value=env.CODEX_THREAD_ID | default(value=env.ANTIGRAVITY_CONVERSATION_ID | default(value=''))) }}";
        PLAYWRIGHT_MCP_OUTPUT_DIR = "${config.xdg.stateHome}/playwright";
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
