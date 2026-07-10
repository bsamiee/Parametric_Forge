# Title         : style.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/style.nix
# ----------------------------------------------------------------------------
# House code-style vocabulary: plain data imported by both module graphs, so
# XDG fallback configs (home), treefmt rows (flake), and never-shadow wrapper
# kernels carry identical bytes. Width/indent are the single law; rendered
# fragments and the discovery kernel project from them.
let
  indent = 4;
  width = 150;
  i = toString indent;
  w = toString width;
in {
  inherit indent width;
  indentString = builtins.concatStringsSep "" (builtins.genList (_: " ") indent);
  yamlfmt = ''
    formatter:
        type: basic
        indent: ${i}
        retain_line_breaks_single: true
        trim_trailing_whitespace: true
        eof_newline: true
  '';
  # sqruff and sqlfluff share one config grammar modulo the section prefix.
  sql = tool: dialect: ''
    [${tool}]
    dialect = ${dialect}
    max_line_length = ${w}

    [${tool}:indentation]
    tab_space_size = ${i}
  '';
  # Never-shadow discovery kernel: _walk_up <name>... prints the first
  # governing project config from $PWD up to and including the filesystem
  # root, exit 1 when none owns the tree. Wrappers embed it so every upward
  # walk shares one correctness.
  walkUp = ''
    _walk_up() {
        local dir="$PWD" name
        while :; do
            for name in "$@"; do
                [[ -f "$dir/$name" ]] && {
                    printf '%s\n' "$dir/$name"
                    return 0
                }
            done
            [[ "$dir" == /* && -n "''${dir%/}" ]] || return 1
            dir="''${dir%/*}"
            [[ -n "$dir" ]] || dir="/"
        done
    }
  '';
}
