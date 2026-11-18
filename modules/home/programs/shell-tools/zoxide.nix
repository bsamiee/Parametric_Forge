{config, ...}: {
  programs.zoxide = {
    enable = true;

    options = [
      "--cmd=cd"
    ];
  };

  home.sessionVariables = {
    _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
    _ZO_RESOLVE_SYMLINKS = "1";
    _ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}:/private/tmp:/private/tmp/*:/private/var/tmp/*:/private/var/folders/*:/usr/bin/*:/usr/sbin/*:/sbin/*:/bin/*";
  };
}
