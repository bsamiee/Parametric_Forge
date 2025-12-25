# Title         : git.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/git.nix
# ----------------------------------------------------------------------------
# Git workflow aliases with tool integrations
_: {
  programs.zsh.shellAliases = {
    # --- Daily Operations ---------------------------------------------------
    g = "git"; # Git shorthand
    gs = "git status -sb"; # Short status with branch info
    ga = "git add -A"; # Stage all changes (new, modified, deleted)
    gap = "git add -p"; # Interactive patch staging
    gcm = "git commit -m"; # Commit with message (verbose via config)
    gcq = "git commit --amend --no-edit"; # Quick amend without editing message
    gm = "git merge --no-ff"; # Merge with commit (ff=false via config)
    gd = "git diff"; # Diff working tree (delta via GIT_PAGER)
    gds = "git diff --staged"; # Diff staged changes (delta via GIT_PAGER)

    # --- Branch & Remote ----------------------------------------------------
    gb = "git branch -avv"; # List all branches with tracking info
    gbd = "git branch -d"; # Delete merged branch (safe)
    gco = "git checkout"; # Switch branches/restore files
    gcob = "git checkout -b"; # Create and switch to new branch
    gf = "git fetch --all"; # Fetch from all remotes (prune via config)
    gps = "git push"; # Push to upstream (auto-setup via config)
    gpsf = "git push --force-with-lease"; # Safe force push

    # --- History Management -------------------------------------------------
    gl = "git log --oneline --graph --decorate --all"; # Graph log for all branches
    gst = "git stash push -m"; # Stash with descriptive message
    gstp = "git stash pop"; # Apply and remove latest stash
    gstl = "git stash list"; # List all stashes
    grb = "git rebase"; # Rebase current branch (autostash via config)
    grbi = "git rebase -i"; # Interactive rebase
    grs = "git reset"; # Unstage files (keep changes)
    grsh = "git reset --hard"; # Reset and discard all changes
    gclean = "git clean -fdx"; # Remove untracked files and directories
    gcp = "git cherry-pick"; # Apply specific commits
    groot = "cd $(git rev-parse --show-toplevel)"; # Jump to repository root

    # --- External Tools -----------------------------------------------------
    lg = "lazygit"; # Launch lazygit TUI
    gstats = "git-quick-stats"; # Interactive git statistics menu
    gstat = "git-quick-stats -r"; # Quick repository overview
    pr = "gh pr list"; # List pull requests
    prc = "gh pr create"; # Create pull request
    prv = "gh pr view"; # View pull request details
    prco = "gh pr checkout"; # Checkout pull request locally
  };
}
