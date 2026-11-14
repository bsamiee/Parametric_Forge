import * as github from '@pulumi/github';
import type { CustomResourceOptions, Resource } from '@pulumi/pulumi';
import * as doppler from '@pulumiverse/doppler';
import { Topology } from './topology.ts';

declare namespace program {
    type Flags = { readonly adopt: boolean };
    type Registration<Row> = {
        readonly key: (row: Row) => string;
        readonly importId: (row: Row) => string;
        readonly anchor?: (row: Row) => Resource | undefined;
        readonly make: (row: Row, options: CustomResourceOptions) => Resource;
    };
}

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

const program = (f: program.Flags) => async (): Promise<Record<string, unknown>> => {
    const _registered = <Row extends { readonly origin: Topology.Origin }>(
        rows: ReadonlyArray<Row>,
        registration: program.Registration<Row>,
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

export { program };
