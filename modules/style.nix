# Title         : style.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/style.nix
# ----------------------------------------------------------------------------
# House code-style vocabulary: plain data imported by both module graphs, so the home editorconfig and sqruff configs and the flake's treefmt
# rows carry identical width and indent. Width/indent are the single law; rendered fragments project from them.
let
  indent = 4;
  width = 150;
  i = toString indent;
  w = toString width;
in {
  inherit indent width;
  # Machine-level editor law as Home Manager editorconfig.settings sections: the [*] block is the whole contract — per-repo .editorconfig
  # files layer on top and win via nearest-first resolution.
  editorconfig = {
    "*" = {
      charset = "utf-8";
      end_of_line = "lf";
      insert_final_newline = true;
      trim_trailing_whitespace = true;
      indent_style = "space";
      indent_size = indent;
      max_line_length = width;
    };
    "*.{sh,bash}".switch_case_indent = true;
    "{Makefile,*.mk,*.go}".indent_style = "tab";
  };
  yamlfmt = ''
    formatter:
        type: basic
        indent: ${i}
        retain_line_breaks_single: true
        trim_trailing_whitespace: true
        eof_newline: true
  '';
  # sqruff config per dialect.
  sqruff = dialect: ''
    [sqruff]
    dialect = ${dialect}
    max_line_length = ${w}

    [sqruff:indentation]
    tab_space_size = ${i}
  '';
}
