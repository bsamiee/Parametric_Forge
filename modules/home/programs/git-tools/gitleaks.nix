# Title         : gitleaks.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/gitleaks.nix
# ----------------------------------------------------------------------------
# Machine-global gitleaks policy. Markdown, logs, text, and test trees are
# fully scanned - they are the highest-probability paste channels. Only
# generated artifacts that cannot carry authored secrets are allowlisted.
{pkgs, ...}: let
  tomlFormat = pkgs.formats.toml {};

  gitleaksConfig = {
    title = "Forge machine gitleaks policy";
    extend.useDefault = true;

    allowlists = [
      {
        description = "Generated lockfiles and dependency forests";
        paths = [
          ''(^|/)(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|deno\.lock)$''
          ''(^|/)(Cargo\.lock|flake\.lock|uv\.lock|poetry\.lock|Gemfile\.lock|composer\.lock)$''
          ''(^|/)(Package\.resolved|packages\.lock\.json|gradle\.lockfile|go\.sum)$''
          ''(^|/)(node_modules|dist|build|target|\.direnv)/''
        ];
      }
      {
        description = "Nix store hashes are content addresses, not credentials";
        condition = "AND";
        regexTarget = "line";
        paths = [''\.nix$''];
        regexes = [''/nix/store/[a-z0-9]{32}-''];
      }
    ];
  };
in {
  home.packages = [pkgs.gitleaks];
  xdg.configFile."gitleaks/gitleaks.toml".source =
    tomlFormat.generate "gitleaks-config" gitleaksConfig;
}
