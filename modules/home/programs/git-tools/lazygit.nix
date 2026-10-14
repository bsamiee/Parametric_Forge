# Title         : lazygit.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/lazygit.nix
# ----------------------------------------------------------------------------
# Lazygit TUI configuration themed from the estate palette owner
{config, ...}: let
  inherit (config.estate.theme) palette roles;
in {
  programs.lazygit = {
    enable = true;

    # Rows differ from lazygit's defaults (`lazygit --config`).
    settings = {
      gui = {
        # --- [DISPLAY_SETTINGS]
        showCommandLog = false;
        showBottomLine = false;
        showBranchCommitHash = true;
        showDivergenceFromBaseBranch = "arrowAndNumber";
        nerdFontsVersion = "3";

        # File-status glyphs are lazygit-built-in NFv3 (not themable — the tool-owned-glyph exception beside eza); the themable git-state
        # surface is color, and unstaged-worktree reads the owner modified hue.
        theme = {
          activeBorderColor = [palette.magenta.hex "bold"];
          inactiveBorderColor = [palette.cyan.hex];
          searchingActiveBorderColor = [palette.yellow.hex "bold"];
          optionsTextColor = [palette.cyan.hex];
          selectedLineBgColor = [palette.selection.hex];
          defaultFgColor = [palette.foreground.hex];
          unstagedChangesColor = [roles.git.modified.color.hex];
          cherryPickedCommitFgColor = [palette.cyan.hex];
          cherryPickedCommitBgColor = [palette.purple.hex];
          markedBaseCommitFgColor = [palette.yellow.hex];
          markedBaseCommitBgColor = [palette.purple.hex];
        };
      };

      git = {
        # --- [DIFF_RENDERER_DELTA_INSIDE_LAZYGIT_PANES]
        # Delta inherits its [delta] git-config options; --paging=never is the in-pane requirement and --navigate does not work inside lazygit.
        # stdinFilter pipes `git diff --color=<colorArg>` through the command; lazygit 0.65 reads git.diffRenderers, and the retired git.pagers
        # and git.paging spellings trigger its config migration, an in-place rewrite that cannot land on a store symlink.
        diffRenderers = [
          {
            type = "stdinFilter";
            name = "delta";
            colorArg = "always";
            command = "delta --paging=never";
          }
        ];

        mainBranches = ["main" "master" "develop" "dev"];
      };

      # Preset owns edit/editAtLine/openDirInEditor ({{filename}}/{{line}} are the only template vars); the darwin platform default owns open/openLink.
      os.editPreset = "nvim"; # Matches EDITOR from programs.neovim.defaultEditor

      # Store-managed binary: self-update writes are impossible.
      update.method = "never";

      disableStartupPopups = true;
    };
  };
}
