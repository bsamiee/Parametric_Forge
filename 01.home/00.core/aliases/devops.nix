# Title         : devops.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/devops.nix
# ----------------------------------------------------------------------------
# DevOps aliases - Docker, Colima, Kubernetes, and container orchestration

{ lib, ... }:

let
  # --- Docker Commands (dynamically prefixed with 'd') ---------------------
  dockerCommands = {
    # Container management
    ps = "ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}'";
    i = "images";
    r = "run --rm -it";
    e = "f() { docker exec -it \$1 sh -c 'bash || zsh || sh'; }; f";

    # Container operations
    manage = "!f() { action=\${1:-status}; shift; case \$action in status) docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}' ;; stop) docker stop \${@:-\$(docker ps -q)} ;; rm) docker rm \${@:-\$(docker ps -aq -f status=exited)} ;; rmi) docker rmi \${@:-\$(docker images -q -f dangling=true)} ;; clean) docker container prune -f && docker image prune -f ;; *) echo 'Usage: dmanage [status|stop|rm|rmi|clean] [args]' ;; esac; }; f";

    # Logs and inspection
    l = "f() { docker logs -f --tail=50 --timestamps \${@}; }; f";
    inspect = "f() { docker inspect \$1 | jq '.[0] | {State, Config: {Image, Cmd, Env}}'; }; f";
    stats = "stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemPerc}}'";

    # Development workflows
    dev = "f() { docker run --rm -it -v \$(pwd):/workspace -w /workspace \${1:-node:alpine} \${@:2}; }; f";
    debug = "f() { docker run --rm -it --pid=container:\$1 --cap-add SYS_PTRACE alpine sh; }; f";
    trace = "f() { docker events --filter container=\$1 & docker logs -f \$1; }; f";

    # Build operations
    b = "build -t";
    build = "f() { docker buildx build --cache-from type=local,src=/tmp/.buildx-cache --cache-to type=local,dest=/tmp/.buildx-cache,mode=max -t \${1:-app} .; }; f";

    # Dockerfile linting
    lint = "f() { hadolint --format tty \${@:-Dockerfile*} 2>/dev/null || hadolint \${@:-Dockerfile}; }; f";

    # Quality & diagnostics
    qa = "f() { docker system df && echo && docker ps -a --filter 'status=exited' | head -20; }; f";
    qaf = "f() { docker container prune -f && docker image prune -f && docker builder prune -f; }; f";

    # Cleanup operations
    prune = "system prune -f";
    clean = "system prune -af --volumes && docker builder prune -af";

    # Volume operations
    v = "volume ls";
    vprune = "volume prune -f";

    # Network operations
    n = "network ls";
    nprune = "network prune -f";
  };

  # --- Docker Compose Commands (prefixed with 'dc') ------------------------
  composeCommands = {
    # Core operations
    up = "f() { docker compose up -d && docker compose logs -f --tail=10; }; f";
    down = "down";
    ps = "ps";

    # Smart workflows
    restart = "f() { docker compose restart \${1} && docker compose logs -f --tail=20 \${1}; }; f";
    cycle = "f() { docker compose down && docker compose up -d && docker compose logs -f --tail=20; }; f";
    rebuild = "f() { docker compose build --no-cache && docker compose up -d --force-recreate; }; f";

    # Development operations
    exec = "f() { docker compose exec \$1 sh -c 'bash || zsh || sh'; }; f";
    test = "f() { docker compose run --rm test \${@} && docker compose down; }; f";
    watch = "f() { watch -n 2 'docker compose ps && echo && docker compose top'; }; f";

    # Environment management
    stage = "f() { docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d; }; f";
    prod = "f() { docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d; }; f";

    # Maintenance
    logs = "f() { docker compose logs -f --tail=50 --timestamps \${@}; }; f";
    pull = "pull";
    build = "build";
  };

  # --- Colima Commands (prefixed with 'col') -------------------------------
  colimaCommands = {
    # Core operations
    start = "f() { colima start \${1:+--profile \$1} --cpu 4 --memory 8 --disk 100; }; f";
    stop = "stop";
    status = "f() { colima status && echo && colima list; }; f";
    ssh = "ssh";

    # Profile management
    profile = "f() { colima start --profile \${1:-default} --cpu 4 --memory 8; }; f";
    switch = "f() { colima stop && colima start --profile \$1; }; f";

    # Specialized profiles
    m1 = "start --arch aarch64 --vm-type=vz --vz-rosetta --cpu 4 --memory 8";
    k8s = "start --profile k8s --kubernetes --cpu 6 --memory 12";
    test = "start --profile test --cpu 2 --memory 4";

    # Maintenance
    clean = "delete --force";
    restart = "f() { colima stop && colima start; }; f";
  };

in
{
  aliases =
    # Docker aliases with 'd' prefix
    lib.mapAttrs' (name: value: {
      name = "d${name}";
      value = if lib.hasPrefix "f()" value then value else "docker ${value}";
    }) dockerCommands
    # Docker Compose aliases with 'dc' prefix
    // lib.mapAttrs' (name: value: {
      name = "dc${name}";
      value = "docker compose ${value}";
    }) composeCommands
    # Colima aliases with 'col' prefix
    // lib.mapAttrs' (name: value: {
      name = "col${name}";
      value = "colima ${value}";
    }) colimaCommands
    // {
      # Standalone shortcuts
      d = "docker";
      dc = "docker compose";
      col = "colima";

      # Docker system info
      dinfo = "docker system df";
      dversion = "docker version --format 'Client: {{.Client.Version}}\nServer: {{.Server.Version}}'";

      # Container management tools (moved from core.nix)
      lzd = "lazydocker"; # Docker TUI
      ctop = "ctop"; # Container top
      dive = "dive"; # Docker image explorer

      # Cross-tool integrations
      port-what = "f() { pid=\$(lsof -ti:\$1 2>/dev/null); [[ -n \$pid ]] && ps -p \$pid || docker ps --filter \"publish=\$1\" --format \"table {{.Names}}\t{{.Image}}\t{{.Ports}}\"; }; f"; # Enhanced port detection with Docker fallback
      net-debug = "f() { echo '=== Local Listening Ports ==='; lsof -iTCP -sTCP:LISTEN -n -P | head -10; echo -e '\n=== Docker Networks ==='; docker network ls 2>/dev/null || echo 'Docker not running'; echo -e '\n=== Active Network Connections ==='; lsof -i -n -P | grep ESTABLISHED | head -5; }; f"; # Network debugging overview
    };
}
