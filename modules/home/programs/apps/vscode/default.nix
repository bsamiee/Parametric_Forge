{
  applications,
  lib,
  ...
}: let
  code = lib.escapeShellArg "${applications.vscode.path}/Contents/Resources/app/bin/code";
in {
  home.activation.installVSCodeExtensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -x ${code} ]]; then
      installed="$(${code} --list-extensions)"
      for extension in adobe.extendscript-debug jaroslavbereza.uxpdebugger jaroslavbereza.uxpvalidator; do
        /usr/bin/grep -qixF "$extension" <<<"$installed" || run ${code} --install-extension "$extension"
      done
    fi
  '';
}
