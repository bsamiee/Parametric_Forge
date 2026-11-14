{
  host,
  lib,
  pkgs,
  ...
}: {
  _module.args.toolchainEnvFor = {
    home,
    username,
    xdgCacheHome,
    xdgConfigHome ? "${home}/.config",
    xdgDataHome ? "${home}/.local/share",
    xdgStateHome ? "${home}/.local/state",
  }: let
    rhinoBin = "${xdgDataHome}/rhino/bin";
    userPathEntries = [
      "${home}/.local/bin"
      "/etc/profiles/per-user/${username}/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/opt/homebrew/bin"
      rhinoBin
    ];
    fallbackPathEntries = [
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];
    shimPath = "${xdgDataHome}/mise/shims";
    pathEntries = userPathEntries ++ [shimPath] ++ fallbackPathEntries;
    runtimeEnv = lib.concatMapAttrs (_: package: package.runtimeEnvAt "/etc/profiles/per-user/${username}") {inherit (pkgs) energyplus openstudio;};
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
          # --- [EDITOR_PAGER]
          EDITOR = editor.name;
          VISUAL = editor.name;
          PAGER = "less";
          LESS = "-RFX";

          # --- [SERVICE_CLIENTS]
          GOG_KEYRING_BACKEND = "file";
          GAMCFGDIR = "${xdgConfigHome}/gam";
          CUA_DRIVER_RS_HOME = "${xdgDataHome}/cua-driver";
          DOPPLER_CONFIG_DIR = "${xdgConfigHome}/doppler";
          DOPPLER_ENABLE_VERSION_CHECK = "false";
          GH_NO_UPDATE_NOTIFIER = "1";
          GH_NO_EXTENSION_UPDATE_NOTIFIER = "1";
          HOSTINGER_FORMAT = "json";
          HOSTINGER_NO_INPUT = "true";
          OFFICECLI_SKIP_UPDATE = "1";
          POWERSHELL_UPDATECHECK = "Off";
          POWERSHELL_TELEMETRY_OPTOUT = "1";
          CLIMICROSOFT365_NOUPDATE = "1";
          CODERABBIT_CLI_DISABLE_AUTO_UPDATE = "true";
          NOTEBOOKLM_MCP_ALLOWED_ROOTS = "/Users:/Volumes:/private";
          TLRC_CONFIG = "${xdgConfigHome}/tlrc/config.toml";
          RCLONE_ASK_PASSWORD = "false";
          RCLONE_CACHE_DIR = "${xdgCacheHome}/rclone";
          RCLONE_CONFIG_B2_TYPE = "b2";
          RCLONE_CONFIG_R2_TYPE = "s3";
          RCLONE_CONFIG_R2_PROVIDER = "Cloudflare";
          RCLONE_CONFIG_R2_REGION = "auto";
          TSCLI_OUTPUT = "json";
          __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS = host.tailnet.node;

          # --- [SEARCH_DATA]
          RIPGREP_CONFIG_PATH = "${xdgConfigHome}/ripgrep/config";
          DFT_UNSTABLE = "yes";
          DFT_DISPLAY = "inline";
          QSV_CACHE_DIR = "${xdgCacheHome}/qsv";
          QSV_DOTENV_PATH = "<NONE>";
          QSV_ERROR_FORMAT = "json";
          PSQLRC = "${xdgConfigHome}/psql/psqlrc";
          PSQL_HISTORY = "${xdgStateHome}/psql/history";
          PGSERVICEFILE = "${xdgConfigHome}/pg/pg_service.conf";
          PGPASSFILE = "${xdgConfigHome}/pg/pgpass";
          PYTHONPYCACHEPREFIX = "${xdgCacheHome}/pycache";

          # --- [FONTS_MEDIA]
          FONTCONFIG_FILE = "${xdgConfigHome}/fontconfig/fonts.conf";
          TYPST_FONT_PATHS = designFontDirectory;
          TYPST_PACKAGE_PATH = "${xdgDataHome}/typst/packages";
          TYPST_PACKAGE_CACHE_PATH = "${xdgCacheHome}/typst/packages";
          VLC_FONT_DIR = designFontDirectory;
          VLC_MISSING_FONTS = "error";
          EXIFTOOL_HOME = "${xdgConfigHome}/exiftool";
          CZKAWKA_CONFIG_PATH = "${xdgConfigHome}/czkawka";
          CZKAWKA_CACHE_PATH = "${xdgCacheHome}/czkawka";
          PDFCPU_CONFIG_ROOT = xdgConfigHome;
          AB_AV1_TEMP_DIR = "${xdgCacheHome}/ab-av1";
          PROJ_NETWORK = "ON";
        };
      session = {
        BAT_PAGER = "less -RFXK";
        MANPAGER = "sh -c 'col -bx | bat -plman'";
        SQLITE_HISTORY = "${xdgStateHome}/sqlite/history";
        NODE_REPL_HISTORY = "${xdgStateHome}/node_repl_history";
        INFOPATH = "/opt/homebrew/share/info:";
      };
    };
  in {
    inherit
      editor
      designFontDirectory
      fontDirectories
      rhinoBin
      runtimeEnv
      ;

    inherit pathEntries shimPath;
    sharedEnv = runtimeEnv // envByClass.all;
    sessionEnv = envByClass.session;
  };
}
