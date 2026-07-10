# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/vscode/default.nix
# ----------------------------------------------------------------------------
# VS Code owner: appearance.nix projects the theme+font owners into asserted
# design scalars and structured appearance rows; this file owns the behavior
# law — editing rules, the universal rows promoted from the estate workspace
# files (language blocks merge per-key across scopes, so workspace intent
# composes on top), tool bindings on the Home Manager profile — plus the
# sentinel-managed publish rails (settings AND keybindings) and the
# manifest-rostered extension surface. The keybindings rail renders the
# chord owner's vscode rows into a forge-keys tail block: user rules
# evaluate bottom-to-top, so the managed tail is the authority position and
# hand experiments above it coexist. Both rails target the Default profile;
# a custom full profile reads profiles/<id>/ and never sees these blocks.
{
  config,
  lib,
  pkgs,
  ...
}: let
  style = import ../../../../style.nix;
  manifest = import ../../../../../overlays/manifest.nix;
  appearance = import ./appearance.nix {
    inherit lib;
    t = config.forge.theme;
    f = config.forge.fonts;
  };
  ext = import ./extensions.nix {
    inherit lib pkgs;
    inherit (manifest.extensions.vscode) rows;
  };
  profileBin = "${config.home.profileDirectory}/bin";
  venv = "\${workspaceFolder}/.venv/bin";
  vscodeBinds = config.forge.chords.vscode.binds;

  # Asserted rows own their key estate-wide: user-region copies are stripped so
  # they cannot shadow the owners. Values must stay scalar — the strip regex
  # removes single lines only, and an attrs/list row would orphan its body.
  asserted =
    lib.mapAttrs (
      k: v:
        lib.throwIf (builtins.isAttrs v || builtins.isList v)
        "vscode asserted row ${k} must be scalar; land structured rows in the shadowable set"
        v
    )
    appearance.asserted;

  settingsBase =
    asserted
    // appearance.settings
    // {
      # --- [EDITING_LAW]: house style projected from modules/style.nix
      "editor.tabSize" = style.indent;
      "editor.insertSpaces" = true;
      "editor.rulers" = [style.width];
      "editor.detectIndentation" = false;
      "files.insertFinalNewline" = true;
      "files.trimTrailingWhitespace" = true;
      "editor.linkedEditing" = true;
      "editor.inlayHints.enabled" = "offUnlessPressed";
      "editor.inlayHints.padding" = true;
      "editor.semanticHighlighting.enabled" = true;
      "editor.suggest.insertMode" = "replace";
      "editor.suggestSelection" = "recentlyUsedByPrefix";
      "editor.acceptSuggestionOnEnter" = "smart";
      # Deterministic suggest posture: the app default mutates when an inline
      # suggestion provider is present.
      "editor.quickSuggestions" = {
        other = "on";
        comments = "off";
        strings = "on";
      };

      # --- [FILES_AND_EXPLORER]
      "files.hotExit" = "onExitAndWindowClose";
      "explorer.incrementalNaming" = "smart";
      "files.associations" = {
        "**/.claude/**/*.md" = "markdown";
        "**/docs/**/*.md" = "markdown";
      };
      "explorer.fileNesting.enabled" = true;
      "explorer.fileNesting.expand" = false;
      # The flake row nests every root manifest a flake-rooted repo carries;
      # it is inert where no flake.nix exists, so non-flake repos fall to the
      # per-manifest rows below. Structured values replace across scopes —
      # base is the single definer, workspace files never restate this key.
      "explorer.fileNesting.patterns" = {
        "flake.nix" = "flake.lock, pyproject.toml, uv.lock, biome.json, package.json, pnpm-lock.yaml, pnpm-workspace.yaml, tsconfig.json";
        "pyproject.toml" = "uv.lock";
        "package.json" = "pnpm-lock.yaml, pnpm-workspace.yaml";
        "README.md" = "LICENSE";
        "CLAUDE.md" = "AGENTS.md, .coderabbit.yaml";
        ".gitignore" = ".gitattributes, .mailmap, .dockerignore";
        "*.ts" = "$(capture).test.ts, $(capture).spec.ts, $(capture).d.ts";
      };
      "files.exclude" = {
        "**/.cache" = true;
        "**/.direnv" = true;
        "**/.venv" = true;
        "**/__pycache__" = true;
        "**/node_modules" = true;
        "result" = true;
        "result-*" = true;
      };
      "files.watcherExclude" = {
        "**/.archive/**" = true;
        "**/.cache/**" = true;
        "**/.direnv/**" = true;
        "**/.venv/**" = true;
        "**/__pycache__/**" = true;
        "result/**" = true;
      };
      "files.readonlyInclude" = {
        "**/flake.lock" = true;
        "**/pnpm-lock.yaml" = true;
        "**/uv.lock" = true;
        "**/node_modules/**" = true;
      };
      "search.exclude" = {
        "**/.archive/**" = true;
        "**/.cache/**" = true;
        "**/.venv/**" = true;
        "**/flake.lock" = true;
        "**/pnpm-lock.yaml" = true;
        "**/uv.lock" = true;
      };
      "search.smartCase" = true;
      "search.followSymlinks" = false;
      "search.useGlobalIgnoreFiles" = true;

      # --- [GIT_DIFF_TESTING]
      "git.autofetch" = true;
      "git.pruneOnFetch" = true;
      "git.branchProtection" = ["main"];
      "git.mergeEditor" = true;
      "diffEditor.ignoreTrimWhitespace" = false;
      "diffEditor.hideUnchangedRegions.enabled" = true;
      "testing.automaticallyOpenPeekView" = "failureAnywhere";
      "testing.automaticallyOpenTestResults" = "openOnTestFailure";
      "workbench.editor.highlightModifiedTabs" = true;
      "workbench.editor.pinnedTabSizing" = "compact";
      # Keyboard shortcuts sync per platform: the forge-keys tail is mac law
      # and must never ride to or from another platform's shortcut file.
      "settingsSync.keybindingsPerPlatform" = true;

      # --- [SCHEMA_BINDING]: projected forge schemas validate estate file shapes
      "json.schemas" = map (name: {
        fileMatch = ["**/.greptile/${name}.json"];
        url = "file://${config.xdg.configHome}/forge/schemas/greptile-${name}.schema.json";
      }) ["config" "files"];
      "yaml.schemas" = {
        "https://storage.googleapis.com/coderabbit_public_assets/schema.v2.json" = ".coderabbit.yaml";
      };

      # --- [LANGUAGE_BLOCKS]: per-key merge law — a workspace block overrides
      # only the keys it names, so these compose under every repo's intent.
      # [yaml] binds the yamlfmt extension (spawns PATH yamlfmt, cwd = workspace,
      # so project .yamlfmt wins before the XDG global); [nix] stays on
      # alejandra's 2-space so owners never fight.
      "[yaml]" = {
        "editor.defaultFormatter" = "bluebrown.yamlfmt";
        "editor.tabSize" = style.indent;
        "editor.insertSpaces" = true;
        "editor.detectIndentation" = false;
      };
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
        "editor.tabSize" = 2;
        "editor.detectIndentation" = false;
      };
      "[python]"."editor.defaultFormatter" = "charliermarsh.ruff";
      "[shellscript]"."editor.defaultFormatter" = "mkhl.shfmt";
      "[csharp]"."editor.defaultFormatter" = "ms-dotnettools.csharp";
      "[markdown]" = {
        "editor.defaultFormatter" = "yzhang.markdown-all-in-one";
        "editor.wordWrap" = "on";
        "editor.rulers" = [];
      };
      "[typescript][typescriptreact][javascript][javascriptreact][json][jsonc][css]"."editor.defaultFormatter" = "biomejs.biome";

      # --- [TOOL_BINDINGS]: Home Manager profile binaries, never bare names
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${profileBin}/nixd";
      "nix.formatterPath" = "${profileBin}/alejandra";
      "nix.serverSettings".nixd.formatting.command = ["${profileBin}/alejandra"];
      "biome.lsp.bin" = "${profileBin}/biome";
      "shfmt.executablePath" = "${profileBin}/shfmt";
      "todo-tree.ripgrep.ripgrep" = "${profileBin}/rg"; # the extension ships no arm64 vscode-ripgrep; bind the estate binary
      "biome.requireConfiguration" = true;
      "biome.suggestInstallingGlobally" = false;
      # prettier.* rows are the esbenp extension's no-config fallback, mirroring
      # the XDG prettierrc so the extension lane matches the CLI wrapper.
      "prettier.tabWidth" = style.indent;
      "prettier.printWidth" = style.width;
      "redhat.telemetry.enabled" = false;

      # --- [TYPESCRIPT]
      "js/ts.tsdk.path" = "./node_modules/typescript/lib";
      "js/ts.tsdk.promptToUseWorkspaceVersion" = true;
      "js/ts.preferences.quoteStyle" = "single";
      "js/ts.preferences.importModuleSpecifierEnding" = "minimal";
      "js/ts.preferences.preferTypeOnlyAutoImports" = true;
      "js/ts.suggest.completeFunctionCalls" = true;
      "js/ts.updateImportsOnFileMove.enabled" = "always";
      "js/ts.inlayHints.parameterNames.enabled" = "literals";
      "js/ts.inlayHints.parameterTypes.enabled" = true;
      "js/ts.inlayHints.functionLikeReturnTypes.enabled" = true;
      "js/ts.inlayHints.variableTypes.enabled" = true;
      "js/ts.inlayHints.enumMemberValues.enabled" = true;

      # --- [PYTHON]: project venv first; the language server lane is ty+ruff
      "python.defaultInterpreterPath" = "${venv}/python";
      "python.languageServer" = "None";
      "python.createEnvironment.trigger" = "off";
      "python.testing.pytestEnabled" = true;
      "python.testing.pytestArgs" = ["tests"];
      "python.testing.promptToConfigure" = false;
      "python.testing.unittestEnabled" = false;
      "ruff.nativeServer" = "on";
      "ruff.configurationPreference" = "filesystemFirst";
      "ruff.importStrategy" = "fromEnvironment";
      "ruff.showSyntaxErrors" = false;
      "ruff.interpreter" = ["${venv}/python"];
      "ty.diagnosticMode" = "workspace";
      "ty.showSyntaxErrors" = true;
      "ty.path" = ["${venv}/ty"];
      "ty.completions.autoImport" = true;
      "mypy-type-checker.cwd" = "\${workspaceFolder}";
      "mypy-type-checker.importStrategy" = "fromEnvironment";
      "mypy-type-checker.interpreter" = ["${venv}/python"];
      "mypy-type-checker.reportingScope" = "file";
      "mypy-type-checker.preferDaemon" = false;

      # --- [DOTNET]
      # Workspace-development posture promoted from the estate C# repos:
      # identical toolchain law for any slnx workspace; solution identity
      # (defaultSolution, solution.autoOpen) stays per-repo.
      "dotnet.preferCSharpExtension" = false;
      "dotnet.server.useOmnisharp" = false;
      "dotnet.enableXamlTools" = false;
      "dotnet.autoDetect" = "on";
      "dotnet.preferVisualStudioCodeFileSystemWatcher" = true;
      "dotnet.automaticallySyncWithActiveItem" = true;
      "dotnet.automaticallyCreateSolutionInWorkspace" = false;
      "dotnet.enableWorkspaceBasedDevelopment" = true;
      "dotnet.useLegacyDotnetResolution" = false;
      "dotnet.backgroundAnalysis.analyzerDiagnosticsScope" = "fullSolution";
      "dotnet.backgroundAnalysis.compilerDiagnosticsScope" = "fullSolution";
      "dotnet.projects.enableAutomaticRestore" = true;
      "dotnet.formatting.organizeImportsOnFormat" = true;
      "dotnet.inlayHints.enableInlayHintsForParameters" = true;
      "dotnet.inlayHints.enableInlayHintsForLiteralParameters" = true;
      "dotnet.inlayHints.enableInlayHintsForIndexerParameters" = true;
      "dotnet.inlayHints.enableInlayHintsForObjectCreationParameters" = true;
      "dotnet.inlayHints.enableInlayHintsForOtherParameters" = true;
      "dotnet.inlayHints.suppressInlayHintsForParametersThatMatchArgumentName" = true;
      "dotnet.inlayHints.suppressInlayHintsForParametersThatMatchMethodIntent" = true;
      "dotnet.inlayHints.suppressInlayHintsForParametersThatDifferOnlyBySuffix" = true;
      "csharp.inlayHints.enableInlayHintsForTypes" = true;
      "csharp.inlayHints.enableInlayHintsForImplicitVariableTypes" = true;
      "csharp.inlayHints.enableInlayHintsForLambdaParameterTypes" = true;
      "csharp.inlayHints.enableInlayHintsForImplicitObjectCreation" = true;
      "csharp.suppressHiddenDiagnostics" = false;
    };

  # Settings Sync is live on this machine and reconciles per-key: a pull can
  # re-inject a managed key BELOW the sentinel block, where JSONC last-wins
  # would shadow the owner. Every owned key is sync-ignored, and the list
  # ignores itself so a remote copy never round-trips an older list.
  forgeSettings =
    settingsBase
    // {
      "settingsSync.ignoredSettings" = builtins.attrNames settingsBase ++ ["settingsSync.ignoredSettings"];
    };

  # Strip set: every scalar owned key — asserted design law plus scalar
  # behavior rows — so a stale user-region copy below the block can never
  # shadow its owner under JSONC last-wins. Structured rows (attrs/lists)
  # stay shadow-tolerated because a single-line strip cannot remove a spread
  # body. The sync ignore list joins explicitly (list-valued but one-line by
  # owner render, and a shadowed copy would disarm the sync defense for every
  # managed key); tombstones strip retired keys back to app defaults (the
  # experimental renderer and retired EditContext spelling).
  managedKeys =
    builtins.attrNames (lib.filterAttrs (_: v: !(builtins.isAttrs v || builtins.isList v)) settingsBase)
    ++ [
      "settingsSync.ignoredSettings"
      "editor.letterSpacing"
      "terminal.integrated.letterSpacing"
      "editor.experimentalEditContextEnabled"
      "editor.experimentalGpuAcceleration"
    ];
  # Key alternation crosses into awk as a dynamic regex through ENVIRON — never
  # a /literal/ — so key spellings can never collide with the awk delimiter.
  managedKeyAlt =
    lib.throwIf (managedKeys == []) "vscode managed strip set is empty"
    (lib.concatMapStringsSep "|" lib.escapeRegex managedKeys);
  managedKeyRegex = "^[[:space:]]*\"(${managedKeyAlt})\"[[:space:]]*:";

  # JSONC block asserted after the root brace; sentinels make replacement
  # idempotent and user keys outside the managed set stay untouched.
  forgeBlock = lib.concatStrings [
    "  // forge-theme:begin generated from modules/home/{theme,fonts}.nix; reasserted on switch\n"
    (lib.concatStrings (lib.mapAttrsToList (k: v: "  ${builtins.toJSON k}: ${builtins.toJSON v},\n") forgeSettings))
    "  // forge-theme:end"
  ];
  settingsPath = "${config.home.homeDirectory}/Library/Application Support/Code/User/settings.json";

  # Keybindings tail block: chord-owner vscode rows as one-line JSONC array
  # elements (no inner bracket lines, so the merge's tail scan stays exact).
  # Keyboard shortcuts sync as their own whole-file resource with no key-level
  # ignore mechanism; the switch reasserts the tail and doctor proves it, so
  # a sync clobber is self-healing, never silent.
  forgeKeysBlock = lib.concatStrings [
    "  // forge-keys:begin generated from modules/home/programs/apps/chords.nix; reasserted on switch\n"
    (lib.concatMapStrings (row: "  ${builtins.toJSON row},\n") vscodeBinds)
    "  // forge-keys:end"
  ];
  keybindingsPath = "${config.home.homeDirectory}/Library/Application Support/Code/User/keybindings.json";
