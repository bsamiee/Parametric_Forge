# Title         : session-rows.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/session-rows.nix
# ----------------------------------------------------------------------------
# ONE `zellij list-sessions --no-formatting` parse, shared by every consumer so the text read cannot fork. The " [Created " anchor keeps
# space-bearing session names whole (first-word split is the anchorless fallback), and EXITED classifies on the detail alone, so a session NAMED
# "EXITED-x" never reads as dead. Consume under `jq -Rcn` with list-sessions output on stdin; a no-session exit 1 is benign.
''
  [inputs | select(length > 0)
   | ((capture("^(?<name>.*?) \\[Created (?<rest>.*)$") | {name, detail: ("[Created " + .rest)})
      // {name: (split(" ")[0]), detail: (sub("^\\S+ ?"; ""))})
   | {name, exited: (.detail | test("EXITED")),
      detail: (.detail | gsub("[\\x00-\\x1f]"; " "))}]''
