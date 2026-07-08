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
        # --- Paging Configuration -------------------------------------------
        paging.colorArg = "always";

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

      os = {
        # --- Editor Integration ---------------------------------------------
        editPreset = "nvim"; # Matches EDITOR in core.nix
        edit = "{{editor}} {{filename}}";
        editAtLine = "{{editor}} +{{line}} {{filename}}";
        openDirInEditor = "{{editor}} {{dir}}";

        # --- macOS Integration ----------------------------------------------
        open = "open {{filename}}";
        openDirInApp = "open {{dir}}";
      };

      update = {
        method = "prompt";
        days = 14;
      };

      confirmOnQuit = false;
      quitOnTopLevelReturn = false;
      startupPopupVersion = 5;
    };
  };
}
