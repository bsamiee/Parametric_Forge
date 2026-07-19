# Title         : git.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/git.nix
# ----------------------------------------------------------------------------
# Git register rows: daily ops, branch/remote, history, external tools.
{
  git-branch = [
    ["gb" "git branch -avv" "All branches with tracking"]
    ["gbd" "git branch -d" "Delete merged branch"]
    ["gco" "git checkout" "Switch branches / restore files"]
    ["gcob" "git checkout -b" "Create and switch branch"]
    ["gf" "git fetch --all" "Fetch all remotes"]
    ["gps" "git push" "Push to upstream"]
    ["gpsf" "git push --force-with-lease" "Safe force push" "destructive"]
  ];
  git-daily = [
    ["g" "git" "Git shorthand"]
    ["gstatus" "git status -sb" "Short status with branch; gs stays Ghostscript"]
    ["ga" "git add -A" "Stage all changes"]
    ["gap" "git add -p" "Interactive patch staging"]
    ["gcm" "git commit -m" "Commit with message"]
    ["gcq" "git commit --amend --no-edit" "Quick amend, keep message"]
    ["gm" "git merge --no-ff" "Merge with commit"]
    ["gd" "git diff" "Diff working tree"]
    ["gds" "git diff --staged" "Diff staged changes"]
  ];
  git-history = [
    ["gl" "git log --oneline --graph --decorate --all" "Graph log for all branches"]
    ["gst" "git stash push -m" "Stash with message"]
    ["gstp" "git stash pop" "Apply and drop latest stash"]
    ["gstl" "git stash list" "List stashes"]
    ["grb" "git rebase" "Rebase current branch"]
    ["grbi" "git rebase -i" "Interactive rebase"]
    ["grs" "git reset" "Unstage files, keep changes"]
    ["gcp" "git cherry-pick" "Apply specific commits"]
  ];
  git-tools = [
    ["lg" "lazygit" "Lazygit TUI"]
    ["gstats" "git-quick-stats" "Interactive git statistics"]
    ["gstat" "git-quick-stats -T" "Per-author contribution stats"]
    ["ghpr" "gh pr list" "List pull requests; pr stays the paginate binary"]
    ["prc" "gh pr create" "Create pull request"]
    ["prv" "gh pr view" "View pull request"]
    ["prco" "gh pr checkout" "Checkout pull request"]
  ];
}
