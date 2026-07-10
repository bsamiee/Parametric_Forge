# Title         : gh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/gh.nix
# ----------------------------------------------------------------------------
# GitHub CLI: declarative config.yml, hosts.yml stays mutable for auth state; headless auth is env-token owned (GH_TOKEN via the secrets
# rail), so a store-symlinked config.yml loses nothing. gh is operator/discovery/breakglass only: durable GitHub state (repo settings,
# rulesets, reviewer rules) lives in services/ Pulumi rows, and `gh api` mutation of surfaces a row owns is retired.

_: {
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      spinner = "enabled";
      pager = "delta";
      telemetry = "disabled";
    };
  };
}
