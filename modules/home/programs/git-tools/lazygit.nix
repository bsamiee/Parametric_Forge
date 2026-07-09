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
      # --- Internationalization ---------------------------------------------
      language = "auto";
      timeFormat = "02 Jan 06";
      shortTimeFormat = "3:04PM";

      gui = {
        # --- Display Settings -----------------------------------------------
        showFileTree = true;
        showCommandLog = false;
        showBottomLine = false;
        showBranchCommitHash = true;
        showDivergenceFromBaseBranch = "arrowAndNumber";
        border = "rounded";
        sidePanelWidth = 0.3333;
        nerdFontsVersion = "3";

        # --- Enhanced Display Options ---------------------------------------
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
        # --- Paging: delta renders inside lazygit panes -----------------------
        # Delta inherits its [delta] git-config options; --paging=never is the
        # in-pane requirement and --navigate does not work inside lazygit.
        pagers = [
          {
            colorArg = "always";
            pager = "delta --paging=never";
          }
        ];

        # --- Git Behavior Settings ------------------------------------------
        autoRefresh = true;
        autoFetch = true;
        autoForwardBranches = "onlyMainBranches";
        fetchAll = true;
        mainBranches = ["main" "master" "develop" "dev"];
        skipHookPrefix = "WIP";

        # --- Log Display Settings -------------------------------------------
        log = {
          order = "topo-order";
          showGraph = "always";
        };

        # --- Commit Settings ------------------------------------------------
        commit = {
          signOff = false;
          autoWrapCommitMessage = true;
          autoWrapWidth = 72;
        };

        # --- Merging Configuration ------------------------------------------
        merging = {
          manualCommit = false;
          args = "";
        };
      };

      refresher = {
        refreshInterval = 10;
        fetchInterval = 60;
      };

      # Preset owns edit/editAtLine/openDirInEditor ({{filename}}/{{line}} are the
      # only template vars); the darwin platform default owns open/openLink.
      os.editPreset = "nvim"; # Matches EDITOR in core.nix

      # Store-managed binary: self-update writes are impossible.
      update.method = "never";

      confirmOnQuit = false;
      quitOnTopLevelReturn = false;
      disableStartupPopups = true;
    };
  };
}
