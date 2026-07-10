// Title         : driver.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/driver.ts
// ----------------------------------------------------------------------------
// Services-IaC boot module: Pulumi Automation API over a local file backend
// under XDG state, passphrase and Doppler token brokered from 1Password per
// invocation. Zero YAML on disk: the project manifest is synthesized into the
// workspace temp dir. Also owns the machine directory-scope rail (the
// replacement for per-repo doppler.yaml). Exports nothing; runMain terminates.
//
//   node services/driver.ts preview|up|refresh [--adopt] [--target=<p>/<c>/<token>]
//   node services/driver.ts outputs [name] [--reveal]
//   node services/driver.ts scopes apply|doctor|strict
//   node services/driver.ts reviewers

import { createHash } from 'node:crypto';
import { homedir } from 'node:os';
import * as path from 'node:path';
import { Command, FileSystem } from '@effect/platform';
import { NodeContext, NodeRuntime } from '@effect/platform-node';
import { LocalWorkspace, type Stack } from '@pulumi/pulumi/automation/index.js';
import { Array as Arr, Config, Console, Data, Effect, Option, Redacted, Schema, Stream } from 'effect';
import { estate } from './estate.ts';
import { Topology } from './topology.ts';

const PROJECT = 'forge-services';
const STACK = 'estate';

type Flags = {
    readonly adopt: boolean;
    readonly reveal: boolean;
    readonly targets: ReadonlyArray<string>;
};

class ShellFault extends Data.TaggedError('ShellFault')<{
    readonly command: string;
    readonly detail: string;
}> {
    override get message(): string {
        return `${this.command}: ${this.detail}`;
    }
}

class StackFault extends Data.TaggedError('StackFault')<{
    readonly operation: string;
    readonly detail: string;
}> {
    override get message(): string {
        return `stack ${this.operation}: ${this.detail}`;
    }
}

class UsageFault extends Data.TaggedError('UsageFault')<{
    readonly wanted: string;
}> {
    override get message(): string {
        return this.wanted;
    }
}

class ScopeFault extends Data.TaggedError('ScopeFault')<{
    readonly divergent: number;
    readonly strayScopes: number;
    readonly strayYaml: number;
}> {
    override get message(): string {
        return `scope rail divergent: rows=${this.divergent} strayScopes=${this.strayScopes} strayYaml=${this.strayYaml}`;
    }
}

const _run = (cmd: Command.Command, label: string) =>
    Effect.gen(function* () {
        const spawned = yield* Command.start(cmd);
        const [code, out, err] = yield* Effect.all(
            [spawned.exitCode, Stream.mkString(Stream.decodeText(spawned.stdout)), Stream.mkString(Stream.decodeText(spawned.stderr))],
            { concurrency: 3 },
        );
        return yield* code === 0
            ? Effect.succeed(out)
            : Effect.fail(
                  new ShellFault({
                      command: label,
                      detail: err.trim() || `exit ${code}`,
                  }),
              );
    }).pipe(
        Effect.scoped,
        Effect.mapError((fault) => (fault instanceof ShellFault ? fault : new ShellFault({ command: label, detail: String(fault) }))),
    );

const _shell = (command: string, ...args: ReadonlyArray<string>) => _run(Command.make(command, ...args), `${command} ${args.join(' ')}`);

// Webhook signing secrets brokered from their Doppler custody rows via the IaC
// token; values pass straight into the inline program as secret inputs.
const _webhookSecrets = (token: Redacted.Redacted<string>) =>
    Effect.map(
        Effect.forEach(
            Topology.webhooks,
            (row) =>
                Effect.map(
                    _run(
                        Command.make(
                            'doppler',
                            'secrets',
                            'get',
                            row.secretSource.name,
                            '--project',
                            row.secretSource.project,
                            '--config',
                            row.secretSource.config,
                            '--plain',
                        ).pipe(Command.env({ DOPPLER_TOKEN: Redacted.value(token) })),
                        `doppler secrets get ${row.secretSource.name} (${row.secretSource.project}/${row.secretSource.config})`,
                    ),
                    (raw) => [row.slug, raw.trim()] as const,
                ),
            { concurrency: 2 },
        ),
        (rows) => new Map(rows),
    );

