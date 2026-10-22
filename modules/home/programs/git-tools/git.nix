# Title         : git.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/git.nix
# ----------------------------------------------------------------------------
# Git identity, op-backed SSH signing, workflow settings, delta
{
  config,
  host,
  lib,
  ...
}: let
  inherit (config.forge.theme) roles projections;
  # Delta output routinely pipes to files and CI logs, so its git-state rows take the ASCII twin register, never the terminal glyph.
  git = projections.gitHex;
  # One universal identity; the one key (in the Personal vault, the hosts/context.nix ssh.publicKey without its comment)
  # authenticates and signs. op-ssh-sign resolves it by public key through the 1Password agent seam in shell-tools/1password.nix.
  identity = {
    name = "Bardia Samiee";
    email = "b.samiee93@gmail.com";
    publicKey = lib.concatStringsSep " " (lib.take 2 (lib.splitString " " host.ssh.publicKey));
  };
  # Principal table for local `git log --show-signature` verification.
  trustedPrincipals = [identity.email];
in {
  programs.git = {
    enable = true;

    # Machine-wide excludes for macOS noise; each repo's .gitignore names its own outputs.
    ignores = [".DS_Store"];

    # allowedSigners lands the $XDG_CONFIG_HOME/git/allowed_signers file and the gpg.ssh.allowedSignersFile row through the module.
    signing = {
      key = "key::${identity.publicKey}";
      format = "ssh";
      signByDefault = true;
      signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      allowedSigners =
        lib.concatMapStrings
        (principal: "${principal} namespaces=\"git\" ${identity.publicKey}\n")
        trustedPrincipals;
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

      core.fsmonitor = true; # git's built-in fsmonitor daemon feeds the untracked cache manyFiles turns on

      feature.manyFiles = true; # index.version 4, index.skipHash, and the untracked cache

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
        writeCommitGraph = true; # Update commit graph cache on fetch
      };

      branch = {
        sort = "-committerdate";
        autosetupmerge = "always";
      };

      rebase = {
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
      help.autocorrect = "prompt"; # Never auto-runs a guessed command in agent lanes
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    # Rows differ from delta's defaults (`delta --show-config` under an empty HOME); the tmTheme rides bat's cache.
    options = {
      navigate = true;
      side-by-side = true;

      # Line numbers: minus/plus lanes carry the owner git-state hues.
      line-numbers = true;
      line-numbers-minus-style = git.deleted.color;
      line-numbers-plus-style = git.added.color;
      line-numbers-zero-style = "dim";
      line-numbers-left-format = "{nm:>4}⋮";
      line-numbers-right-format = "{np:>4}│";

      # File headers: state labels are the ASCII twins, so a piped diff carries state in text; copied folds into the rename family (identity move).
      file-style = "bold";
      file-decoration-style = "none";
      file-added-label = git.added.ascii;
      file-copied-label = git.renamed.ascii;
      file-modified-label = git.modified.ascii;
      file-removed-label = git.deleted.ascii;
      file-renamed-label = git.renamed.ascii;

      # Hunk headers
      hunk-header-style = "file line-number";
      hunk-header-decoration-style = "box";

      # Commit/blame styles
      commit-decoration-style = "bold box ul";

      # Blame configuration
      blame-palette = projections.blameRamp;
      blame-separator-style = "dim";
      blame-timestamp-output-format = "%Y-%m-%d %H:%M";

      # Diff styles: owner-derived fills tint the background and hold the code foreground neutral; word-level emphasis is the same hue lifted.
      minus-style = "syntax ${roles.diff.del.hex}";
      minus-emph-style = "syntax bold ${roles.diff.delEmph.hex}";
      plus-style = "syntax ${roles.diff.add.hex}";
      plus-emph-style = "syntax bold ${roles.diff.addEmph.hex}";

      # Grep integration
      grep-output-type = "ripgrep";
      grep-match-line-style = "syntax";
      grep-match-word-style = "bold magenta";
      grep-file-style = "blue bold";

      # Advanced diff features
      word-diff-regex = "\\w+|[^[:space:]]";
      relative-paths = true;

      # UI elements
      syntax-theme = "forge-dracula"; # bat theme from shell-tools/bat.nix; delta reads the bat cache
      true-color = "always";
      zero-style = "dim syntax";

      # Interactive features
      hyperlinks = true;
      hyperlinks-file-link-format = "file://{path}:{line}"; # WezTerm's open-uri handler routes file:line links to the quick-edit float
    };
  };
}
