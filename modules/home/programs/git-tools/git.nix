# Title         : git.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/git.nix
# ----------------------------------------------------------------------------
# Core Git configuration and workflow settings
_:
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
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user.name = "bsamiee";
      user.email = "b.samiee93@gmail.com";
      init.defaultBranch = "main";

      pull.rebase = true; # Always rebase on pull (ff setting ignored with rebase)

      push = {
        default = "current";
        autoSetupRemote = true;
        useForceIfIncludes = true;
        followTags = true;
      };

      core = {
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
        preloadindex = true;
        fsmonitor = true; # Background daemon for instant git status
        untrackedCache = true; # 2x faster untracked file detection
        commitGraph = true; # Cache commit DAG for faster git log
      };

      feature.manyFiles = true;
      index.threads = 0;
      pack.threads = 0;

      diff = {
        algorithm = "histogram";
        renames = "copies";
        colorMoved = "default";
        submodule = "log"; # Show submodule changes in diffs
      };

      merge = {
        conflictstyle = "zdiff3";
        ff = false;
      };

      fetch = {
        prune = true;
        prunetags = true;
        fsckObjects = true;
        writeCommitGraph = true; # Update commit graph cache on fetch
      };
      receive.fsckObjects = true;
      transfer.fsckobjects = true;

      branch = {
        sort = "-committerdate";
        autosetupmerge = "always";
        autosetuprebase = "always";
      };

      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };

      status = {
        branch = true;
        showUntrackedFiles = "all";
        submoduleSummary = true; # Show submodule summary in status
      };

      log = {
        date = "iso";
        follow = true;
      };

      column.ui = "auto"; # Multi-column output for branch/tag lists
      tag.sort = "version:refname"; # Sort tags as semantic versions

      commit.verbose = true;
      rerere.enabled = true;
      help.autocorrect = 20;
    };
  };

  # Delta is now configured via programs.delta, with explicit Git integration
  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    options = {
      navigate = true;
      light = false;
      side-by-side = true;

      # Line numbers
      line-numbers = true;
      line-numbers-minus-style = "red";
      line-numbers-plus-style = "green";
      line-numbers-zero-style = "dim";
      line-numbers-left-format = "{nm:>4}⋮";
      line-numbers-right-format = "{np:>4}│";

      # File headers
      file-style = "bold";
      file-decoration-style = "none";
      file-added-label = "";
      file-copied-label = "[==]";
      file-modified-label = "";
      file-removed-label = "";
      file-renamed-label = "";

      # Hunk headers
      hunk-header-style = "file line-number";
      hunk-header-decoration-style = "box";

      # Commit/blame styles
      commit-decoration-style = "bold box ul";
      commit-style = "raw";

      # Blame configuration
      blame-format = "{timestamp:<15} {author:<15.14} {commit:<8}";
      blame-palette = "#2e3440 #3b4252 #434c5e #4c566a";
      blame-separator-format = "│{n:^4}│";
      blame-separator-style = "dim";
      blame-timestamp-output-format = "%Y-%m-%d %H:%M";

      # Diff styles
      minus-style = "syntax";
      minus-emph-style = "syntax bold";
      plus-style = "syntax";
      plus-emph-style = "syntax bold";

      # Grep integration
      grep-output-type = "ripgrep";
      grep-match-line-style = "syntax";
      grep-match-word-style = "bold magenta";
      grep-line-number-style = "green";
      grep-file-style = "blue bold";
      grep-separator-symbol = ":";

      # Advanced diff features
      word-diff-regex = "\\w+|[^[:space:]]";
      max-line-distance = "0.6";
      whitespace-error-style = "magenta reverse";
      relative-paths = true;
      default-language = "txt";

      # Line wrapping
      wrap-max-lines = 2;
      wrap-left-symbol = "↵";
      wrap-right-symbol = "↴";
      wrap-right-prefix-symbol = "…";

      # UI elements
      keep-plus-minus-markers = false;
      syntax-theme = "Dracula"; # Match bat theme
      true-color = "always";
      zero-style = "dim syntax";

      # Interactive features
      hyperlinks = true;
      hyperlinks-file-link-format = "vscode://file/{path}:{line}";
    };
  };
}
