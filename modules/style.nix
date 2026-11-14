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
  sqruff = ''
    [sqruff]
    max_line_length = ${w}

    [sqruff:indentation]
    tab_space_size = ${i}
  '';
}
