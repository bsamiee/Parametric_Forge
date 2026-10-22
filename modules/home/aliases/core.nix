# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/core.nix
# ----------------------------------------------------------------------------
# Core register rows: system, files, monitoring, data, network, dev.
{
  "1password" = [
    ["opls" "op item list"]
    ["opg" "op item get"]
    ["opr" "op run --"]
    ["opi" "op inject -i"]
  ];
  actions = [
    ["actl" "act -l"]
  ];
  data = [
    ["sqlite3" "sqlite3 -column -header -nullvalue NULL"]
    ["jqi" "jnv"]
    ["fqd" "fq d"]
    ["c2j" "mlr --c2j cat"]
    ["j2c" "mlr --j2c cat"]
  ];
  dev = [
    ["watch" "watchexec -c"]
    ["watchr" "watchexec -r"]
    ["pc" "process-compose"]
    ["pdev" "pnpm dev"]
    ["pbuild" "pnpm build"]
    ["ptest" "pnpm test"]
    ["dnr" "dotnet run --"]
    ["dnw" "dotnet watch run --"]
    ["dnb" "dotnet build -c Release"]
    ["dnt" "dotnet test --logger 'console;verbosity=minimal'"]
  ];
  files = [
    ["ls" "eza -la --header --no-user --time-style=relative"]
    ["mkdir" "mkdir -pv"]
    ["rcmv" "rclone move --delete-empty-src-dirs"]
    ["yz" "yazi-dispatch.sh reveal"]
    ["yzd" "yazi-dispatch.sh cd"]
    ["cpsp" "rsync -ahPSX --"]
    ["backup" "rsync -ahPX --delete"]
    ["rsyncd" "rsync -ahPn"]
    ["rsyncf" "rsync -ahPX --append-verify"]
    ["rcs" "rclone sync --progress --transfers 4"]
    ["hex" "hexyl"]
    ["pack" "ouch compress"]
    ["unpack" "ouch decompress"]
  ];
  general = [
    ["cl" "clear"]
    ["vim" "nvim"]
    ["nv" "nvim"]
    ["ff" "fastfetch"]
  ];
  monitoring = [
    ["pst" "procs --tree"]
    ["psc" "procs --sortd cpu"]
    ["psmem" "procs --sortd mem"]
    ["psw" "procs --watch"]
    ["top" "btm"]
    ["load" "/usr/bin/top -l 2 -n 12 -o cpu -stats pid,command,cpu,mem,state | tail -n 24"]
    ["memhog" ''ps -axo rss=,comm= | awk '{n=$0; sub(/^ *[0-9]+ +/,"",n); sub(/.*\//,"",n); m[n]+=$1} END {for (c in m) printf "%7d MB  %s\n", m[c]/1024, c}' | sort -rn | head -n 20'' "Resident memory summed per program, top 20"]
    ["dfi" "dua i"]
    ["killi" "pik"]
  ];
  navigation = [
    ["cdr" "cd $(git rev-parse --show-toplevel)"]
    [".." "cd .."]
    ["..." "cd ../.."]
    ["...." "cd ../../.."]
    ["....." "cd ../../../.."]
    ["-" "cd -"]
  ];
  network = [
    ["xh" "xh --style=fruity"]
    ["http" "xh"]
    ["https" "xh --https"]
    ["POST" "xh POST"]
    ["PUT" "xh PUT"]
    ["tripu" "trip --udp --target-port 33434"]
    ["ohaj" "oha --no-tui --output-format json"]
    ["serve" "rclone serve http --addr :8000 ."]
    ["bw" "sudo bandwhich"]
    ["speedtestl" "speedtest --accept-license"]
    ["lssh" "sshs"]
    ["ports" "sudo lsof -iTCP -sTCP:LISTEN -n -P"]
  ];
  shell = [
    ["envs" "env | sort"]
    ["ezsh" "$EDITOR \${ZDOTDIR:-$HOME}/.zshrc"]
    ["rzsh" "source \${ZDOTDIR:-$HOME}/.zshrc"]
    ["reload" "exec $SHELL"]
  ];
  text-search = [
    ["chs" "choose"]
    ["batg" "batgrep"]
    ["tldru" "tldr --update"]
    ["rgx" "grex -xc"]
    ["rgxf" "grex -xc -f"]
    ["sr" "serpl"]
    ["mdv" "rich --markdown"]
  ];
  time = [
    ["timestamp" "date +'%Y%m%d_%H%M%S'"]
    ["epoch" "date +%s"]
    ["now" "date +'%Y-%m-%d %H:%M:%S'"]
    ["today" "date +'%Y-%m-%d'"]
    ["week" "date +%V"]
  ];
  zellij = [
    ["zjl" "zellij list-sessions"]
    ["zja" "zellij attach"]
  ];
}
