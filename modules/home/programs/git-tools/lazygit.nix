# Title         : lazygit.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/lazygit.nix
# ----------------------------------------------------------------------------
# Lazygit TUI configuration themed from the estate palette owner

{config, ...}: let
  inherit (config.forge.theme) palette;
in {
  programs.lazygit = {
    enable = true;

    settings = {
      # --- [INTERNATIONALIZATION]
      language = "auto";
      timeFormat = "02 Jan 06";
      shortTimeFormat = "3:04PM";

      gui = {
        # --- [DISPLAY_SETTINGS]
        showFileTree = true;
        showCommandLog = false;
        showBottomLine = false;
        showBranchCommitHash = true;
        showDivergenceFromBaseBranch = "arrowAndNumber";
        border = "rounded";
        sidePanelWidth = 0.3333;
        nerdFontsVersion = "3";

        # --- [ENHANCED_DISPLAY_OPTIONS]
        commitAuthorLongLength = 17;
        commitHashLength = 8;
        showRandomTip = true;
        showFileIcons = true;
        splitDiff = "auto";
        screenMode = "normal";

        theme = {
          activeBorderColor = [palette.magenta.hex "bold"];
          inactiveBorderColor = [palette.cyan.hex];
          searchingActiveBorderColor = [palette.yellow.hex "bold"];
          optionsTextColor = [palette.cyan.hex];
          selectedLineBgColor = [palette.selection.hex];
          defaultFgColor = [palette.foreground.hex];
          unstagedChangesColor = [palette.red.hex];
          cherryPickedCommitFgColor = [palette.cyan.hex];
          cherryPickedCommitBgColor = [palette.purple.hex];
          markedBaseCommitFgColor = [palette.yellow.hex];
          markedBaseCommitBgColor = [palette.purple.hex];
        };
      };

      git = {
        # --- [PAGING_DELTA_RENDERS_INSIDE_LAZYGIT_PANES]
        # Delta inherits its [delta] git-config options; --paging=never is the in-pane requirement and --navigate does not work inside lazygit.
        pagers = [
          {
            colorArg = "always";
            pager = "delta --paging=never";
          }
        ];

        # --- [GIT_BEHAVIOR_SETTINGS]
        autoRefresh = true;
        autoFetch = true;
        autoForwardBranches = "onlyMainBranches";
        fetchAll = true;
        mainBranches = ["main" "master" "develop" "dev"];
        skipHookPrefix = "WIP";

        # --- [LOG_DISPLAY_SETTINGS]
        log = {
          order = "topo-order";
          showGraph = "always";
        };

        # --- [COMMIT_SETTINGS]
        commit = {
          signOff = false;
          autoWrapCommitMessage = true;
          autoWrapWidth = 72;
        };

        # --- [MERGING_CONFIGURATION]
        merging = {
          manualCommit = false;
          args = "";
        };
      };

      refresher = {
        refreshInterval = 10;
        fetchInterval = 60;
      };

      # Preset owns edit/editAtLine/openDirInEditor ({{filename}}/{{line}} are the only template vars); the darwin platform default owns open/openLink.
      os.editPreset = "nvim"; # Matches EDITOR from programs.neovim.defaultEditor

      # Store-managed binary: self-update writes are impossible.
      update.method = "never";

      confirmOnQuit = false;
      quitOnTopLevelReturn = false;
      disableStartupPopups = true;
    };
  };
}
