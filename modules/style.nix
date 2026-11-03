# Title         : style.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/style.nix
# ----------------------------------------------------------------------------
# House code-style vocabulary: plain data imported by both module graphs, so the sqruff configs and the flake's treefmt rows carry the width
# and indent the repository .editorconfig states. Width/indent are the single law; rendered fragments project from them.
let
  indent = 4;
  width = 150;
  i = toString indent;
  w = toString width;
in {
  inherit indent width;
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
