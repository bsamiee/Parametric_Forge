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
  volume = "/System/Volumes/Data";
  exclusions =
    [userHome.xdg.cacheHome]
    ++ map (path: "${homeDirectory}/${path}") [
      "Library/Caches"
      "Library/Logs"
      "Library/Developer/Xcode/DerivedData"
      "Library/Application Support/Code/CachedData"
      "Library/Application Support/Epic/UnrealEngine/Common/Zen"
      "Library/Application Support/Firefox/Profiles"
      "Library/Application Support/Spotify/PersistentCache"
      "Library/Application Support/Superhuman/Cache"
      "Library/Application Support/Superhuman/Code Cache"
      "Library/Application Support/Superhuman/Service Worker"
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
    ObjC.bindFunction('_MDSetExclusion', ['int', ['id', 'int']]);
    ObjC.bindFunction('mkdir', ['int', ['string', 'unsigned short']]);
    ObjC.bindFunction('rmdir', ['int', ['string']]);

    const read = file => ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(file, $.NSUTF8StringEncoding, null));
    const write = (file, rows) => $(JSON.stringify(rows)).writeToFileAtomicallyEncodingError(file, true, $.NSUTF8StringEncoding, null);

    function exclusion(path, excluded) {
      const missing = [];
      if (!excluded) {
        for (let parent = path; !$.NSFileManager.defaultManager.fileExistsAtPath(parent); parent = ObjC.unwrap($(parent).stringByDeletingLastPathComponent)) {
          missing.unshift(parent);
        }
      }
      const created = missing.filter(directory => $.mkdir(directory, 0o700) === 0);
      const status = created.length === missing.length ? $._MDSetExclusion($(path), Number(excluded)) : 'mkdir';
      created.reverse().forEach(directory => $.rmdir(directory));
      return status;
    }

    function run([input, state, prepared, configurationFile, volume]) {
      const paths = read(input).split('\0').filter(Boolean).map(path => path.replace(/\/+$/, ""));
      const queued = path => Number($(volume + path).lengthOfBytesUsingEncoding($.NSUTF8StringEncoding)) + 1;
      const queueable = path => queued(path) <= 0x400 && (queued(path) & 0x80) === 0;
      const declared = new Set(paths);
      const settable = new Set(paths.filter(queueable));
      const covered = path => {
        for (let index = path.lastIndexOf('/'); index > 0; index = path.lastIndexOf('/', index - 1)) {
          if (settable.has(path.slice(0, index))) return true;
        }
        return false;
      };
      const desired = [...settable].filter(path => !covered(path));
      const previous = new Set($.NSFileManager.defaultManager.fileExistsAtPath(state) ? JSON.parse(read(state)) : []);
      const configuration = $.NSPropertyListSerialization.propertyListWithDataOptionsFormatError(
        $.NSData.dataWithContentsOfFile(configurationFile), 0, null, null);
      if (configuration.isNil()) throw new Error('Cannot read Spotlight volume configuration ' + configurationFile);
      const rows = configuration.objectForKey('Exclusions');
      const current = new Set(rows.isNil() ? [] : ObjC.deepUnwrap(rows).map(row => row.normalize()));
      const stored = path => current.has(path.normalize());
      const owned = new Set(desired.filter(path => previous.has(path) || !stored(path)));
      const managed = new Set([...owned, ...previous]);
      const changes = [...managed].filter(path => queueable(path) && owned.has(path) !== stored(path));
      if (!write(state, [...managed])) throw new Error('Cannot write pending Spotlight exclusions to ' + state);
      const failed = new Map(changes.map(path => [path, exclusion(path, owned.has(path))]).filter(([, status]) => status !== 0));
      if (!write(prepared, [...managed].filter(path => owned.has(path) !== failed.has(path)))) {
        throw new Error('Cannot write Spotlight exclusions to ' + prepared);
      }
      return JSON.stringify({
        desired: desired.length,
        managed: owned.size,
        changes: changes.length,
        retained: current.size - [...managed].filter(stored).length,
        unsettable: [...declared].filter(path => !settable.has(path) && !covered(path)),
        failed: Object.fromEntries(failed),
      });
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
      /usr/bin/mdutil -P ${volume} > "$work/volume.plist"
      /usr/bin/osascript -l JavaScript ${reconcile} "$work/desired" "$state" "$work/committed" "$work/volume.plist" ${volume}
    '';
  };
in {
  # --- [COMPOSITION] ---------------------------------------------------------------------
  system.activationScripts.postActivation.text = ''
    ${lib.getExe command} || printf 'spotlight-exclusions: exit %s\n' "$?" >&2
  '';
}
