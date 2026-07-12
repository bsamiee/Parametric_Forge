// Title         : estate.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/estate.ts
// ----------------------------------------------------------------------------
// Inline Pulumi program: one parameterized registration fold materializes every topology row family into Doppler and GitHub resources. Adoption of
// live CLI/gh-born state rides the `import` option behind the adopt flag; a row dropped from topology.ts is destroyed by Pulumi on the next up. This
// module is the Pulumi engine boundary: resource constructors are the engine's own registration calls inside the Automation API program context.

import * as github from '@pulumi/github';
import type { CustomResourceOptions, Resource } from '@pulumi/pulumi';
import { secret } from '@pulumi/pulumi';
import * as doppler from '@pulumiverse/doppler';
import { Redacted } from 'effect';
import { Topology } from './topology.ts';

declare namespace estate {
    type Flags = { readonly adopt: boolean };
    type Registration<Row> = {
        readonly key: (row: Row) => string;
        readonly importId: (row: Row) => string;
        readonly anchor?: (row: Row) => Resource | undefined;
        readonly make: (row: Row, options: CustomResourceOptions) => Resource;
    };
}

// Uniform repo policy: merge hygiene plus live feature-surface booleans; deprecated provider inputs stay unbound.
const _mergeHygiene = {
    allowAutoMerge: true,
    allowMergeCommit: false,
    allowSquashMerge: true,
    allowRebaseMerge: true,
    allowUpdateBranch: true,
    deleteBranchOnMerge: true,
    squashMergeCommitTitle: 'PR_TITLE',
    squashMergeCommitMessage: 'PR_BODY',
    hasWiki: false,
    hasIssues: true,
    hasProjects: false,
} as const;

const estate =
    (f: estate.Flags, webhookSecrets: Readonly<Record<string, Redacted.Redacted<string>>> = {}) =>
    // BOUNDARY ADAPTER: promise-native Pulumi registration program — statements and the JS Map registries live only inside this kernel.
    async (): Promise<Record<string, unknown>> => {
        // One fold owns every row family: key, import identity, dependency anchor, and constructor arrive as registration columns.
        const _registered = <Row extends { readonly origin: Topology.Origin }>(
            rows: ReadonlyArray<Row>,
            registration: estate.Registration<Row>,
        ): ReadonlyMap<string, Resource> =>
            new Map(
                rows.map((row) => {
                    const anchor = registration.anchor?.(row);
                    return [
                        registration.key(row),
                        registration.make(row, {
                            ...(f.adopt && row.origin === 'adopt' ? { import: registration.importId(row) } : {}),
                            ...(anchor ? { dependsOn: anchor } : {}),
                        }),
                    ] as const;
                }),
            );

        const project = _registered(Topology.projects, {
            key: (row) => row.slug,
            importId: (row) => row.slug,
            make: (row, options) => new doppler.Project(row.slug, { name: row.slug, description: row.description }, options),
        });

        const environment = _registered(Topology.environments, {
            key: (row) => `${row.project}.${row.slug}`,
            importId: (row) => `${row.project}.${row.slug}`,
            anchor: (row) => project.get(row.project),
            make: (row, options) =>
                new doppler.Environment(`${row.project}-${row.slug}`, { project: row.project, slug: row.slug, name: row.name }, options),
        });

        const config = _registered(Topology.configs, {
            key: (row) => `${row.project}.${row.name}`,
            importId: (row) => `${row.project}.${row.environment}.${row.name}`,
            anchor: (row) => environment.get(`${row.project}.${row.environment}`),
            make: (row, options) =>
                new doppler.BranchConfig(
                    `${row.project}-${row.name}`,
                    {
                        project: row.project,
                        environment: row.environment,
                        name: row.name,
                    },
                    options,
                ),
        });

        // The signing secret arrives driver-brokered sealed from its Doppler custody row and unwraps only into the engine's secret input;
        // an absent broker value plans the webhook unsigned-diff-free, and the payload event generates from the row's own coordinates;
        // anchoring falls back to the environment when the first enabled config is a root.
        void _registered(Topology.webhooks, {
            key: (row) => row.slug,
            importId: (row) => row.slug,
            anchor: (row) => config.get(`${row.project}.${row.enabledConfigs[0]}`) ?? environment.get(`${row.project}.${row.enabledConfigs[0]}`),
            make: (row, options) => {
                const brokered = webhookSecrets[row.slug];
                return new doppler.Webhook(
                    row.slug,
                    {
                        project: row.project,
                        url: row.url,
                        enabled: true,
                        enabledConfigs: [...row.enabledConfigs],
                        payload: JSON.stringify({ event: `${row.project}.${row.enabledConfigs[0]}.secrets.update` }),
                        ...(brokered === undefined ? {} : { secret: secret(Redacted.value(brokered)) }),
                    },
                    options,
                );
            },
        });

        // GitHub settings surface: the token rides the engine env (driver-brokered GITHUB_TOKEN); repositories carry protect so a row edit
        // can never cascade into repo destruction; rulesets adopt by `<repository>:<id>`.
        const gh = new github.Provider('github', { owner: Topology.owner });
        const repository = _registered(Topology.repositories, {
            key: (row) => row.name,
            importId: (row) => row.name,
            make: (row, options) =>
                new github.Repository(
                    row.name,
                    { name: row.name, description: row.description, ..._mergeHygiene },
                    { provider: gh, protect: true, ...options },
                ),
        });

        void _registered(Topology.rulesets, {
            key: (row) => `${row.repository}-${row.name}`,
            importId: (row) => `${row.repository}:${row.importId}`,
            anchor: (row) => repository.get(row.repository),
            make: (row, options) =>
                new github.RepositoryRuleset(
                    `${row.repository}-${row.name}`,
                    {
                        name: row.name,
                        repository: row.repository,
                        target: 'branch',
                        enforcement: 'active',
                        conditions: {
                            refName: { includes: ['~DEFAULT_BRANCH'], excludes: [] },
                        },
                        rules: Topology.rulesetPolicy,
                    },
                    { provider: gh, ...options },
                ),
        });

        return Object.fromEntries(
            Topology.tokens.map((row) => {
                // A token coordinate is compile-proven against declared rows: branch-config tokens anchor on their config row,
                // root-config tokens on their environment (same-slug root config).
                const anchor = config.get(`${row.project}.${row.config}`) ?? environment.get(`${row.project}.${row.config}`);
                const token = new doppler.ServiceToken(
                    `${row.project}-${row.config}-${row.name}`,
                    {
                        project: row.project,
                        config: row.config,
                        name: row.name,
                        access: row.access,
                    },
                    { ...(anchor ? { dependsOn: anchor } : {}) },
                );
                return [`token:${row.project}/${row.config}/${row.name}`, token.key] as const;
            }),
        );
    };

// --- [EXPORTS] -------------------------------------------------------------------------

export { estate };
