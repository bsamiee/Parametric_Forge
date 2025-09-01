# Title         : lib/build.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/build.nix
# ----------------------------------------------------------------------------
# Unified build and deployment with content-addressed efficiency

{ nixpkgs }:

let
  inherit (nixpkgs) lib;

  # --- Content Hash Generation ---------------------------------------------
  contentHash =
    path:
    if builtins.pathExists path then builtins.substring 0 8 (builtins.hashString "sha256" (toString path)) else "missing";

  manifestHash =
    manifests:
    builtins.substring 0 8 (
      builtins.hashString "sha256" (
        lib.concatStringsSep "-" (map (f: builtins.hashFile "sha256" f) (lib.filter builtins.pathExists manifests))
      )
    );

  # --- Executable Detection -----------------------------------------------
  isExecutable =
    filename: sourcePath:
    let
      # File extension patterns
      exts = [
        "sh"
        "bash"
        "zsh"
        "fish"
        "py"
        "rb"
        "pl"
        "lua"
        "js"
      ];

      # Known executable config file patterns (no extension)
      executableConfigs = [
        "sketchybarrc"
        "yabairc"
        "skhdrc"
        "bordersrc"
      ];

      # Check file extension
      hasExecExt = lib.any (ext: lib.hasSuffix ".${ext}" filename) exts;

      # Check known executable config names
      isExecConfig = lib.any (name: filename == name) executableConfigs;

      # Check for shebang pattern (if file exists and is readable)
      hasShebang =
        if builtins.pathExists sourcePath then
          let
            content = builtins.readFile sourcePath;
            firstLine = lib.head (lib.splitString "\n" content);
          in
          lib.hasPrefix "#!" firstLine
        else
          false;
    in
    hasExecExt || isExecConfig || hasShebang;

  # --- Build-Time Caching (Existing Logic) --------------------------------
  cached =
    _pkgs: drv: manifests:
    let
      key = manifestHash manifests;
    in
    drv.overrideAttrs (_: {
      version = "${drv.version or "0"}-${key}";
      __contentOptimized = true;
      meta = drv.meta or { } // {
        description = "${drv.pname or drv.name} (cached)";
      };
    });

  auto =
    pkgs: drv:
    let
      src = drv.src or null;
      manifests =
        if src != null && builtins.isPath src then
          lib.filter builtins.pathExists (
            map (p: "${src}/${p}") [
              "Cargo.toml"
              "Cargo.lock"
              "pyproject.toml"
              "poetry.lock"
              "package.json"
              "package-lock.json"
            ]
          )
        else
          [ ];
    in
    if manifests == [ ] then drv else cached pkgs drv manifests;

  # --- Deployment-Time Logic (From deploy.nix + Selective Enhancement) ----
  deployDirInternal =
    source: target:
    let
      processEntry =
        relPath: name: type:
        let
          sourcePath = "${source}/${relPath}";
          targetPath = "${target}/${relPath}";
        in
        if type == "directory" then
          processDir relPath
        else if type == "regular" then
          lib.nameValuePair targetPath (
            {
              source = sourcePath;
            }
            // lib.optionalAttrs (isExecutable name sourcePath) {
              executable = true;
            }
          )
        else
          { };

      processDir =
        relPath:
        let
          dirPath = if relPath == "" then source else "${source}/${relPath}";
          entries = builtins.readDir dirPath;
        in
        lib.mapAttrsToList (
          name: type:
          let
            newRelPath = if relPath == "" then name else "${relPath}/${name}";
          in
          processEntry newRelPath name type
        ) entries;
    in
    lib.listToAttrs (lib.flatten (processDir ""));

  # --- Selective Deployment (New Logic) -----------------------------------
  selectiveDeploy =
    source: target:
    let
      sourceHash = contentHash source;
      targetExists = builtins.pathExists target;
      targetHash = if targetExists then contentHash target else "";
      needsDeploy = sourceHash != targetHash || !targetExists;
    in
    if needsDeploy then deployDirInternal source target else { };

  # --- Binary Package Builder (From deploy.nix) ---------------------------
  mkBinPackage =
    {
      pkgs,
      source,
      name ? "scripts",
    }:
    if !builtins.pathExists source then
      null
    else
      let
        files = builtins.readDir source;
        scripts = lib.filterAttrs (n: t: t == "regular" && isExecutable n "${source}/${n}") files;
      in
      if scripts == { } then
        null
      else
        pkgs.runCommand name { } (
          ''
            mkdir -p $out/bin
          ''
          + lib.concatStrings (
            lib.mapAttrsToList (n: _: ''
              install -m 755 ${source}/${n} $out/bin/${n}
            '') scripts
          )
        );

in
{
  # --- Build-Time Caching (Backward Compatible API) ----------------------
  inherit cached auto;

  rust =
    pkgs: drv:
    let
      manifests = lib.filter builtins.pathExists [
        "${drv.src}/Cargo.toml"
        "${drv.src}/Cargo.lock"
      ];
    in
    if manifests == [ ] then drv else cached pkgs drv manifests;

  python =
    pkgs: drv:
    let
      manifests = lib.filter builtins.pathExists [
        "${drv.src}/pyproject.toml"
        "${drv.src}/poetry.lock"
      ];
    in
    if manifests == [ ] then drv else cached pkgs drv manifests;

  node =
    pkgs: drv:
    let
      manifests = lib.filter builtins.pathExists [
        "${drv.src}/package.json"
        "${drv.src}/package-lock.json"
      ];
    in
    if manifests == [ ] then drv else cached pkgs drv manifests;

  # --- Deployment Functions (Backward Compatible + Enhanced) --------------
  deployDir = deployDirInternal; # Keep existing behavior for compatibility
  inherit mkBinPackage;

  # --- New Selective Deployment -------------------------------------------
  inherit selectiveDeploy;

  # --- Utilities -----------------------------------------------------------
  inherit contentHash manifestHash isExecutable;
}
