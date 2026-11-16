{
  lib,
  lld,
  rustPlatform,
  data,
}: let
  manifest = lib.importTOML ./Cargo.toml;
in
  rustPlatform.buildRustPackage {
    pname = manifest.package.name;
    inherit (manifest.package) version;
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [./Cargo.toml ./Cargo.lock ./main.rs ./view.rs];
    };
    cargoLock.lockFile = ./Cargo.lock;
    nativeBuildInputs = [lld];
    env = {
      RUSTFLAGS = "-C linker=wasm-ld";
      STATUSBAR_DATA = "${data}";
    };
    preBuild = ''
      export RUSTFLAGS="$RUSTFLAGS --remap-path-prefix=$NIX_BUILD_TOP=/build"
    '';
    meta = {
      description = "Zellij status bars: tabs, needs-you notice, agent and command counts, session, and mode hints";
      license = lib.licenses.mit;
      platforms = lib.platforms.wasi;
    };
  }
