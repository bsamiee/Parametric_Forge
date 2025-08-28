# Title         : rust.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/rust.nix
# ----------------------------------------------------------------------------
# Rust development aliases - unified namespace for all rust-related tools

{ lib, ... }:

let
  # --- Rust Commands (dynamically prefixed with 'r') -----------------------
  rustCommands = {
    # Core development
    b = "cargo build";
    c = "cargo check";
    t = "cargo test";
    r = "cargo run";

    # Code quality
    fmt = "cargo fmt";
    fix = "cargo clippy --fix && cargo fmt";

    # Testing & coverage
    test = "f() { if command -v cargo-nextest &>/dev/null; then cargo nextest run \"\$@\"; else cargo test \"\$@\"; fi; }; f";
    cov = "f() { if command -v cargo-tarpaulin &>/dev/null; then cargo tarpaulin --out html \"\$@\"; else echo 'Coverage requires devshell: rdl'; fi; }; f";

    # Development workflow
    watch = "f() { cargo watch -x \"\${1:-check}\" \"\${@:2}\"; }; f";
    expand = "cargo expand";

    # Dependency management
    deps = "f() { case \"\$1\" in add|rm|up) cargo \"\$@\" ;; *) cargo tree \"\$@\" ;; esac; }; f";
    audit = "cargo audit && cargo deny check";
    clean = "cargo machete && cargo outdated";

    # Documentation
    doc = "f() { cargo doc \"\${@:---open}\"; }; f";

    # Project management
    new = "f() { cargo \"\${2:-new}\" \"\$1\" \"\${@:3}\"; }; f";

    # Advanced tools
    bacon = "bacon";
    perf = "f() { if command -v cargo-flamegraph &>/dev/null; then cargo flamegraph \"\$@\"; else echo 'Profiling requires devshell: rdl'; fi; }; f";
    size = "cargo bloat --release";

    # WebAssembly
    wasm = "f() { if command -v wasm-pack &>/dev/null; then wasm-pack \"\${1:-build}\" \"\${@:2}\"; else echo 'WebAssembly requires devshell: rdl'; fi; }; f";

    # Quality assurance workflows
    qa = "cargo fmt && cargo clippy && cargo test";
    ci = "cargo fmt --check && cargo clippy -- -D warnings && cargo test";
    release = "cargo build --release";

    # Development environment
    dl = "nix develop .#rust";
  };

in
{
  aliases = lib.mapAttrs' (key: value: lib.nameValuePair "r${key}" value) rustCommands;
}
