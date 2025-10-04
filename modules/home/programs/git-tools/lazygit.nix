# Title         : lazygit.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/lazygit.nix
# ----------------------------------------------------------------------------
# Lazygit TUI configuration with Dracula theme

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475A
# foreground    #F8F8F2
# comment       #6272A4
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #FF5555
# magenta       #d82f94
# pink          #E98FBE

{
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
          activeBorderColor = ["#d82f94" "bold"];
          inactiveBorderColor = ["#94F2E8"];
          searchingActiveBorderColor = ["#F1FA8C" "bold"];
          optionsTextColor = ["#94F2E8"];
          selectedLineBgColor = ["#44475A"];
          defaultFgColor = ["#F8F8F2"];
          unstagedChangesColor = ["#FF5555"];
          cherryPickedCommitFgColor = ["#94F2E8"];
          cherryPickedCommitBgColor = ["#A072C6"];
          markedBaseCommitFgColor = ["#F1FA8C"];
          markedBaseCommitBgColor = ["#A072C6"];
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
        editPreset = "nvim";  # Matches EDITOR in core.nix
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
