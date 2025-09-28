# Title         : delta.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/delta.nix
# ----------------------------------------------------------------------------
# Syntax-highlighting pager for git diffs

{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    delta = {
      enable = true;

      # --- Delta Configuration ----------------------------------------------
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
        file-added-label = "[+]";
        file-copied-label = "[==]";
        file-modified-label = "[*]";
        file-removed-label = "[-]";
        file-renamed-label = "[->]";

        # Hunk headers
        hunk-header-style = "file line-number";
        hunk-header-decoration-style = "box";

        # Commit/blame styles
        commit-decoration-style = "bold box ul";
        commit-style = "raw";

        # Blame configuration
        blame-format = "{timestamp:<15} {author:<15.14} {commit:<8}";
        blame-palette = "#2e3440 #3b4252 #434c5e #4c566a";
        blame-separator-format = "│{n:^4}│";
        blame-separator-style = "dim";
        blame-timestamp-output-format = "%Y-%m-%d %H:%M";

        # Diff styles
        minus-style = "syntax";
        minus-emph-style = "syntax bold";
        plus-style = "syntax";
        plus-emph-style = "syntax bold";

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
        syntax-theme = "Dracula";  # Match bat theme
        true-color = "always";
        zero-style = "dim syntax";

        # Interactive features
        hyperlinks = true;
        hyperlinks-file-link-format = "vscode://file/{path}:{line}";
      };
    };

    extraConfig = {
      # interactive.diffFilter is set automatically by delta module
      merge.conflictStyle = "zdiff3";  # Better than diff3
      diff.colorMoved = "default";
    };
  };
}