// nonEmptyString: an empty exported override means unset, per XDG semantics.
const _settings = Config.all({
    passphraseRef: Config.withDefault(Config.nonEmptyString('FORGE_SERVICES_PASSPHRASE_REF'), 'op://Tokens/PULUMI_FORGE_SERVICES/password'),
    tokenRef: Config.withDefault(Config.nonEmptyString('FORGE_SERVICES_DOPPLER_TOKEN_REF'), 'op://Tokens/DOPPLER_IAC_TOKEN/token'),
    githubTokenRef: Config.withDefault(Config.nonEmptyString('FORGE_SERVICES_GITHUB_TOKEN_REF'), 'op://Tokens/Github Token/token'),
    stateDir: Config.nonEmptyString('FORGE_SERVICES_STATE_DIR').pipe(
        Config.orElse(() => Config.map(Config.nonEmptyString('XDG_STATE_HOME'), (root) => path.join(root, 'forge-services'))),
        Config.withDefault(path.join(homedir(), '.local', 'state', 'forge-services')),
    ),
    passphrase: Config.option(Config.redacted('PULUMI_CONFIG_PASSPHRASE')),
    token: Config.option(Config.redacted('DOPPLER_TOKEN')),
    githubToken: Config.option(Config.redacted('GITHUB_TOKEN')),
});

// Ambient env short-circuits 1Password; otherwise the op reference resolves per run.
const _brokered = (ambient: Option.Option<Redacted.Redacted<string>>, ref: string) =>
    Option.match(ambient, {
        onSome: (value) => Effect.succeed(value),
        onNone: () => Effect.map(_shell('op', 'read', ref), (raw) => Redacted.make(raw.trim())),
    });

const _openStack = (flags: Flags) =>
    Effect.gen(function* () {
        const cfg = yield* _settings;
        const fs = yield* FileSystem.FileSystem;
        yield* fs.makeDirectory(cfg.stateDir, { recursive: true });
        yield* fs.chmod(cfg.stateDir, 0o700);
        const [passphrase, token, githubToken] = yield* Effect.all(
            [_brokered(cfg.passphrase, cfg.passphraseRef), _brokered(cfg.token, cfg.tokenRef), _brokered(cfg.githubToken, cfg.githubTokenRef)],
            { concurrency: 3 },
        );
        const backendUrl = `file://${cfg.stateDir}`;
        const webhookSecrets = yield* _webhookSecrets(token);
        return yield* Effect.tryPromise({
            // BOUNDARY ADAPTER: Pulumi Automation API is promise-native; secrets unwrap
            // only into the engine's child process environment.
            try: () =>
                LocalWorkspace.createOrSelectStack(
                    {
                        stackName: STACK,
                        projectName: PROJECT,
                        program: estate(flags, webhookSecrets),
                    },
                    {
                        projectSettings: {
                            name: PROJECT,
                            runtime: 'nodejs',
                            backend: { url: backendUrl },
                        },
                        secretsProvider: 'passphrase',
                        envVars: {
                            PULUMI_CONFIG_PASSPHRASE: Redacted.value(passphrase),
                            PULUMI_BACKEND_URL: backendUrl,
                            DOPPLER_TOKEN: Redacted.value(token),
                            GITHUB_TOKEN: Redacted.value(githubToken),
                        },
                    },
                ),
            catch: (cause) => new StackFault({ operation: 'open', detail: String(cause) }),
        });
    });

const _stackAct = <A>(operation: string, flags: Flags, act: (stack: Stack) => Promise<A>) =>
    Effect.flatMap(_openStack(flags), (stack) =>
        Effect.tryPromise({
            try: () => act(stack),
            catch: (cause) => new StackFault({ operation, detail: String(cause) }),
        }),
    );

const _echo = (chunk: string): void => {
    process.stdout.write(chunk);
};

// --- [SCOPE_RAIL] ----------------------------------------------------------------------

