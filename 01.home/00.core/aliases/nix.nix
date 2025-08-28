# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/nix.nix
# ----------------------------------------------------------------------------
# Nix ecosystem aliases - unified namespace for all nix-related tools

{ lib, ... }:

let
  # --- Nix Commands (dynamically prefixed with 'n') ------------------------
  nixCommands = {
    # Core development
    b = "nom build";
    d = "nom develop";
    r = "nix run";

    # Package/profile management
    pi = "nix profile install";
    pr = "nix profile remove";
    pl = "nix profile list";
    pu = "nix profile upgrade";
    sh = "nix shell";
    prollback = "nix profile rollback";

    # Flake operations
    fu = "nix flake update";
    fc = "nix-fast-build --skip-cached --flake '.#checks'";
    fs = "nix flake show";
    fl = "nix flake lock";
    fli = "nix flake lock --update-input";
    fm = "nix flake metadata";

    # Development environments
    dp = "nix develop .#python";
    dd = "nix develop --command";
    di = "nix develop --impure";
    envrc = "echo 'use flake' > .envrc && direnv allow";

    # Darwin operations
    rb = "darwin-rebuild switch --flake .";
    rc = "darwin-rebuild switch --flake . && nix flake check";
    ru = "nix flake update && darwin-rebuild switch --flake .";
    rp = "darwin-rebuild build --flake .";
    rd = "darwin-rebuild build --flake . && nvd diff /run/current-system result";
    drrollback = "darwin-rebuild switch --rollback";

    # Home-manager operations
    hmb = "home-manager build --flake .";
    hms = "home-manager switch --flake .";
    hmg = "home-manager generations";
    hmp = "home-manager packages";
    hmn = "home-manager news";
    hme = "home-manager edit";
    hmrollback = "home-manager switch --rollback";
    hmexpire = "home-manager expire-generations '-30 days'";

    # Build variants
    fb = "nix-fast-build";
    fallback = "nix build --fallback";
    offline = "nix build --offline";
    debug = "nix build --log-format internal-json -v --print-build-logs --keep-failed |& nom --json";

    # Store inspection
    du = "nix-du";
    tree = "nix-tree";
    why = "nix-store --query --roots";
    size = "nix path-info --closure-size -h";
    find = "nix-locate --whole-name";
    index = "nix-index";

    # Diagnostics & debugging
    diff = "nix-diff";
    log = "nix log";
    repl = "nix repl";
    eval = "nix eval";
    show = "nix show-derivation";
    health = "nix-store --verify --check-contents";

    # Visualization & comparison
    vdiff = "nvd";
    viz = "f() { format=\${2:-png}; nix-visualize \"\$1\" -o \"\${3:-graph.\$format}\"; }; f";

    # Code quality & formatting
    fmt = "nixfmt";
    lint = "f() { deadnix --hidden --no-underscore --fail \"\${@:-.}\" && statix check \"\${@:-.}\"; }; f";
    lintf = "f() { deadnix --hidden --no-underscore --edit \"\${@:-.}\" && statix fix \"\${@:-.}\"; }; f";
    dead = "f() { deadnix --hidden --no-underscore \"\${@:-.}\"; }; f";
    deadf = "f() { deadnix --hidden --no-underscore --edit \"\${@:-.}\"; }; f";

    # Generation management
    gens = "darwin-rebuild --list-generations";
    gendiff = "f() { nvd diff \$(darwin-rebuild --list-generations | grep \"^\$1 \" | cut -d' ' -f2) \$(darwin-rebuild --list-generations | grep \"^\$2 \" | cut -d' ' -f2); }; f";
    genswitch = "f() { darwin-rebuild switch --switch-generation \"\$1\" --flake .; }; f";

    # Garbage collection & cleanup
    gc = "nix-collect-garbage -d";
    gcold = "nix-collect-garbage --delete-older-than 30d";
    gcinfo = "echo 'Store usage:' && df -h /nix/store && echo 'GC roots:' && nix-store --gc --print-roots | wc -l && echo 'Dead paths:' && nix-store --gc --print-dead 2>/dev/null | wc -l";

    # Store verification & repair
    verify = "nix-store --verify --check-contents";
    repair = "nix-store --verify --check-contents --repair";

    # Cache management
    cache = "cachix push";
    cstatus = "cachix use";
  };

in
{
  aliases = lib.mapAttrs' (name: value: {
    name = "n${name}";
    inherit value;
  }) nixCommands;
}