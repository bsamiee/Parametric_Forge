{
  config,
  lib,
  pkgs,
  ...
}: let
  # --- [SCOPE] ---------------------------------------------------------------------------
  inherit (config.system) primaryUser;
  userHome = config.home-manager.users.${primaryUser};
  inherit (userHome.home) homeDirectory;
  exclusions =
    [userHome.xdg.cacheHome]
    ++ map (path: "${homeDirectory}/${path}") [
      "Library/Caches"
      "Library/Developer/Xcode/DerivedData"
      "Library/Logs"
    ];
  generatedDirectories = [
    ".artifacts"
    ".build"
    ".cache"
    ".direnv"
    ".gradle"
    ".next"
    ".nuxt"
    ".nx"
    ".parcel-cache"
    ".pixi"
    ".pytest_cache"
    ".ruff_cache"
    ".svelte-kit"
    ".terraform"
    ".tmp"
    ".venv"
    "__pycache__"
    "bin"
    "binaries"
    "build"
    "cache"
    "coverage"
    "deriveddata"
    "deriveddatacache"
    "dist"
    "intermediate"
    "node_modules"
    "obj"
    "out"
    "target"
  ];

  # --- [OPERATIONS] ----------------------------------------------------------------------
  reconcile = pkgs.writeText "spotlight-exclusions.js" ''
    ObjC.import('Foundation');
    ObjC.import('CoreServices');
    ObjC.bindFunction('_MDConfigCopyStoreAttributes', ['id', ['id']]);
    ObjC.bindFunction('_MDSetExclusion', ['int', ['id', 'int']]);
    ObjC.bindFunction('mkdir', ['int', ['string', 'unsigned short']]);
    ObjC.bindFunction('rmdir', ['int', ['string']]);
    ObjC.bindFunction('__error', ['int *', []]);
    ObjC.bindFunction('strerror', ['string', ['int']]);

    function indexing(enabled) {
      const volumes = enabled ? ['/', '/System/Volumes/Data'] : ['/System/Volumes/Data'];
      const task = $.NSTask.alloc.init;
      task.executableURL = $.NSURL.fileURLWithPath('/usr/bin/mdutil');
      task.arguments = $(['-i', enabled ? 'on' : 'off', ...volumes]);
      if (!task.launchAndReturnError(null)) throw new Error('Cannot launch /usr/bin/mdutil');
      task.waitUntilExit;
      if (task.terminationStatus !== 0) throw new Error('mdutil exit ' + task.terminationStatus);
      const expected = enabled ? 'kMDConfigSearchLevelReadWrite' : 'kMDConfigSearchLevelFSSearchOnly';
      for (const volume of volumes) {
        const attributes = ObjC.deepUnwrap($._MDConfigCopyStoreAttributes($(volume)));
        if (attributes.kMDConfigCurrentSearchLevel !== expected) {
          throw new Error(volume + ': expected ' + expected + ', received ' + attributes.kMDConfigCurrentSearchLevel);
        }
      }
    }

    function exclusion(path, excluded) {
      const directories = [];
      if (!excluded) {
        for (let parent = path; !$.NSFileManager.defaultManager.fileExistsAtPath(parent); parent = ObjC.unwrap($(parent).stringByDeletingLastPathComponent)) {
          directories.push(parent);
        }
      }
      const created = [];
      const errors = [];
      try {
        for (const directory of directories.reverse()) {
          if ($.mkdir(directory, 0o700) !== 0) throw new Error('mkdir ' + directory + ': ' + $.strerror($.__error()[0]));
          created.push(directory);
        }
        const status = $._MDSetExclusion($(path), Number(excluded));
        if (status !== 0) throw new Error('_MDSetExclusion ' + path + ': ' + status);
      } catch (error) {
        errors.push(error);
      }
      for (const directory of created.reverse()) {
        const status = $.rmdir(directory);
        if (status !== 0) errors.push(new Error('rmdir ' + directory + ': ' + $.strerror($.__error()[0])));
      }
      if (errors.length !== 0) throw new AggregateError(errors, errors.map(error => error.message).join('\n'));
    }

    function run([input, state, prepared, marker, volume]) {
      if (input === undefined) return indexing(true);
      const paths = ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(input, $.NSUTF8StringEncoding, null))
        .split('\0').filter(Boolean).map(path => path.replace(/\/+$/, ""));
      const declared = new Set(paths);
      const desired = new Set(paths.filter(path => {
        for (let index = path.lastIndexOf('/'); index > 0; index = path.lastIndexOf('/', index - 1)) {
          if (declared.has(path.slice(0, index))) return false;
        }
        return true;
      }));
      const previous = new Set($.NSFileManager.defaultManager.fileExistsAtPath(state)
        ? JSON.parse(ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(state, $.NSUTF8StringEncoding, null)))
        : ${builtins.toJSON (map (path: "${homeDirectory}/${path}") [
      "Developer"
      "Developer/Rasm/plan"
      "Library/Application Support"
      "Library/Developer/Xcode/DerivedData"
      "Library/Logs"
      "Library/WebKit"
    ])});
      const configuration = $.NSPropertyListSerialization.propertyListWithDataOptionsFormatError(
        $.NSData.dataWithContentsOfFile(volume), 0, null, null);
      if (configuration.isNil()) throw new Error('Cannot read Spotlight volume configuration ' + volume);
      const exclusions = configuration.objectForKey('Exclusions');
      const current = new Set(exclusions.isNil() ? [] : ObjC.deepUnwrap(exclusions));
      const owned = new Set([...desired].filter(path => previous.has(path) || !current.has(path)));
      const managed = new Set([...owned, ...previous]);
      const changes = [...managed].filter(path => owned.has(path) !== current.has(path));
      if (!$(JSON.stringify([...managed])).writeToFileAtomicallyEncodingError(state, true, $.NSUTF8StringEncoding, null)) {
        throw new Error('Cannot write pending Spotlight exclusions to ' + state);
      }
      if (changes.length !== 0) {
        if (!$('1').writeToFileAtomicallyEncodingError(marker, true, $.NSUTF8StringEncoding, null)) {
          throw new Error('Cannot record indexing restoration marker ' + marker);
        }
        indexing(false);
      } else {
        indexing(true);
      }
      for (const path of changes) exclusion(path, owned.has(path));
      if (!$(JSON.stringify([...owned])).writeToFileAtomicallyEncodingError(prepared, true, $.NSUTF8StringEncoding, null)) {
        throw new Error('Cannot write Spotlight exclusions to ' + prepared);
      }
      return JSON.stringify({desired: desired.size, managed: owned.size, changes: changes.length, retained: [...current].filter(path => !managed.has(path)).length});
    }
  '';
  command = pkgs.writeShellApplication {
    name = "spotlight-exclusions";
    runtimeInputs = [pkgs.coreutils pkgs.fd];
    text = ''
      shopt -s nullglob nocasematch
      stateDirectory=/var/db/parametric-forge
      mkdir -p "$stateDirectory"
      state="$stateDirectory/spotlight-exclusions.json"
      work=$(mktemp -d "$stateDirectory/spotlight.XXXXXX")
      finish() {
        local exitCode=$?
        if [[ -f "$work/indexing" ]]; then
          if /usr/bin/osascript -l JavaScript ${reconcile}; then
            :
          else
            local restoreCode=$?
            ((exitCode != 0)) || exitCode=$restoreCode
          fi
        fi
        if ((exitCode == 0)); then
          mv "$work/committed" "$state" || exitCode=$?
        fi
        rm -rf "$work"
        exit "$exitCode"
      }
      trap finish EXIT
      touch "$work/desired" "$work/repositories"
      for directory in ${lib.escapeShellArgs exclusions}; do
        [[ ! -d $directory ]] || printf '%s\0' "$directory" >> "$work/desired"
      done
      for directory in ${lib.escapeShellArg "${homeDirectory}/Developer"}/*/; do
        fd --hidden --no-ignore --prune --glob .git --type directory --type file --print0 \
          ${lib.concatMapStringsSep " " (name: "--exclude ${lib.escapeShellArg name}") generatedDirectories} \
          "$directory" >> "$work/repositories"
      done
      while IFS= read -r -d "" repository; do
        repository=''${repository%/}
        repository=''${repository%/.git}
        {
          /usr/bin/sudo -H -u ${lib.escapeShellArg primaryUser} ${pkgs.git}/bin/git -C "$repository" \
            ls-files --others --ignored --exclude-standard --directory -z
        } > "$work/ignored"
        while IFS= read -r -d "" relative; do
          directory=''${relative%/}
          [[ $directory != "$relative" ]] || continue
          case "''${directory##*/}" in
            ${lib.concatStringsSep "|" generatedDirectories}) printf '%s/%s\0' "$repository" "$directory" >> "$work/desired" ;;
          esac
        done < "$work/ignored"
      done < "$work/repositories"
      if [[ -d ${lib.escapeShellArg "${homeDirectory}/Library/Application Support"} ]]; then
        fd --hidden --no-ignore --type directory --prune --ignore-case --print0 \
          --exclude site-packages --exclude node_modules --exclude '*.app' --exclude '*.framework' --exclude '*.bundle' \
          '^(cache|caches|code cache|gpucache|dawncache|grshadercache|shadercache)$' \
          ${lib.escapeShellArg "${homeDirectory}/Library/Application Support"} >> "$work/desired"
      fi
      /usr/bin/mdutil -P /System/Volumes/Data > "$work/volume.plist"
      /usr/bin/osascript -l JavaScript ${reconcile} "$work/desired" "$state" "$work/committed" "$work/indexing" "$work/volume.plist"
    '';
  };
in {
  # --- [COMPOSITION] ---------------------------------------------------------------------
  system.activationScripts.postActivation.text = lib.getExe command;
}
