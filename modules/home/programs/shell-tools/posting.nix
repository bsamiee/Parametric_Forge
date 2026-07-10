# Title         : posting.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/posting.nix
# ----------------------------------------------------------------------------
# Terminal API workspace with versionable request collections; the package row lives in the owner table. Theme is projected from the estate
# palette owner; user collections stay mutable state, while the forge-services collection is a generated probe surface over service-row
# credential NAMES — `forge-console` brokers values into a mode-600 launch-time env file, never a durable file.

{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette roles;
  yamlFormat = pkgs.formats.yaml {};

  # Credential custody coordinates; probe rows reference keys by name only.
  probeSources = {
    agent = {
      project = "agent-runtime";
      config = "dev";
    };
    machine = {
      project = "parametric-forge";
      config = "dev_machine";
    };
  };

  probes = [
    {
      name = "github-identity";
      description = "Authenticated GitHub identity behind the services PAT";
      method = "GET";
      url = "https://api.github.com/user";
      source = "agent";
      headers = [
        {
          name = "Authorization";
          value = "Bearer \${GITHUB_TOKEN}";
        }
        {
          name = "Accept";
          value = "application/vnd.github+json";
        }
      ];
    }
    {
      name = "github-rulesets";
      description = "Live main-guard ruleset state; compare against services/topology.ts";
      method = "GET";
      url = "https://api.github.com/repos/bsamiee/Parametric_Forge/rulesets";
      source = "agent";
      headers = [
        {
          name = "Authorization";
          value = "Bearer \${GITHUB_TOKEN}";
        }
        {
          name = "Accept";
          value = "application/vnd.github+json";
        }
      ];
    }
    {
      name = "doppler-config";
      description = "Doppler agent-runtime/dev config facts through the scoped MCP token";
      method = "GET";
      url = "https://api.doppler.com/v3/configs/config";
      source = "agent";
      params = [
        {
          name = "project";
          value = "agent-runtime";
        }
        {
          name = "config";
          value = "dev";
        }
      ];
      headers = [
        {
          name = "Authorization";
          value = "Bearer \${DOPPLER_MCP_AGENT_TOKEN}";
        }
      ];
    }
    {
      name = "greptile-index";
      description = "Greptile index currency for the Forge repo (status + sha)";
      method = "GET";
      url = "https://api.greptile.com/v2/repositories/github%3Amain%3Absamiee%2FParametric_Forge";
      source = "agent";
      headers = [
        {
          name = "Authorization";
          value = "Bearer \${GREPTILE_API_KEY}";
        }
        {
          name = "X-GitHub-Token";
          value = "\${GITHUB_TOKEN}";
        }
      ];
    }
    {
      name = "cachix-cache";
      description = "bsamiee cache metadata; narinfo proof lives with forge-redeploy";
      method = "GET";
      url = "https://app.cachix.org/api/v1/cache/bsamiee";
      source = "machine";
      headers = [
        {
          name = "Authorization";
          value = "Bearer \${CACHIX_AUTH_TOKEN}";
        }
      ];
    }
  ];

  collectionFiles = lib.listToAttrs (map (row: {
      name = "posting/collections/forge-services/${row.name}.posting.yaml";
      value.source = yamlFormat.generate "posting-${row.name}" {
        inherit (row) name description method url headers;
        params = row.params or [];
      };
    })
    probes);

  # Launch-time credential materialization: one env render per distinct custody coordinate, mode-600 tmpfile, removed on exit — no secret at rest.
  forgeConsole = pkgs.writeShellApplication {
    name = "forge-console";
    runtimeInputs = [pkgs.coreutils pkgs.doppler pkgs.posting];
    text = ''
      env_file="$(mktemp)"
      trap 'rm -f "$env_file"' EXIT
      ${lib.concatMapStringsSep "\n" (
        source: ''doppler secrets download --project ${source.project} --config ${source.config} --format env --no-file >>"$env_file"''
      ) (lib.unique (map (row: probeSources.${row.source}) probes))}
      posting --collection "${config.xdg.dataHome}/posting/collections/forge-services" --env "$env_file" "$@"
    '';
  };

  postingConfig = {
    theme = "forge";
    load_user_themes = true;
    watch_themes = false;
    theme_directory = "${config.xdg.dataHome}/posting/themes";
    use_host_environment = false; # request variables come from explicit --env files only
  };

  forgeTheme = {
    name = "forge";
    primary = roles.accent.primary.hex;
    secondary = roles.accent.structural.hex;
    accent = roles.accent.secondary.hex;
    background = roles.surface.base.hex;
    surface = roles.surface.raised.hex;
    error = roles.state.danger.hex;
    success = roles.state.success.hex;
    warning = roles.state.warning.hex;
    url = {
      base = palette.cyan.hex;
      protocol = palette.magenta.hex;
    };
    syntax = {
      json_key = palette.green.hex;
      json_string = palette.yellow.hex;
      json_number = palette.purple.hex;
      json_boolean = palette.magenta.hex;
      json_null = palette.comment.hex;
    };
    # HTTP-verb semantics: read=success green, create=accent cyan, mutate=attention orange (patch=warning yellow), destroy=danger red,
    # introspection (options/head)=structural purple / muted comment.
    method = {
      get = palette.green.hex;
      post = palette.cyan.hex;
      put = palette.orange.hex;
      patch = palette.yellow.hex;
      delete = palette.red.hex;
      options = palette.purple.hex;
      head = palette.comment.hex;
    };
    # Rich style strings; mirrors the tmTheme editor surface (caret=primary, line highlight=raised, selection=selected).
    text_area = {
      gutter = roles.text.muted.hex;
      cursor = "${roles.text.inverse.hex} on ${roles.text.primary.hex}";
      cursor_line = "on ${roles.surface.raised.hex}";
      cursor_line_gutter = "${roles.text.muted.hex} on ${roles.surface.raised.hex}";
      matched_bracket = "on ${roles.surface.selected.hex}";
      selection = "on ${roles.surface.selected.hex}";
    };
  };
in {
  home.packages = [forgeConsole];
  xdg.configFile."posting/config.yaml".source = yamlFormat.generate "posting-config" postingConfig;
  xdg.dataFile =
    {"posting/themes/forge.yaml".source = yamlFormat.generate "posting-forge-theme" forgeTheme;}
    // collectionFiles;
}