type ScopeReport = {
    readonly dir: string;
    readonly declared: { readonly project: string; readonly config: string };
    readonly resolved: { readonly project: string; readonly config: string };
    readonly present: boolean;
    readonly ok: boolean;
};

const _ScopeTable = Schema.parseJson(
    Schema.Record({
        key: Schema.String,
        value: Schema.Record({ key: Schema.String, value: Schema.Unknown }),
    }),
);

// The doppler CLI emits enclave-prefixed keys; fromKey folds the rename into
// the decode and an absent key decodes as unset.
const _ScopePair = Schema.parseJson(
    Schema.Struct({
        project: Schema.optionalWith(Schema.String, { default: () => '' }).pipe(Schema.fromKey('enclave.project')),
        config: Schema.optionalWith(Schema.String, { default: () => '' }).pipe(Schema.fromKey('enclave.config')),
    }),
);

const _scopeTable = Effect.flatMap(_shell('doppler', 'configure', '--all', '--json'), Schema.decodeUnknown(_ScopeTable));

const _resolved = (dir: string) =>
    Effect.flatMap(_shell('doppler', 'configure', 'get', 'project', 'config', '--json', '--scope', dir), Schema.decodeUnknown(_ScopePair));

const _strayScopes = Effect.map(_scopeTable, (table) => {
    const declared = new Set<string>(Topology.scopes.map((row) => row.dir));
    return Object.entries(table)
        .filter(
            ([dir, entry]) =>
                dir.startsWith(`${Topology.scopeRoot}/`) && !declared.has(dir) && ('enclave.project' in entry || 'enclave.config' in entry),
        )
        .map(([dir]) => dir);
});

const _strayYaml = Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem;
    const entries = yield* fs.readDirectory(Topology.scopeRoot);
    const candidates = [
        path.join(Topology.scopeRoot, 'doppler.yaml'),
        ...entries.map((entry) => path.join(Topology.scopeRoot, entry, 'doppler.yaml')),
    ];
    // Plain files under scopeRoot yield ENOTDIR on the probe; absence either way.
    const present = yield* Effect.forEach(candidates, (candidate) => Effect.orElseSucceed(fs.exists(candidate), () => false), {
        concurrency: 8,
    });
    return candidates.filter((_, index) => present[index] === true);
});

const _doctor = Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem;
    const rows = yield* Effect.forEach(
        Topology.scopes,
        (row) =>
            Effect.gen(function* () {
                const present = yield* fs.exists(row.dir);
                const resolved = yield* present ? _resolved(row.dir) : Effect.succeed({ project: '', config: '' });
                return {
                    dir: row.dir,
                    declared: { project: row.project, config: row.config },
                    resolved,
                    present,
                    ok: present && resolved.project === row.project && resolved.config === row.config,
                } satisfies ScopeReport;
            }),
        { concurrency: 4 },
    );
    const [strayScopes, strayYaml] = yield* Effect.all([_strayScopes, _strayYaml], { concurrency: 2 });
    return {
        rows,
        strayScopes,
        strayYaml,
        ok: rows.every((row) => row.ok) && strayScopes.length === 0 && strayYaml.length === 0,
    };
});

// Applies declared rows for existing directories, then unsets stray rows under
// scopeRoot; never touches scope `/`, never sets a token, never parses the CLI
// config file directly.
const _applyScopes = Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem;
    const rows = yield* Effect.filter(Topology.scopes, (row) => fs.exists(row.dir), { concurrency: 4 });
    yield* Effect.forEach(
        rows,
        (row) => _shell('doppler', 'configure', 'set', `project=${row.project}`, `config=${row.config}`, '--scope', row.dir),
        { concurrency: 1 },
    );
    const strays = yield* _strayScopes;
    yield* Effect.forEach(strays, (dir) => _shell('doppler', 'configure', 'unset', 'project', 'config', '--scope', dir), {
        concurrency: 1,
    });
});

const _printed = Effect.flatMap(_doctor, (report) => Effect.map(Console.log(JSON.stringify(report, null, 2)), () => report));

