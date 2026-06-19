# Title         : catalog.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa/catalog.nix
# ----------------------------------------------------------------------------
# Public check-name catalog.
_: {
  perSystem = _: {
    _module.args.forgeRequiredCheckNames = [
      "formatting"
      "nix-unit"
      "nix-static"
      "forge-provision-shell"
      "forge-provision-help"
      "forge-provision-self-test"
      "forge-provision-readonly"
      "forge-provision-extensions-readonly"
      "forge-provision-pgduckdb-readonly"
      "forge-provision-bats"
      "duckdb-smoke"
      "duckdb-extension-smoke"
      "sqlite-extension-smoke"
      "forge-provision-assets"
      "forge-new-tool-smoke"
    ];
  };
}
