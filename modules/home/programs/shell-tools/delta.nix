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
    enable = true;  # Required for delta to be installed

    delta = {
      enable = true;

    options = {
      features = "decorations";
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

      # Diff styles
      minus-style = "syntax";
      minus-emph-style = "syntax bold";
      plus-style = "syntax";
      plus-emph-style = "syntax bold";

      # UI elements
      keep-plus-minus-markers = false;
      syntax-theme = "base16";
      true-color = "always";
      zero-style = "dim syntax";

      # Interactive features
      hyperlinks = true;
      hyperlinks-file-link-format = "vscode://file/{path}:{line}";
    };
  };

    extraConfig = {
      merge.conflictStyle = "diff3";
      diff.colorMoved = "default";
    };
  };
}
