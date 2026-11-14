{pkgs, ...}: let
  svgoConfig = pkgs.writeText "svgo.config.mjs" ''
    export default {
      multipass: true,
      js2svg: { eol: "lf", finalNewline: true },
      plugins: [
        {
          name: "preset-default",
          params: {
            overrides: {
              mergePaths: false,
              removeHiddenElems: false,
              cleanupIds: false,
              collapseGroups: false,
              removeEditorsNSData: false,
              convertShapeToPath: false,
              convertPathData: { floatPrecision: 3, transformPrecision: 4, makeArcs: false, forceAbsolutePath: false },
            },
          },
        },
      ],
    };
  '';
  svgo = pkgs.symlinkJoin {
    inherit (pkgs.svgo) pname version meta;
    paths = [pkgs.svgo];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/svgo" --add-flags "--config ${svgoConfig}"
    '';
  };
in {
  home.packages = [svgo];
}
