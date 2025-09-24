# Title         : git.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/git.nix
# ----------------------------------------------------------------------------
# Git version control aliases - dynamically generated for consistency

{ lib, ... }:

let
  # --- Core Git Commands (dynamically prefixed with 'g') -------------------
  gitCommands = {
    # Status & inspection
    s = "status -sb";
    # Simple log variations (removed complex function)
    l = "log --oneline --graph --decorate -10"; # Quick last 10
    ll = "log --oneline --graph --decorate"; # Full log
    lg = "log --graph --pretty=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --abbrev-commit --all"; # Pretty graph
    d = "diff";
    ds = "diff --staged"; # Staged changes

    # File operations
    a = "add";
    aa = "add --all";
    ap = "add --patch";
    c = "commit";
    cm = "commit -m";
    ca = "commit --amend --no-edit";
    cae = "commit --amend";

    # Push/pull/fetch
    p = "push";
    pf = "push --force-with-lease";
    pl = "pull"; # Config now handles --rebase
    f = "fetch --all"; # Config handles --prune --prune-tags

    # Branch operations - prefer modern 'switch' over 'checkout'
    b = "branch -vv";
    br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
    sw = "switch";
    sc = "switch -c";
    m = "merge"; # Config handles --no-ff
    bd = "branch -d";
    bD = "branch -D";

    # Rebase operations
    rb = "rebase";
    rbi = "rebase -i HEAD~10";
    rbc = "rebase --continue";
    rba = "rebase --abort";

    # Stash operations
    st = "stash push -u";
    stp = "stash pop";
    stl = "stash list";
    sta = "stash apply";
    std = "stash drop";
    sts = "stash show -p";

    # Remote operations
    r = "remote -v";
    ra = "remote add";
    rr = "remote remove";

    # Reset operations
    rs = "reset";
    rsh = "reset --hard";

    # Cherry-pick & advanced
    cp = "cherry-pick";
    cpa = "cherry-pick --abort";
    cpc = "cherry-pick --continue";

    # Inspection & analysis
    who = "shortlog -sn";
    contrib = "contrib";

    # Workflow operations
    wip = "!git add -A && git commit -m 'wip' --no-verify";
    unstage = "reset HEAD --";
    uncommit = "reset --soft HEAD~1";

    # Maintenance
    cleanup = "!git remote prune origin && git gc --auto";
    prune = "remote prune origin";
    gc = "gc --aggressive --prune=now";
    verify = "fsck --full";

    # Dangerous operations
    nuke = "!git reset --hard HEAD && git clean -fd";
    pristine = "!git reset --hard && git clean -fdx";

    # Git-extras (only keep useful ones)
    ignore = "ignore";
    summary = "summary";
    delmerged = "delete-merged-branches";
    changelog = "changelog";
    authors = "authors";
    effort = "effort";
  };

  # --- Git LFS Commands -----------------------------------------------------
  lfsCommands = {
    t = "lfs track";
    ls = "lfs ls-files";
    s = "lfs status";
  };

  # --- GitHub CLI Commands (no prefix - use directly) ----------------------
  ghCommands = {
    # Pull Request workflows
    prco = "pr checkout";
    prv = "pr view --web";
    prc = "pr create --web";
    prm = "pr merge --squash --delete-branch";
    prs = "pr status";

    # Issues
    il = "issue list --assignee @me";
    ic = "issue create --web";
    iv = "issue view --web";

    # Repository
    rv = "repo view --web";
    rc = "repo clone";
    rf = "repo fork";

    # Workflow
    wl = "workflow list";
    wr = "workflow run";
    runs = "run list --limit 10";
  };

in
{
  aliases =
    # Git commands with 'g' prefix
    lib.mapAttrs' (name: value: {
      name = "g${name}";
      value = "git ${value}";
    }) gitCommands
    # Git LFS commands with 'glfs' prefix
    // lib.mapAttrs' (name: value: {
      name = "glfs${name}";
      value = "git ${value}";
    }) lfsCommands
    # GitHub CLI commands - no extra prefix
    // lib.mapAttrs' (name: value: {
      name = "${name}";
      value = "gh ${value}";
    }) ghCommands
    // {
      # Special standalone shortcuts
      g = "git";
      gh = "gh";
      lg = "lazygit";
    };
}
