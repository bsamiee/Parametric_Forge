// Title         : estate.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/estate.ts
// ----------------------------------------------------------------------------
// Inline Pulumi program: folds topology rows into Doppler and GitHub
// resources. Adoption of live CLI/gh-born state rides the `import` resource
// option behind the adopt flag; a row deleted from topology.ts is destroyed
// by Pulumi on the next up. This module is the Pulumi engine boundary:
// resource constructors are the engine's own registration calls inside the
// Automation API program context.

import * as doppler from "@pulumiverse/doppler";
import * as github from "@pulumi/github";
import { secret } from "@pulumi/pulumi";
import type { CustomResourceOptions, Resource } from "@pulumi/pulumi";
import {
  configs,
  environments,
  projects,
  repositories,
  rulesetPolicy,
  rulesets,
  tokens,
  webhooks,
  type Origin,
} from "./topology.ts";

type EstateFlags = {
  readonly adopt: boolean;
};

const GITHUB_OWNER = "bsamiee";

// Uniform repo policy: merge hygiene plus the live feature-surface booleans —
// unspecified booleans would plan as removals against adopted state.
const _mergeHygiene = {
  allowMergeCommit: false,
  allowSquashMerge: true,
  allowRebaseMerge: true,
  deleteBranchOnMerge: true,
  hasWiki: false,
  hasIssues: true,
  hasProjects: true,
  hasDownloads: true,
} as const;

const _options = (
  origin: Origin,
  importId: string,
  f: EstateFlags,
  dependsOn?: Resource,
): CustomResourceOptions => ({
  ...(f.adopt && origin === "adopt" ? { import: importId } : {}),
  ...(dependsOn ? { dependsOn } : {}),
});

const estate = (
  f: EstateFlags,
  webhookSecrets: ReadonlyMap<string, string> = new Map(),
) => async (): Promise<Record<string, unknown>> => {
  const project = new Map<string, Resource>(
    projects.map((row) => [
      row.slug,
      new doppler.Project(
        row.slug,
        { name: row.slug, description: row.description },
        _options(row.origin, row.slug, f),
      ),
    ] as const),
  );

  const environment = new Map<string, Resource>(
    environments.map((row) => [
      `${row.project}.${row.slug}`,
      new doppler.Environment(
        `${row.project}-${row.slug}`,
        { project: row.project, slug: row.slug, name: row.name },
        _options(row.origin, `${row.project}.${row.slug}`, f, project.get(row.project)),
      ),
    ] as const),
  );

  const config = new Map<string, Resource>(
    configs.map((row) => [
      `${row.project}.${row.name}`,
      new doppler.BranchConfig(
        `${row.project}-${row.name}`,
        { project: row.project, environment: row.environment, name: row.name },
        _options(row.origin, `${row.project}.${row.environment}.${row.name}`, f, environment.get(`${row.project}.${row.environment}`)),
      ),
    ] as const),
  );

  // Change-notification webhooks: the signing secret arrives driver-brokered
  // from its Doppler custody row and lands engine-side as a secret input; an
  // absent broker value plans the webhook unsigned-diff-free by omission.
  for (const row of webhooks) {
    const brokered = webhookSecrets.get(row.slug);
    void new doppler.Webhook(
      row.slug,
      {
        project: row.project,
        url: row.url,
        enabled: true,
        enabledConfigs: [...row.enabledConfigs],
        payload: row.payload,
        ...(brokered === undefined ? {} : { secret: secret(brokered) }),
      },
      _options(row.origin, row.slug, f, config.get(`${row.project}.${row.enabledConfigs[0]}`)),
    );
  }

  // GitHub settings surface: token rides the engine env (GITHUB_TOKEN, driver-
  // brokered); repositories carry protect so a row edit can never cascade into
  // repo destruction; rulesets adopt by `<repository>:<id>`.
  const gh = new github.Provider("github", { owner: GITHUB_OWNER });
  const repository = new Map<string, Resource>(
    repositories.map((row) => [
      row.name,
      new github.Repository(
        row.name,
        { name: row.name, description: row.description, ..._mergeHygiene },
        {
          provider: gh,
          protect: true,
          ...(f.adopt && row.origin === "adopt" ? { import: row.name } : {}),
        },
      ),
    ] as const),
  );
  for (const row of rulesets) {
    const anchor = repository.get(row.repository);
    void new github.RepositoryRuleset(
      `${row.repository}-${row.name}`,
      {
        name: row.name,
        repository: row.repository,
        target: "branch",
        enforcement: "active",
        conditions: { refName: { includes: ["~DEFAULT_BRANCH"], excludes: [] } },
        rules: rulesetPolicy,
      },
      {
        provider: gh,
        ...(anchor === undefined ? {} : { dependsOn: anchor }),
        ...(f.adopt && row.origin === "adopt" ? { import: `${row.repository}:${row.importId}` } : {}),
      },
    );
  }

  return Object.fromEntries(
    tokens
      .filter((row) => config.has(`${row.project}.${row.config}`) || project.has(row.project))
      .map((row) => {
        // Root-config tokens anchor on their environment (same-slug root config
        // exists once the environment does); branch-config tokens on their config row.
        const anchor = config.get(`${row.project}.${row.config}`) ??
          environment.get(`${row.project}.${row.config}`) ??
          project.get(row.project);
        const token = new doppler.ServiceToken(
          `${row.project}-${row.config}-${row.name}`,
          { project: row.project, config: row.config, name: row.name, access: row.access },
          { ...(anchor ? { dependsOn: anchor } : {}) },
        );
        return [`token:${row.project}/${row.config}/${row.name}`, token.key] as const;
      }),
  );
};

// --- [EXPORTS] ------------------------------------------------------------------

export { estate };
export type { EstateFlags };
