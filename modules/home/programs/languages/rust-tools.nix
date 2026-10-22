# Title         : rust-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/rust-tools.nix
# ----------------------------------------------------------------------------
# Cargo's user configuration, read by every cargo run on the machine from any directory. The toolchain is each project's rust-toolchain.toml,
# installed through rustup by mise's rust backend, never a machine package.
{config, ...}: {
  # One build directory serves every workspace that names none of its own, so a crate compiled once (same version, features, profile, flags, and
  # toolchain) is reused by every other workspace in place of a rebuild, and a workspace's target directory holds only its final artifacts.
  # A workspace with its own `build.build-dir` keeps it. Nightly cargo locks each unit under `fine-grain-locking`, so concurrent builds sharing
  # the directory proceed together; stable cargo ignores the `[unstable]` table and locks the whole directory for each build. `cargo clean`
  # empties the whole shared directory, a finished project deletes its own target directory alone.
  programs.cargo = {
    enable = true;
    package = null;
    settings = {
      build.build-dir = "${config.xdg.cacheHome}/cargo/build";
      unstable.fine-grain-locking = true;
    };
  };
}