const _scopeVerbs = {
    apply: Effect.flatMap(_applyScopes, () => Effect.asVoid(_printed)),
    doctor: Effect.asVoid(_printed),
    strict: Effect.flatMap(_printed, (report) =>
        report.ok
            ? Effect.void
            : Effect.fail(
                  new ScopeFault({
                      divergent: report.rows.filter((row) => !row.ok).length,
                      strayScopes: report.strayScopes.length,
                      strayYaml: report.strayYaml.length,
                  }),
              ),
    ),
} as const;

// --- [REVIEWER_MATRIX] -----------------------------------------------------------------

type ReviewerRepo = {
    readonly repo: string;
    readonly present: boolean;
    readonly configHash: string;
};

// App identities hash their repo-owned artifacts per repo root; ruleset-native
// identities hash the desired rule policy once — drift shows up as a hash
// change on either side, never as prose. The digest fold is the node:crypto
// boundary kernel.
const _artifactHash = (root: string, artifacts: readonly string[]) =>
    Effect.map(
        Effect.flatMap(FileSystem.FileSystem, (fs) =>
            Effect.forEach(
                artifacts,
                (artifact) => {
                    const file = path.join(root, artifact);
                    return Effect.flatMap(
                        Effect.orElseSucceed(fs.exists(file), () => false),
                        (exists) => (exists ? Effect.map(fs.readFile(file), Option.some) : Effect.succeed(Option.none<Uint8Array>())),
                    );
                },
                { concurrency: 3 },
            ),
        ),
        (bodies) => {
            const found = Arr.getSomes(bodies);
            return {
                present: artifacts.length > 0 && found.length === artifacts.length,
                hash: Arr.isNonEmptyArray(found)
                    ? found
                          .reduce((digest, body) => digest.update(body), createHash('sha256'))
                          .digest('hex')
                          .slice(0, 16)
                    : '',
            };
        },
    );

const _reviewerMatrix = Effect.gen(function* () {
    const policyHash = createHash('sha256').update(JSON.stringify(Topology.rulesetPolicy)).digest('hex').slice(0, 16);
    const rows = yield* Effect.forEach(
        Topology.reviewers,
        (row) =>
            Effect.map(
                Effect.forEach(
                    Topology.scopes,
                    (scope) =>
                        row.mechanism === 'ruleset'
                            ? Effect.succeed({
                                  repo: path.basename(scope.dir),
                                  present: row.posture === 'active',
                                  configHash: row.posture === 'active' ? policyHash : '',
                              } satisfies ReviewerRepo)
                            : Effect.map(
                                  _artifactHash(scope.dir, row.artifacts),
                                  (proof) =>
                                      ({
                                          repo: path.basename(scope.dir),
                                          present: proof.present,
                                          configHash: proof.hash,
                                      }) satisfies ReviewerRepo,
                              ),
                    { concurrency: 3 },
                ),
                (repos) => ({
                    identity: row.identity,
                    mechanism: row.mechanism,
                    posture: row.posture,
                    trigger: row.trigger,
                    statusCheck: row.statusCheck,
                    overlapClass: row.overlapClass,
                    repos,
                }),
            ),
        { concurrency: 2 },
    );
    // Gated identities prove ABSENCE; active identities prove presence on every repo root.
    const ok = rows.every((row) => (row.posture === 'gated' ? row.repos.every((repo) => !repo.present) : row.repos.every((repo) => repo.present)));
    return { reviewers: rows, ok };
});

// --- [ENTRY] ---------------------------------------------------------------------------

const USAGE =
    'forge-services driver\n' +
    '  preview|up|refresh [--adopt] [--target=<project>/<config>/<token>]\n' +
    '  outputs [name] [--reveal]\n' +
    '  scopes apply|doctor|strict\n' +
    '  reviewers';

const FLAG_VOCABULARY = new Set(['--adopt', '--reveal']);

const _flags = (argv: ReadonlyArray<string>): Flags => ({
    adopt: argv.includes('--adopt'),
    reveal: argv.includes('--reveal'),
    targets: argv.filter((arg) => arg.startsWith('--target=')).map((arg) => arg.slice('--target='.length)),
});

