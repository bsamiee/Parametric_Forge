# Title         : git.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/git.nix
# ----------------------------------------------------------------------------
# Git register rows: daily ops, branch/remote, history, external tools.
{
  git-branch = [
    ["gb" "git branch -avv"]
    ["gbd" "git branch -d"]
    ["gco" "git checkout"]
    ["gcob" "git checkout -b"]
    ["gf" "git fetch --all"]
    ["gps" "git push"]
    ["gpsf" "git push --force-with-lease"]
  ];
  git-daily = [
    ["g" "git"]
    ["gstatus" "git status -sb"]
    ["ga" "git add -A"]
    ["gap" "git add -p"]
    ["gcm" "git commit -m"]
    ["gcq" "git commit --amend --no-edit"]
    ["gm" "git merge --no-ff"]
    ["gd" "git diff"]
    ["gds" "git diff --staged"]
  ];
  git-history = [
    ["gl" "git log --oneline --graph --decorate --all"]
    ["gst" "git stash push -m"]
    ["gstp" "git stash pop"]
    ["gstl" "git stash list"]
    ["grb" "git rebase"]
    ["grbi" "git rebase -i"]
    ["grs" "git reset"]
    ["gcp" "git cherry-pick"]
  ];
  # forgit's fzf commands through git-forgit's subcommands; the seven names the register spends on plain git (ga gd gcp grb gbd gco grs) take
  # an f suffix. gwt and gwa are site functions (zsh/plugins.nix) because they cd.
  git-forgit = [
    ["gaf" "git forgit add"]
    ["gdf" "git forgit diff"]
    ["glo" "git forgit log"]
    ["grl" "git forgit reflog"]
    ["gso" "git forgit show"]
    ["grh" "git forgit reset_head"]
    ["grsf" "git forgit restore"]
    ["gcf" "git forgit checkout_file"]
    ["gcff" "git forgit checkout_file_from_commit"]
    ["gcb" "git forgit checkout_branch"]
    ["gsw" "git forgit switch_branch"]
    ["gcof" "git forgit checkout_commit"]
    ["gct" "git forgit checkout_tag"]
    ["gbdf" "git forgit branch_delete"]
    ["grc" "git forgit revert_commit"]
    ["gclean" "git forgit clean"]
    ["gss" "git forgit stash_show"]
    ["gsp" "git forgit stash_push"]
    ["gcpf" "git forgit cherry_pick_from_branch"]
    ["grbf" "git forgit rebase"]
    ["gfu" "git forgit fixup"]
    ["gsq" "git forgit squash"]
    ["grw" "git forgit reword"]
    ["gbl" "git forgit blame"]
    ["gi" "git forgit ignore"]
    ["gat" "git forgit attributes"]
    ["gwd" "git forgit worktree_delete"]
  ];
  git-tools = [
    ["ghpr" "gh pr list"]
    ["prc" "gh pr create"]
    ["prv" "gh pr view"]
    ["prco" "gh pr checkout"]
  ];
}
