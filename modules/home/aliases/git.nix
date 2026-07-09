# Title         : git.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/aliases/git.nix
# ----------------------------------------------------------------------------
# Git register rows: daily ops, branch/remote, history, external tools.
[
  # --- git-daily ---------------------------------------------------------------
  {
    alias = "g";
    expansion = "git";
    desc = "Git shorthand";
    category = "git-daily";
  }
  {
    alias = "gstatus";
    expansion = "git status -sb";
    desc = "Short status with branch; gs stays Ghostscript";
    category = "git-daily";
  }
  {
    alias = "ga";
    expansion = "git add -A";
    desc = "Stage all changes";
    category = "git-daily";
  }
  {
    alias = "gap";
    expansion = "git add -p";
    desc = "Interactive patch staging";
    category = "git-daily";
  }
  {
    alias = "gcm";
    expansion = "git commit -m";
    desc = "Commit with message";
    category = "git-daily";
  }
  {
    alias = "gcq";
    expansion = "git commit --amend --no-edit";
    desc = "Quick amend, keep message";
    category = "git-daily";
  }
  {
    alias = "gm";
    expansion = "git merge --no-ff";
    desc = "Merge with commit";
    category = "git-daily";
  }
  {
    alias = "gd";
    expansion = "git diff";
    desc = "Diff working tree";
    category = "git-daily";
  }
  {
    alias = "gds";
    expansion = "git diff --staged";
    desc = "Diff staged changes";
    category = "git-daily";
  }
  # --- git-branch --------------------------------------------------------------
  {
    alias = "gb";
    expansion = "git branch -avv";
    desc = "All branches with tracking";
    category = "git-branch";
  }
  {
    alias = "gbd";
    expansion = "git branch -d";
    desc = "Delete merged branch";
    category = "git-branch";
  }
  {
    alias = "gco";
    expansion = "git checkout";
    desc = "Switch branches / restore files";
    category = "git-branch";
  }
  {
    alias = "gcob";
    expansion = "git checkout -b";
    desc = "Create and switch branch";
    category = "git-branch";
  }
  {
    alias = "gf";
    expansion = "git fetch --all";
    desc = "Fetch all remotes";
    category = "git-branch";
  }
  {
    alias = "gps";
    expansion = "git push";
    desc = "Push to upstream";
    category = "git-branch";
  }
  {
    alias = "gpsf";
    expansion = "git push --force-with-lease";
    desc = "Safe force push";
    category = "git-branch";
    risk = "destructive";
  }
  # --- git-history -------------------------------------------------------------
  {
    alias = "gl";
    expansion = "git log --oneline --graph --decorate --all";
    desc = "Graph log for all branches";
    category = "git-history";
  }
  {
    alias = "gst";
    expansion = "git stash push -m";
    desc = "Stash with message";
    category = "git-history";
  }
  {
    alias = "gstp";
    expansion = "git stash pop";
    desc = "Apply and drop latest stash";
    category = "git-history";
  }
  {
    alias = "gstl";
    expansion = "git stash list";
    desc = "List stashes";
    category = "git-history";
  }
  {
    alias = "grb";
    expansion = "git rebase";
    desc = "Rebase current branch";
    category = "git-history";
  }
  {
    alias = "grbi";
    expansion = "git rebase -i";
    desc = "Interactive rebase";
    category = "git-history";
  }
  {
    alias = "grs";
    expansion = "git reset";
    desc = "Unstage files, keep changes";
    category = "git-history";
  }
  {
    alias = "gcp";
    expansion = "git cherry-pick";
    desc = "Apply specific commits";
    category = "git-history";
  }
  # --- git-tools ---------------------------------------------------------------
  {
    alias = "lg";
    expansion = "lazygit";
    desc = "Lazygit TUI";
    category = "git-tools";
  }
  {
    alias = "gstats";
    expansion = "git-quick-stats";
    desc = "Interactive git statistics";
    category = "git-tools";
  }
  {
    alias = "gstat";
    expansion = "git-quick-stats -T";
    desc = "Per-author contribution stats";
    category = "git-tools";
  }
  {
    alias = "ghpr";
    expansion = "gh pr list";
    desc = "List pull requests; pr stays the paginate binary";
    category = "git-tools";
  }
  {
    alias = "prc";
    expansion = "gh pr create";
    desc = "Create pull request";
    category = "git-tools";
  }
  {
    alias = "prv";
    expansion = "gh pr view";
    desc = "View pull request";
    category = "git-tools";
  }
  {
    alias = "prco";
    expansion = "gh pr checkout";
    desc = "Checkout pull request";
    category = "git-tools";
  }
]
