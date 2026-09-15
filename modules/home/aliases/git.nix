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
  # forgit's fzf widgets under forgit's own default names; the seven names the register already spends on plain git (ga gd gcp grb gbd gco grs)
  # take an f suffix. The plugin's alias table is off (FORGIT_NO_ALIASES), so this register is the one owner of every g* name.
  git-forgit = [
    ["gaf" "forgit::add" "Interactive add"]
    ["gdf" "forgit::diff" "Interactive diff"]
    ["glo" "forgit::log" "Interactive log"]
    ["grl" "forgit::reflog" "Interactive reflog"]
    ["gso" "forgit::show" "Interactive show"]
    ["grh" "forgit::reset::head" "Interactive unstage"]
    ["grsf" "forgit::restore" "Interactive restore"]
    ["gcf" "forgit::checkout::file" "Interactive checkout file"]
    ["gcff" "forgit::checkout::file::from::commit" "Interactive checkout file from a commit"]
    ["gcb" "forgit::checkout::branch" "Interactive checkout branch"]
    ["gsw" "forgit::switch::branch" "Interactive switch branch"]
    ["gcof" "forgit::checkout::commit" "Interactive checkout commit"]
    ["gct" "forgit::checkout::tag" "Interactive checkout tag"]
    ["gbdf" "forgit::branch::delete" "Interactive branch delete" "destructive"]
    ["grc" "forgit::revert::commit" "Interactive revert"]
    ["gclean" "forgit::clean" "Interactive clean" "destructive"]
    ["gss" "forgit::stash::show" "Interactive stash show"]
    ["gsp" "forgit::stash::push" "Interactive stash push"]
    ["gcpf" "forgit::cherry::pick::from::branch" "Interactive cherry-pick from a branch"]
    ["grbf" "forgit::rebase" "Interactive rebase"]
    ["gfu" "forgit::fixup" "Interactive fixup"]
    ["gsq" "forgit::squash" "Interactive squash"]
    ["grw" "forgit::reword" "Interactive reword"]
    ["gbl" "forgit::blame" "Interactive blame"]
    ["gi" "forgit::ignore" "Gitignore template picker"]
    ["gat" "forgit::attributes" "Gitattributes template picker"]
    ["gwt" "forgit::worktree" "Interactive worktree switch"]
    ["gwa" "forgit::worktree::add" "Interactive worktree add"]
    ["gwd" "forgit::worktree::delete" "Interactive worktree delete" "destructive"]
  ];
  git-tools = [
    ["lg" "lazygit" "Lazygit TUI"]
    ["ghpr" "gh pr list" "List pull requests; pr stays the paginate binary"]
    ["prc" "gh pr create" "Create pull request"]
    ["prv" "gh pr view" "View pull request"]
    ["prco" "gh pr checkout" "Checkout pull request"]
  ];
}
