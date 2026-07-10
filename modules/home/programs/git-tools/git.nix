# Title         : git.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/git.nix
# ----------------------------------------------------------------------------
# Git identity, op-backed SSH signing, workflow settings, delta + difftastic
{
  config,
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  # One universal identity; the unified estate key ("Forge SSH Key" in the
  # Private vault) authenticates and signs. op-ssh-sign resolves it by
  # public key through the 1Password agent seam in shell-tools/1password.nix.
  identity = {
    name = "Bardia Samiee";
    email = "b.samiee93@gmail.com";
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13xqqm/BVTzJNN/V0Cukvk4xAentt3qqE525URRqwS";
  };
  # Principal table for local `git log --show-signature` verification.
  trustedPrincipals = [identity.email];
in {
  # Git trust material lives beside the git config, not in xdg.nix.
  xdg.configFile."git/allowed_signers".text =
    lib.concatMapStrings
    (principal: "${principal} namespaces=\"git\" ${identity.publicKey}\n")
    trustedPrincipals;

  programs.git = {
    enable = true;
    lfs.enable = true;

    # The op agent (and its signer binary) exists on Darwin only; maghz holds
    # no private key, so signing stays off there instead of faulting per commit.
    signing =
      {
        key = "key::${identity.publicKey}";
        format = "ssh";
        signByDefault = isDarwin;
      }
      // lib.optionalAttrs isDarwin {
        signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };

    settings = {
      user = {inherit (identity) name email;};
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
        fsmonitor = true; # Background daemon for instant git status; forge-git-doctor owns the health receipt
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
        tool = "difftastic"; # Structural lane: `git difftool` / `git dft`; delta owns the pager lane
      };

      difftool = {
        prompt = false;
        # GIT_EXTERNAL_DIFF calling convention: difft renders rename/mode data.
        difftastic.cmd = ''difft "$MERGED" "$LOCAL" "abcdef1" "100644" "$REMOTE" "abcdef2" "100644"'';
      };
      pager.difftool = true;
      alias.dft = "difftool";

      merge = {
        conflictstyle = "zdiff3";
        ff = false;
        # Structural merge driver (manifest admission row): registration is
        # inert until a repo opts in via gitattributes `merge=mergiraf` —
        # fixture-proven before any default enablement.
        mergiraf = {
          name = "mergiraf";
          driver = "${lib.getExe pkgs.mergiraf} merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
        };
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

      gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";

      commit.verbose = true;
      rerere.enabled = true;
      help.autocorrect = "prompt"; # Never auto-runs a guessed command in agent lanes
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
      file-added-label = "";
      file-copied-label = "[==]";
      file-modified-label = "";
      file-removed-label = "";
      file-renamed-label = "";

      # Hunk headers
      hunk-header-style = "file line-number";
      hunk-header-decoration-style = "box";

      # Commit/blame styles
      commit-decoration-style = "bold box ul";
      commit-style = "raw";

      # Blame configuration
      blame-format = "{timestamp:<15} {author:<15.14} {commit:<8}";
      blame-palette = config.forge.theme.projections.blameRamp;
      blame-separator-format = "│{n:^4}│";
      blame-separator-style = "dim";
      blame-timestamp-output-format = "%Y-%m-%d %H:%M";

      # Diff styles: owner-derived fills tint the background and hold the
      # code foreground neutral; word-level emphasis is the same hue lifted.
      minus-style = "syntax ${config.forge.theme.roles.diff.del.hex}";
      minus-emph-style = "syntax bold ${config.forge.theme.roles.diff.delEmph.hex}";
      plus-style = "syntax ${config.forge.theme.roles.diff.add.hex}";
      plus-emph-style = "syntax bold ${config.forge.theme.roles.diff.addEmph.hex}";

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
      syntax-theme = "forge-dracula"; # Owner-generated bat theme; delta reads the bat cache
      true-color = "always";
      zero-style = "dim syntax";

      # Interactive features
      hyperlinks = true;
      hyperlinks-file-link-format = "vscode://file/{path}:{line}";
    };
  };
}
