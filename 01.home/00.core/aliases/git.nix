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
    l = "!f() { case \${1:-short} in short) git log --oneline --graph --decorate -10 ;; full) git log --oneline --graph --decorate ;; pretty) git log --pretty=format:'%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]' --abbrev-commit -20 ;; graph) git log --graph --pretty=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --abbrev-commit --all ;; [0-9]*) git log --oneline --graph --decorate -\$1 ;; *) echo 'Usage: gl [short|full|pretty|graph|NUMBER]' ;; esac; }; f";
    d = "diff";
    ds = "diff --staged";
    dc = "diff --cached";

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
    pl = "pull --rebase --autostash";
    f = "fetch --all --prune --prune-tags";

    # Branch operations
    b = "branch -vv";
    br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
    co = "checkout";
    cb = "checkout -b";
    sw = "switch";
    sc = "switch -c";
    m = "merge --no-ff";
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
    undo = "undo";
    unstage = "reset HEAD --";
    uncommit = "reset --soft HEAD~1";
    fixup = "!f() { git commit --fixup=\$1; }; f";
    squash = "!f() { git rebase -i --autosquash \$1~; }; f";

    # Maintenance
    cleanup = "!git remote prune origin && git gc --auto";
    prune = "remote prune origin";
    gc = "gc --aggressive --prune=now";
    verify = "fsck --full";

    # Dangerous operations
    nuke = "!git reset --hard HEAD && git clean -fd";
    pristine = "!git reset --hard && git clean -fdx";

    # Git-extras workflow tools
    ignore = "ignore";
    summary = "summary";
    delmerged = "delete-merged-branches";
    standup = "standup";

    # Code quality & hooks
    hooks = "pre-commit";
    hookinstall = "pre-commit install";
    hookrun = "pre-commit run --all-files";
    hookupdate = "pre-commit update";

    # Git-extras analysis
    authors = "authors";
    effort = "effort";
    info = "info";
    changelog = "changelog";

    # Git-extras branch & sync
    sync = "sync";
    fresh = "fresh-branch";
    showtree = "show-tree";

    # Git-extras advanced
    repl = "repl";
    bulk = "bulk";
    lock = "lock";
    unlock = "unlock";
  };

  # --- Git LFS Commands -----------------------------------------------------
  lfsCommands = {
    t = "lfs track";
    ls = "lfs ls-files";
    s = "lfs status";
  };

  # --- GitHub CLI Commands (dynamically prefixed with 'gh') ----------------
  ghCommands = {
    # Pull Request workflows
    co = "pr checkout";
    pv = "pr view --web";
    pc = "pr create --web";
    pm = "pr merge --squash --delete-branch";

    # Pull Request listing
    pl = "pr list --author @me";
    prl = "pr list --reviewer @me";
    pra = "pr list --assignee @me";
    ps = "pr status";
    pcheck = "pr checks";

    # Repository management
    rv = "repo view --web";
    rc = "repo clone";
    rf = "repo fork";

    # Issue management
    il = "issue list --assignee @me";
    ic = "issue create --web";
    iv = "issue view --web";

    # Workflow & CI
    wl = "workflow list";
    wr = "workflow run";
    wv = "workflow view";
    runs = "run list --limit 10";

    # Advanced operations
    bl = "repo view --branch";
    rl = "release list --limit 5";
    rla = "release view --web";
    api = "api";
    gl = "gist list --limit 10";

    # Search and discovery
    sr = "search repos";
    si = "search issues";
    sp = "search prs";
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
    # GitHub CLI commands with 'gh' prefix
    // lib.mapAttrs' (name: value: {
      name = "gh${name}";
      value = "gh ${value}";
    }) ghCommands
    // {
      # Special cases
      g = "git";
      gh = "gh";
      lazygit = "lazygit";
      lg = "lazygit";
    };
}
