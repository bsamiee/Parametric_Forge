let
  indent = 4;
  width = 150;
  i = toString indent;
  w = toString width;
in {
  inherit indent width;
  sqruff = ''
    [sqruff]
    max_line_length = ${w}

    [sqruff:indentation]
    tab_space_size = ${i}
  '';
}
