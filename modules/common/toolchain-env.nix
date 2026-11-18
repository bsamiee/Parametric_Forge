{
  config,
  host,
  lib,
  pkgs,
  ...
}: {
  _module.args.toolchainEnv = let
    inherit (host.user) home;
    inherit (config.home-manager.users.${host.user.name}) xdg;
    userPathEntries = [
      "${home}/.local/bin"
      "/etc/profiles/per-user/${host.user.name}/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/opt/homebrew/bin"
    ];
    fallbackPathEntries = [
      "/usr/local/bin"
      "/System/Cryptexes/App/usr/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];
    pathEntries = userPathEntries ++ ["${xdg.dataHome}/mise/shims"] ++ fallbackPathEntries;
    runtimeEnv = lib.concatMapAttrs (_: package: package.runtimeEnvAt "/etc/profiles/per-user/${host.user.name}") {inherit (pkgs) energyplus openstudio;};
    designFontDirectory = "${home}/Library/Application Support/design-tools/fonts";
    fontDirectories = [
      "/System/Library/Fonts"
      "/Library/Fonts"
      "${home}/Library/Fonts"
      designFontDirectory
    ];
    editor = pkgs.writeShellScriptBin "code-wait" ''exec code --wait "$@"'';
    sftpRemotes = lib.concatMapAttrs (name: value: lib.genAttrs' host.tailnet.servers (remote: lib.nameValuePair "RCLONE_CONFIG_${lib.toUpper remote}_${name}" (value remote))) {
      TYPE = _: "sftp";
      SSH = remote: "ssh ${remote}";
      KNOWN_HOSTS_FILE = _: "none";
    };
    envByClass = {
      all =
        sftpRemotes
        // {
          # --- [LOCALE_XDG]
          LANG = "en_US.UTF-8";
          XDG_CONFIG_HOME = xdg.configHome;
          XDG_CACHE_HOME = xdg.cacheHome;
          XDG_DATA_HOME = xdg.dataHome;
          XDG_STATE_HOME = xdg.stateHome;

          # --- [EDITOR_PAGER]
          EDITOR = editor.name;
          VISUAL = editor.name;
          PAGER = "less";
          LESS = "-RFX";

          # --- [SERVICE_CLIENTS]
          GOG_KEYRING_BACKEND = "file";
          GAMCFGDIR = "${xdg.configHome}/gam";
          DOPPLER_ENABLE_VERSION_CHECK = "false";
          GH_NO_UPDATE_NOTIFIER = "1";
          GH_NO_EXTENSION_UPDATE_NOTIFIER = "1";
          HOMEBREW_NO_AUTO_UPDATE = "1";
          HOSTINGER_FORMAT = "json";
          HOSTINGER_NO_INPUT = "true";
          OFFICECLI_SKIP_UPDATE = "1";
          OFFICECLI_NO_AUTO_INSTALL = "1";
          CF_SEND_TELEMETRY = "false";
          CTX7_TELEMETRY_DISABLED = "1";
          NPM_CONFIG_CACHE = "${xdg.cacheHome}/npm";
          POWERSHELL_UPDATECHECK = "Off";
          POWERSHELL_TELEMETRY_OPTOUT = "1";
          CLIMICROSOFT365_NOUPDATE = "1";
          CODERABBIT_CLI_DISABLE_AUTO_UPDATE = "true";
          PDFM_MCP_TELEMETRY_DISABLED = "true";
          NOTEBOOKLM_MCP_ALLOWED_ROOTS = "/Users:/Volumes:/private";
          TLRC_CONFIG = "${xdg.configHome}/tlrc/config.toml";
          RCLONE_ASK_PASSWORD = "false";
          RCLONE_CACHE_DIR = "${xdg.cacheHome}/rclone";
          RCLONE_CONFIG_B2_TYPE = "b2";
          RCLONE_CONFIG_R2_TYPE = "s3";
          RCLONE_CONFIG_R2_PROVIDER = "Cloudflare";
          RCLONE_CONFIG_R2_REGION = "auto";
          TSCLI_OUTPUT = "json";
          PYMOBILEDEVICE3_NATIVE = "1";
          __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS = host.tailnet.node;

          # --- [SEARCH_DATA]
          RIPGREP_CONFIG_PATH = "${xdg.configHome}/ripgrep/config";
          DFT_UNSTABLE = "yes";
          DFT_DISPLAY = "inline";
          QSV_CACHE_DIR = "${xdg.cacheHome}/qsv";
          QSV_DOTENV_PATH = "<NONE>";
          QSV_ERROR_FORMAT = "json";
          PSQLRC = "${xdg.configHome}/psql/psqlrc";
          PSQL_HISTORY = "${xdg.stateHome}/psql/history";
          PGSERVICEFILE = "${xdg.configHome}/pg/pg_service.conf";
          PGPASSFILE = "${xdg.configHome}/pg/pgpass";

          # --- [FONTS_MEDIA]
          FONTCONFIG_FILE = "${xdg.configHome}/fontconfig/fonts.conf";
          TYPST_FONT_PATHS = designFontDirectory;
          TYPST_PACKAGE_PATH = "${xdg.dataHome}/typst/packages";
          TYPST_PACKAGE_CACHE_PATH = "${xdg.cacheHome}/typst/packages";
          VLC_FONT_DIR = designFontDirectory;
          VLC_MISSING_FONTS = "error";
          EXIFTOOL_HOME = "${xdg.configHome}/exiftool";
          CZKAWKA_CONFIG_PATH = "${xdg.configHome}/czkawka";
          CZKAWKA_CACHE_PATH = "${xdg.cacheHome}/czkawka";
          PDFCPU_CONFIG_ROOT = xdg.configHome;
          AB_AV1_TEMP_DIR = "${xdg.cacheHome}/ab-av1";
          PROJ_NETWORK = "ON";
          BLENDER_SYSTEM_SCRIPTS = "${xdg.dataHome}/blender/scripts";

          # --- [DIAGNOSTICS]
          RUST_BACKTRACE = "1";
          RUST_LIB_BACKTRACE = "0";
        };
      session = {
        BAT_PAGER = "less -RFXK";
        MANPAGER = "sh -c 'col -bx | bat -plman'";
        SQLITE_HISTORY = "${xdg.stateHome}/sqlite/history";
        NODE_REPL_HISTORY = "${xdg.stateHome}/node_repl_history";
        INFOPATH = "/opt/homebrew/share/info:";
      };
    };
  in {
    inherit
      editor
      designFontDirectory
      fontDirectories
      runtimeEnv
      pathEntries
      ;

    sharedEnv = runtimeEnv // envByClass.all;
    sessionEnv = envByClass.session;
  };
}