in {
  imports = [../chords.nix];

  # Project-agnostic projection artifacts; sibling repos consume these instead
  # of carrying color copies in workspace settings.
  xdg.configFile = {
    "forge/theme/vscode.json".text = builtins.toJSON forgeSettings;
    "forge/theme/vscode-settings-block.jsonc".text = forgeBlock;
    "forge/vscode/roster.json".text = ext.rosterJson;
    "forge/vscode/keybindings-block.jsonc".text = forgeKeysBlock;
    "forge/schemas/greptile-config.schema.json".source = ./schemas/greptile-config.schema.json;
    "forge/schemas/greptile-files.schema.json".source = ./schemas/greptile-files.schema.json;
  };

  home = {
    packages = [ext.package];

    activation.vscodeThemeSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
        settings=${lib.escapeShellArg settingsPath}
      FORGE_BLOCK=$(<${config.xdg.configFile."forge/theme/vscode-settings-block.jsonc".source})
      FORGE_MANAGED_RE=${lib.escapeShellArg managedKeyRegex}
      FORGE_MANAGED_RE_ANY=${lib.escapeShellArg "\"(${managedKeyAlt})\"[[:space:]]*:"}
      export FORGE_BLOCK FORGE_MANAGED_RE FORGE_MANAGED_RE_ANY
      if [ -s "$settings" ]; then
        # Fail-closed guards: a begin sentinel without its end (torn prior write)
        # would strip every remaining user key, and a managed key sharing the
        # root-brace line (hand-minified file) would shadow the owners under
        # JSONC last-wins; both refuse instead of merging.
        merged=$(/usr/bin/awk '
          /\/\/ forge-theme:begin/ { skip = 1; next }
          /\/\/ forge-theme:end/   { skip = 0; next }
          skip { next }
          !inserted && match($0, /^[[:space:]]*\{/) {
            rest = substr($0, RLENGTH + 1)
            if (rest ~ ENVIRON["FORGE_MANAGED_RE_ANY"]) exit 66
            print substr($0, 1, RLENGTH)
            print ENVIRON["FORGE_BLOCK"]
            if (rest != "") print rest
            inserted = 1
            next
          }
          inserted && $0 ~ ENVIRON["FORGE_MANAGED_RE"] {
            # A managed line whose value continues past the line (open bracket
            # or brace, or a bare colon with the scalar on the next line) would
            # orphan its body under a single-line strip, and a second key
            # sharing the managed line would vanish with it; all refuse
            # instead of tearing the document.
            if (gsub(/\[/, "[") > gsub(/\]/, "]") || gsub(/\{/, "{") > gsub(/\}/, "}")) exit 67
            rest = $0
            sub(/^[[:space:]]*"[^"]+"[[:space:]]*:/, "", rest)
            if (rest ~ /^[[:space:]]*$/ || rest ~ /"[^"]*"[[:space:]]*:/) exit 67
            next
          }
          { print }
          END { if (skip) exit 65 }
        ' "$settings") || merged=""
      else
        run /bin/mkdir -p "''${settings%/*}"
        merged=$(printf '{\n%s\n}' "$FORGE_BLOCK")
      fi
      case "$merged" in
        *"forge-theme:begin"*)
          if [ "$merged" != "$(/bin/cat "$settings" 2>/dev/null)" ]; then
            # Publish by in-place copy: VS Code's kqueue watcher is bound to the
            # settings inode, so a rename publishes to an inode it never observes
            # and the live window keeps stale config until reload. cp truncates
            # and rewrites the existing inode, which the watcher applies live.
            tmp=$(/usr/bin/mktemp "$settings.XXXXXX")
            printf '%s\n' "$merged" >"$tmp"
            run /bin/cp "$tmp" "$settings"
            /bin/rm -f "$tmp"
          fi
          ;;
        *)
          echo "vscode theme seed: $settings lacks a root brace, carries an unterminated forge-theme block, holds a managed key on the root-brace line, or spreads a managed key across lines; block not asserted" >&2
          ;;
      esac
    '';

    # Keybindings rail: the forge-keys block re-lands at the array TAIL every
    # switch — bottom-to-top precedence makes tail position the authority — and
    # user rows above it pass through untouched. Fail-closed guards mirror the
    # settings rail: an unterminated prior block refuses (a strip would eat the
    # tail), and a document that is neither a multi-line array, the `[]`
    # template, nor absent refuses with a named error instead of guessing.
    activation.vscodeKeysSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
        kb=${lib.escapeShellArg keybindingsPath}
      FORGE_KEYS_BLOCK=$(<${config.xdg.configFile."forge/vscode/keybindings-block.jsonc".source})
      export FORGE_KEYS_BLOCK
      if [ -s "$kb" ]; then
        merged=$(/usr/bin/awk '
          /\/\/ forge-keys:begin/ { skip = 1; next }
          /\/\/ forge-keys:end/   { skip = 0; next }
          skip { next }
          { buf[++n] = $0 }
          END {
            if (skip) exit 65
            # The document tail is the LAST lone "]" line; inner array closers
            # sit earlier, and the generated block is one-line rows by contract.
            # A hand-minified closer sharing its line (e.g. "}]") would make an
            # INNER closer scan as the tail and tear the document — anything
            # but blanks or comments after the tail line refuses instead.
            tail = 0
            for (i = n; i >= 1; i--) if (buf[i] ~ /^[[:space:]]*\][[:space:]]*$/) { tail = i; break }
            if (tail == 0) {
              for (i = 1; i <= n; i++) if (buf[i] ~ /^[[:space:]]*\[\][[:space:]]*$/) {
                for (j = 1; j < i; j++) print buf[j]
                print "["
                print ENVIRON["FORGE_KEYS_BLOCK"]
                print "]"
                for (j = i + 1; j <= n; j++) print buf[j]
                exit 0
              }
              exit 66
            }
            for (i = tail + 1; i <= n; i++)
              if (buf[i] !~ /^[[:space:]]*$/ && buf[i] !~ /^[[:space:]]*\/\//) exit 66
            # The preceding element needs a separator; JSONC tolerates the
            # trailing comma our block always carries before the closer. A
            # trailing line comment would swallow an appended comma, so the
            # separator lands on the content ahead of the comment tail — but
            # only when the "//" sits OUTSIDE a string (even quote count in
            # the prefix), or a value like "x} //y" would take an interior
            # comma and change meaning silently.
            for (i = tail - 1; i >= 1; i--) {
              if (buf[i] ~ /^[[:space:]]*$/ || buf[i] ~ /^[[:space:]]*\/\//) continue
              line = buf[i]; cmt = ""
              if (match(line, /[]}",[{][[:space:]]*\/\//)) {
                pre = substr(line, 1, RSTART)
                if (gsub(/"/, "\"", pre) % 2 == 0) {
                  cmt = substr(line, RSTART + 1)
                  line = substr(line, 1, RSTART)
                }
              }
              if (line !~ /,[[:space:]]*$/ && line !~ /[[{][[:space:]]*$/) line = line ","
              buf[i] = line cmt
              break
            }
            for (i = 1; i < tail; i++) print buf[i]
            print ENVIRON["FORGE_KEYS_BLOCK"]
            for (i = tail; i <= n; i++) print buf[i]
          }
        ' "$kb") || merged=""
      else
        run /bin/mkdir -p "''${kb%/*}"
        merged=$(printf '[\n%s\n]' "$FORGE_KEYS_BLOCK")
      fi
      case "$merged" in
        *"forge-keys:begin"*)
          if [ "$merged" != "$(/bin/cat "$kb" 2>/dev/null)" ]; then
            # Same watcher law as settings: cp rewrites the live inode so the
            # running window applies the bindings without a reload.
            tmp=$(/usr/bin/mktemp "$kb.XXXXXX")
            printf '%s\n' "$merged" >"$tmp"
            run /bin/cp "$tmp" "$kb"
            /bin/rm -f "$tmp"
          fi
          ;;
        *)
          echo "vscode keys seed: $kb carries an unterminated forge-keys block or no recognizable root array; block not asserted" >&2
          ;;
      esac
    '';
  };
}
