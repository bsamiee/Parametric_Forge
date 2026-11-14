{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) roles projections;
  git = projections.gitHex;
  identity = {
    name = "Bardia Samiee";
    email = "b.samiee93@gmail.com";
    publicKey = lib.concatStringsSep " " (lib.take 2 (lib.splitString " " host.ssh.publicKey));
  };
  trustedPrincipals = [identity.email];
  idmlText = pkgs.writeShellApplication {
    name = "idml-text";
    runtimeInputs = [pkgs.unzip pkgs.yq-go];
    text = ''
      unzip -Z1 "$1" | LC_ALL=C sort | while IFS= read -r member; do
        printf '== %s\n' "$member"
        [[ $member != *.xml ]] || unzip -p "$1" "$member" | yq -p xml -o xml
      done
    '';
  };
  textconv = {
    pdf = "sh -c '${lib.getExe' pkgs.poppler-utils "pdftotext"} -layout \"$1\" -' textconv";
    exif = lib.getExe pkgs.exiftool;
    idml = lib.getExe idmlText;
  };
in {
  programs.git = {
    enable = true;
    package = pkgs.git-current;

    ignores = [".DS_Store"];
    attributes = ["*.pdf diff=pdf" "*.psd diff=exif" "*.idml diff=idml"];

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

      pull.rebase = true;

      push = {
        default = "current";
        autoSetupRemote = true;
        followTags = true;
      };

      diff =
        {
          algorithm = "histogram";
          colorMoved = "default";
          submodule = "log";
        }
        // lib.mapAttrs (_: command: {
          textconv = command;
          cachetextconv = true;
        })
        textconv;

      merge = {
        conflictstyle = "zdiff3";
        ff = false;
      };

      fetch = {
        prune = true;
        prunetags = true;
        writeCommitGraph = true;
        parallel = 0;
        followRemoteHEAD = "always";
      };

      submodule.fetchJobs = 0;

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
        submoduleSummary = true;
      };

      log.date = "iso";

      column.ui = "auto";
      tag.sort = "version:refname";

      commit.verbose = true;
      rerere.enabled = true;

      alias = {
        dft = "-c diff.external=difft diff";
        dlog = "-c diff.external=difft log -p --ext-diff";
        dshow = "-c diff.external=difft show --ext-diff";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    options = {
      navigate = true;
      side-by-side = true;

      line-numbers = true;
      line-numbers-minus-style = git.deleted.color;
      line-numbers-plus-style = git.added.color;
      line-numbers-zero-style = "dim";
      line-numbers-left-format = "{nm:>4}⋮";
      line-numbers-right-format = "{np:>4}│";

      file-style = "bold";
      file-decoration-style = "none";
      file-added-label = git.added.ascii;
      file-copied-label = git.renamed.ascii;
      file-modified-label = git.modified.ascii;
      file-removed-label = git.deleted.ascii;
      file-renamed-label = git.renamed.ascii;

      hunk-header-style = "file line-number";
      hunk-header-decoration-style = "box";

      commit-decoration-style = "bold box ul";

      blame-palette = projections.blameRamp;
      blame-separator-style = "dim";
      blame-timestamp-output-format = "%Y-%m-%d %H:%M";

      minus-style = "syntax ${roles.diff.del.hex}";
      minus-emph-style = "syntax bold ${roles.diff.delEmph.hex}";
      plus-style = "syntax ${roles.diff.add.hex}";
      plus-emph-style = "syntax bold ${roles.diff.addEmph.hex}";

      grep-output-type = "ripgrep";
      grep-match-line-style = "syntax";
      grep-match-word-style = "bold magenta";
      grep-file-style = "blue bold";

      word-diff-regex = "\\w+|[^[:space:]]";
      relative-paths = true;

      syntax-theme = "forge-dracula";
      true-color = "always";
      zero-style = "dim syntax";

      hyperlinks = true;
      hyperlinks-file-link-format = "vscode://file/{path}:{line}";
    };
  };
}
