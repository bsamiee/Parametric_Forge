# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Package overlays
final: prev: {
  carbon-now-cli = prev.carbon-now-cli.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        cli="$out/lib/node_modules/carbon-now-cli/dist/cli.js"
        if [ -f "$cli" ]; then
          substituteInPlace "$cli" \
            --replace-fail "assert { type: 'json' }" "with { type: 'json' }"
        fi
      '';
  });
  duckdb = prev.callPackage ./duckdb {};
  # The CLI overlay above has no source tree or pythonHash; python duckdb
  # (harlequin's engine) keeps the nixpkgs source-built duckdb lineage.
  pythonPackagesExtensions =
    (prev.pythonPackagesExtensions or [])
    ++ [
      (_pyFinal: pyPrev: {
        duckdb = pyPrev.duckdb.override {inherit (prev) duckdb;};
      })
    ];
  energyplus = prev.callPackage ./energyplus {};
  forge-provision = final.callPackage ./forge-provision {};
  google-cloud-sdk =
    if prev.stdenv.hostPlatform.system == "aarch64-darwin"
    then
      prev.google-cloud-sdk.overrideAttrs (_old: rec {
        version = "574.0.0";
        src = prev.fetchurl {
          url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${version}-darwin-arm.tar.gz";
          hash = "sha256-HdK5rnWc8aZDd8Tk4VIwPAtC04qNOtq8OVTNLpw6YqM=";
        };
        doInstallCheck = true;
        installCheckPhase = ''
          export HOME=$(mktemp -d)

          gcloud_version="$($out/bin/gcloud version --format json | ${prev.jq}/bin/jq -r '."Google Cloud SDK"')"
          test "$gcloud_version" = "${version}"

          gsutil_version="$($out/bin/gsutil version | sed -n 's/^gsutil version: //p')"
          expected_gsutil_version="$(cat "$out/google-cloud-sdk/platform/gsutil/VERSION")"
          test "$gsutil_version" = "$expected_gsutil_version"
        '';
      })
    else prev.google-cloud-sdk;
  nodejs-bin_26 = final.callPackage ./nodejs-bin {};
  openstudio = prev.callPackage ./openstudio {};
  pnpm = final.pnpm_11;
  pnpm_11 = import ./pnpm {
    inherit (prev) fetchurl pnpm_11;
    inherit (final) nodejs-bin_26;
  };
  sqlite-forge = final.callPackage ./sqlite-forge {};
  sqlean = prev.callPackage ./sqlean {};
}