// Remint rail: a token coordinate maps onto its ServiceToken URN so drop/restore
// applies touch nothing else even when the estate carries unrelated drift.
const _tokenUrn = (coordinate: string): string =>
    `urn:pulumi:${STACK}::${PROJECT}::doppler:index/serviceToken:ServiceToken::${coordinate.split('/').join('-')}`;

const _targeted = (flags: Flags): { readonly target?: string[] } => (flags.targets.length === 0 ? {} : { target: flags.targets.map(_tokenUrn) });

const _verbs = {
    preview: (flags: Flags, _positional: ReadonlyArray<string>) =>
        Effect.flatMap(
            _stackAct('preview', flags, (stack) => stack.preview({ diff: true, onOutput: _echo, ..._targeted(flags) })),
            (result) => Console.log(JSON.stringify(result.changeSummary ?? {})),
        ),
    up: (flags: Flags, _positional: ReadonlyArray<string>) =>
        Effect.flatMap(
            _stackAct('up', flags, (stack) => stack.up({ onOutput: _echo, ..._targeted(flags) })),
            (result) => Console.log(JSON.stringify(result.summary.resourceChanges ?? {})),
        ),
    refresh: (flags: Flags, _positional: ReadonlyArray<string>) =>
        Effect.asVoid(_stackAct('refresh', flags, (stack) => stack.refresh({ onOutput: _echo, ..._targeted(flags) }))),
    outputs: (flags: Flags, positional: ReadonlyArray<string>) =>
        Effect.flatMap(
            _stackAct('outputs', flags, (stack) => stack.outputs()),
            (outputs) => {
                const selected = positional[1];
                if (selected === undefined) {
                    return Effect.forEach(
                        Object.entries(outputs),
                        ([name, value]) => Console.log(`${name}\t${value.secret ? '<secret>' : String(value.value)}`),
                        { concurrency: 1, discard: true },
                    );
                }
                const match = outputs[`token:${selected}`] ?? outputs[selected];
                return match === undefined
                    ? Effect.fail(new UsageFault({ wanted: `no output named ${selected}` }))
                    : match.secret && !flags.reveal
                      ? Console.log('secret output; pass --reveal for one-time handoff')
                      : Console.log(String(match.value));
            },
        ),
    scopes: (_flags2: Flags, positional: ReadonlyArray<string>) => {
        const sub = positional[1];
        return sub !== undefined && sub in _scopeVerbs
            ? _scopeVerbs[sub as keyof typeof _scopeVerbs]
            : Effect.fail(new UsageFault({ wanted: USAGE }));
    },
    reviewers: (_flags2: Flags, _positional: ReadonlyArray<string>) =>
        Effect.flatMap(_reviewerMatrix, (matrix) => Console.log(JSON.stringify(matrix, null, 2))),
} as const;

const _program = Effect.gen(function* () {
    const argv = process.argv.slice(2);
    const positional = argv.filter((arg) => !arg.startsWith('--'));
    const stray = argv.find((arg) => arg.startsWith('--') && !FLAG_VOCABULARY.has(arg) && !arg.startsWith('--target='));
    const flags = _flags(argv);
    const malformed = flags.targets.find((coordinate) => coordinate.split('/').length !== 3);
    const verb = positional[0];
    const handler = verb !== undefined && verb in _verbs ? _verbs[verb as keyof typeof _verbs] : undefined;
    return yield* stray !== undefined
        ? Effect.fail(new UsageFault({ wanted: `unknown flag ${stray}\n${USAGE}` }))
        : malformed !== undefined
          ? Effect.fail(
                new UsageFault({
                    wanted: `--target wants <project>/<config>/<token>, got ${malformed}`,
                }),
            )
          : handler === undefined
            ? Effect.fail(new UsageFault({ wanted: USAGE }))
            : handler(flags, positional);
});

NodeRuntime.runMain(Effect.provide(_program, NodeContext.layer));
