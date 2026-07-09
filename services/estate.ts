// Title         : estate.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/estate.ts
// ----------------------------------------------------------------------------
// Inline Pulumi program: folds topology rows into Doppler resources. Adoption
// of live CLI-born state rides the `import` resource option behind the adopt
// flag; retire/cutover rows leave the program when their keep flag drops and
// Pulumi destroys the live resource on the next up. This module is the Pulumi
// engine boundary: resource constructors are the engine's own registration
// calls and run inside the Automation API program context.

import * as doppler from "@pulumiverse/doppler";
import type { CustomResourceOptions, Resource } from "@pulumi/pulumi";
import { configs, environments, projects, tokens, type Disposition, type Origin } from "./topology.ts";

type EstateFlags = {
  readonly adopt: boolean;
  readonly keepRetired: boolean;
  readonly keepCutover: boolean;
};

const _admitted = (disposition: Disposition, f: EstateFlags): boolean =>
  disposition === "steady" ||
  (disposition === "retire" && f.keepRetired) ||
  (disposition === "cutover" && f.keepCutover);

const _options = (
  origin: Origin,
  importId: string,
  f: EstateFlags,
  dependsOn?: Resource,
): CustomResourceOptions => ({
  ...(f.adopt && origin === "adopt" ? { import: importId } : {}),
  ...(dependsOn ? { dependsOn } : {}),
});

const estate = (f: EstateFlags) => async (): Promise<Record<string, unknown>> => {
  const project = new Map<string, Resource>(
    projects
      .filter((row) => _admitted(row.disposition, f))
      .map((row) => [
        row.slug,
        // Only steady rows are shaped; retiring projects adopt live state untouched.
        new doppler.Project(
          row.slug,
          { name: row.slug, ...(row.disposition === "steady" ? { description: row.description } : {}) },
          {
            ..._options(row.origin, row.slug, f),
            ...(row.disposition === "steady" ? {} : { ignoreChanges: ["description"] }),
          },
        ),
      ] as const),
  );

  const environment = new Map<string, Resource>(
    environments
      .filter((row) => _admitted(row.disposition, f) && project.has(row.project))
      .map((row) => [
        `${row.project}.${row.slug}`,
        new doppler.Environment(
          `${row.project}-${row.slug}`,
          { project: row.project, slug: row.slug, name: row.name },
          _options(row.origin, `${row.project}.${row.slug}`, f, project.get(row.project)),
        ),
      ] as const),
  );

  const config = new Map<string, Resource>(
    configs
      .filter((row) => _admitted(row.disposition, f) && environment.has(`${row.project}.${row.environment}`))
      .map((row) => [
        `${row.project}.${row.name}`,
        new doppler.BranchConfig(
          `${row.project}-${row.name}`,
          { project: row.project, environment: row.environment, name: row.name },
          _options(row.origin, `${row.project}.${row.environment}.${row.name}`, f, environment.get(`${row.project}.${row.environment}`)),
        ),
      ] as const),
  );

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
