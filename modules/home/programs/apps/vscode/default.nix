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
# sentinel-managed publish rail and the manifest-rostered extension surface.
# The publish rail targets the Default profile settings file; a custom full
# profile reads profiles/<id>/settings.json and never sees this block.
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

  forgeSettings =
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
      "explorer.fileNesting.patterns" = {
        "flake.nix" = "flake.lock";
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
      "dotnet.preferCSharpExtension" = false;
      "dotnet.server.useOmnisharp" = false;
      "dotnet.enableXamlTools" = false;
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

  # Strip set derives from the asserted rows; tombstones strip retired keys
  # whose value now falls back to the app default (the experimental renderer
  # and retired EditContext spelling are owned-surface cleanup).
  managedKeys =
    builtins.attrNames asserted
    ++ [
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
in {
  # Project-agnostic projection artifacts; sibling repos consume these instead
  # of carrying color copies in workspace settings.
  xdg.configFile = {
    "forge/theme/vscode.json".text = builtins.toJSON forgeSettings;
    "forge/theme/vscode-settings-block.jsonc".text = forgeBlock;
    "forge/vscode/roster.json".text = ext.rosterJson;
    "forge/schemas/greptile-config.schema.json".source = ./schemas/greptile-config.schema.json;
    "forge/schemas/greptile-files.schema.json".source = ./schemas/greptile-files.schema.json;
  };

  home.packages = [ext.package];

  home.activation.vscodeThemeSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
        inserted && $0 ~ ENVIRON["FORGE_MANAGED_RE"] { next }
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
        echo "vscode theme seed: $settings lacks a root brace, carries an unterminated forge-theme block, or holds a managed key on the root-brace line; block not asserted" >&2
        ;;
    esac
  '';
}
