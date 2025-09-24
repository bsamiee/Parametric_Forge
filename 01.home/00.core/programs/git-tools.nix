# Title         : git-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/git-tools.nix
# ----------------------------------------------------------------------------
# Git ecosystem tools: Git, GitHub CLI, and Lazygit configuration.

_:

{
  # --- Git Core Configuration -----------------------------------------------
  programs = {
    git = {
      enable = true;
      userName = "bsamiee";
      userEmail = "b.samiee93@gmail.com";
      # --- Git Tools --------------------------------------------------------
      lfs.enable = true;
      delta = {
        enable = true;
        options = {
          # --- Core Features --------------------------------------------------
          navigate = true; # Use n and N to navigate between diff sections
          line-numbers = true; # Show line numbers
          side-by-side = true; # Side-by-side view for wider terminals
          hyperlinks = true; # Make commit hashes clickable in supported terminals

          # --- Dracula Theme Configuration ------------------------------------
          syntax-theme = "Dracula";
          plus-style = "syntax #003800"; # Added lines - dark green background
          minus-style = "syntax #3f0001"; # Removed lines - dark red background

          # --- Decorations ----------------------------------------------------
          features = "decorations line-numbers"; # Enable feature groups
          decorations = {
            commit-decoration-style = "bold yellow box ul";
            file-style = "bold yellow ul";
            file-decoration-style = "none";
            hunk-header-decoration-style = "cyan box ul";
          };

          # --- Line Numbers ---------------------------------------------------
          line-numbers-left-style = "cyan";
          line-numbers-right-style = "cyan";
          line-numbers-minus-style = "124"; # Red for removed lines
          line-numbers-plus-style = "28"; # Green for added lines
        };
      };
      # --- Core Configuration -----------------------------------------------
      extraConfig = {
        init.defaultBranch = "master";
        pull = {
          ff = "only";
          rebase = true; # Always rebase on pull
        };
        push = {
          default = "current";
          autoSetupRemote = true;
          useForceIfIncludes = true; # Safer force pushes - requires local ref to be up-to-date
          followTags = true; # Automatically push annotated tags
        };
        core = {
          # editor already set globally in environment.nix
          autocrlf = "input";
          whitespace = "trailing-space,space-before-tab";
          preloadindex = true; # Faster operations by preloading index
          # exclude/attributes files placed by file-management.nix
        };
        feature.manyFiles = true; # Optimizations for repos with many files
        index.threads = 0; # Use all CPU cores for index operations
        diff = {
          colorMoved = "default";
          algorithm = "histogram";
          submodule = "log"; # Show submodule changes in diffs
          renames = "copies"; # Detect both renames and copies
        };
        merge = {
          conflictstyle = "zdiff3";
          ff = false; # Always create merge commits
        };
        rerere.enabled = true;
        fetch = {
          prune = true;
          prunetags = true;
          fsckObjects = true; # Verify object integrity on fetch
        };
        receive.fsckObjects = true; # Verify object integrity on receive
        pack.threads = 0;
        transfer.fsckobjects = true;
        status = {
          branch = true;
          showUntrackedFiles = "all";
          submoduleSummary = true; # Show submodule summary in status
        };
        log = {
          date = "iso"; # ISO 8601 format for dates
          follow = true; # Follow renames in history
        };
        branch = {
          sort = "-committerdate";
          autosetupmerge = "always"; # Auto-track remote branches
          autosetuprebase = "always"; # Default to rebase for new branches
        };
        rebase = {
          autoStash = true;
          autoSquash = true;
          updateRefs = true;
        };
        # Commit configuration - SSH signing handled by ssh.nix
        commit.verbose = true;
        help.autocorrect = 20;

        # Note: GitHub/Gist credential helper automatically configured by programs.gh module
      };
    };
    # --- GitHub CLI Configuration -------------------------------------------
    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
        spinner = "enabled";
        prefer_editor_prompt = "disabled";
        # pager, editor, browser inherit from env vars (GH_PAGER, EDITOR, BROWSER)
      };
      # Extensions: gh-copilot, gh-dash, gh-skyline available via `gh extension install`
    };
    # --- Lazygit Configuration ----------------------------------------------
    lazygit = {
      enable = true;
      settings = {
        # --- User Interface -------------------------------------------------
        gui = {
          showFileTree = true;
          showCommandLog = false;
          showBottomLine = false;
          showBranchCommitHash = true; # Show commit hash alongside branch name
          showDivergenceFromBaseBranch = "arrowAndNumber"; # Show commits ahead/behind
          border = "rounded";
          sidePanelWidth = 0.3333;
          nerdFontsVersion = "3";
          # Dracula theme colors
          theme = {
            activeBorderColor = [
              "#ff79c6"
              "bold"
            ]; # Pink
            inactiveBorderColor = [ "#6272a4" ]; # Comment
            searchingActiveBorderColor = [
              "#f1fa8c"
              "bold"
            ]; # Yellow
            optionsTextColor = [ "#8be9fd" ]; # Cyan
            selectedLineBgColor = [ "#44475a" ]; # Current Line
            cherryPickedCommitFgColor = [ "#8be9fd" ]; # Cyan
            cherryPickedCommitBgColor = [ "#bd93f9" ]; # Purple
            unstagedChangesColor = [ "#ff5555" ]; # Red
            defaultFgColor = [ "#f8f8f2" ]; # Foreground
          };
        };
        # --- Git Workflow ---------------------------------------------------
        git = {
          paging = {
            colorArg = "always";
            # pager inherits from GIT_PAGER env var
          };
          pull.mode = "rebase";
          autoRefresh = true;
          autoFetch = true;
          autoForwardBranches = "onlyMainBranches"; # Auto fast-forward main branches
          fetchAll = true; # Fetch all remotes
          mainBranches = [
            "master"
            "main"
            "develop"
          ];
        };
        # --- Performance ----------------------------------------------------
        refresher = {
          refreshInterval = 10;
          fetchInterval = 60;
        };
        # --- System Integration ---------------------------------------------
        os = {
          # editor commands use $EDITOR env var
          edit = "{{editor}} {{filename}}";
          editAtLine = "{{editor}} +{{line}} {{filename}}";
        };
        # --- Update Management ----------------------------------------------
        update = {
          method = "prompt";
          days = 14;
        };
      };
    };
  };
}
