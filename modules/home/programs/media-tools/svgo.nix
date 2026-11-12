# Title         : svgo.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/svgo.nix
# ----------------------------------------------------------------------------
# SVG optimizer with its machine-wide default config. svgo has no global config location: it takes `--config`, else walks from the working
# directory up to the filesystem root for svgo.config.js, .mjs, or .cjs (lib/svgo-node.js loadConfig), so the file at the home root is the
# default for every folder under home and a nearer project file wins.
{pkgs, ...}: {
  home.packages = [pkgs.svgo];

  # Rows differ from preset-default: the four plugins switched off keep separate paths, hidden elements, ids, and basic shapes as drawn, so
  # an optimized drawing stays editable and its references resolve; path data keeps three decimals, transforms four, and no arc conversion.
  home.file."svgo.config.mjs".text = ''
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
              convertShapeToPath: false,
              convertPathData: { floatPrecision: 3, transformPrecision: 4, makeArcs: false, forceAbsolutePath: false },
            },
          },
        },
      ],
    };
  '';
}
