# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# mise owner: per-repo runtime and task contract, settings-only global config. Nix keeps PATH truth — no activation, no shims; agents discover
# tasks with `mise tasks --json` and execute with `mise run`. Auto-install stays off in every form: a missing tool is a typed failure, never a
# mid-command download. Trust covers the estate roots only, so a foreign checkout's config never executes implicitly.
# Estate task rows project as gitignored `mise.local.toml` machine-local files at each repo root: a repo-committed `mise.toml` composes freely
# underneath (tools, env, its own tasks), and a same-name collision resolves to the machine row — estate verbs are machine truth.
{pkgs, ...}: let
  toml = pkgs.formats.toml {};

  # One row per estate repo: repo-root-relative home.file target -> task table. A new repo or verb is one row here.
  estateTasks = {
    "Documents/99.Github/Parametric_Forge" = {
      deploy = {
        description = "Switch this machine, then prove it: forge-redeploy + forge-accept";
        run = ["forge-redeploy --os darwin --host macbook --switch" "forge-accept"];
      };
      check = {
        description = "Static gate: both host toplevels eval";
        run = "nix flake check --no-build";
      };
      fmt = {
        description = "Format gate over the repo";
        run = "fmt --check .";
      };
    };
    "Documents/99.Github/Rasm" = {
      check = {
        description = "Polyglot quality gate: assay diagnose + build per language";
        run = "uv run python -m tools.assay static";
      };
      typecheck = {
        description = "TypeScript workspace typecheck (tsgo + tsc)";
        run = "pnpm run typecheck";
      };
    };
    "Documents/99.Github/Maghz" = {
      up = {
        description = "Local stack bring-up ladder: up, schema apply, schema doctor";
        run = ["uv run python -m admin up" "uv run python -m admin schema apply" "uv run python -m admin schema doctor"];
      };
      health = {
        description = "Typed health probe";
        run = "uv run python -m admin health";
      };
    };
  };
  localManifests = pkgs.lib.mapAttrs' (repo: tasks:
    pkgs.lib.nameValuePair "${repo}/mise.local.toml" {
      source = toml.generate "mise-local.toml" {inherit tasks;};
    })
  estateTasks;
in {
  home.packages = [pkgs.mise];
  home.file = localManifests;
  xdg.configFile."mise/config.toml".source = toml.generate "mise-config.toml" {
    settings = {
      trusted_config_paths = ["~/Documents/99.Github"];
      auto_install = false;
      not_found_auto_install = false;
      exec_auto_install = false;
      experimental = true; # monorepo task paths
      disable_hints = ["*"];
      status = {
        show_env = false;
        show_tools = false;
      };
    };
  };
}
