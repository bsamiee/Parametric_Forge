// Title         : driver.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/driver.ts
// ----------------------------------------------------------------------------
// Services-IaC boot module: Pulumi Automation API over a local file backend under XDG state, with 1Password brokering only the
// Pulumi passphrase and Doppler IaC credential. The GitHub credential resolves from Doppler. Zero YAML on disk: the project
// manifest synthesizes into the workspace temp dir. Also applies the machine's Doppler directory scopes. Exports nothing; runMain terminates.

import { homedir } from 'node:os';
import * as path from 'node:path';
import { NodeRuntime, NodeServices } from '@effect/platform-node';
import { LocalWorkspace, type Stack } from '@pulumi/pulumi/automation/index.js';
import { Array as Arr, Config, Console, Data, Effect, FileSystem, HashSet, Option, Record, Redacted, Result, Schema, Stream, Struct } from 'effect';
import { ChildProcess } from 'effect/process';
import { program } from './program.ts';
import { Topology } from './topology.ts';

// --- [CONSTANTS] -----------------------------------------------------------------------

const PROJECT = 'services';
const STACK = 'forge';

// Host seam: the home-relative scope rows resolve onto the operator home once, here, so topology.ts carries no machine path.
const _scopeRoot = path.join(homedir(), Topology.scopeRoot);
const _scopes = Arr.map(Topology.scopes, (row) => ({ ...row, dir: path.join(_scopeRoot, row.dir) }));

// --- [TYPES] ---------------------------------------------------------------------------

type Flags = {
    readonly adopt: boolean;
    readonly reveal: boolean;
    readonly refresh: boolean;
    readonly expectNoChanges: boolean;
    readonly targets: ReadonlyArray<string>;
};

// --- [ERRORS] --------------------------------------------------------------------------

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

// --- [OPERATIONS] ----------------------------------------------------------------------

// A scoped env extends the inherited one, so the child keeps PATH beside the brokered credential.
const _run = (command: string, args: ReadonlyArray<string>, label: string, env?: Record<string, string>) =>
    Effect.gen(function* () {
        const spawned = yield* ChildProcess.make(command, args, env === undefined ? {} : { env, extendEnv: true });
        const [code, out, err] = yield* Effect.all(
            [spawned.exitCode, Stream.mkString(Stream.decodeText(spawned.stdout)), Stream.mkString(Stream.decodeText(spawned.stderr))],
            { concurrency: 3 },
        );
        return code === 0 ? out : yield* new ShellFault({ command: label, detail: err.trim() || `exit ${code}` });
    }).pipe(
        Effect.scoped,
        Effect.catchTag('PlatformError', (fault) => Effect.fail(new ShellFault({ command: label, detail: fault.message }))),
    );

const _shell = (command: string, ...args: ReadonlyArray<string>) => _run(command, args, `${command} ${args.join(' ')}`);

const _dopplerSecret = (token: Redacted.Redacted<string>, credential: Topology.Credential) =>
    Effect.map(
        _run(
            'doppler',
            ['secrets', 'get', credential.name, '--project', credential.project, '--config', credential.config, '--plain'],
            `doppler secrets get ${credential.name} (${credential.project}/${credential.config})`,
            { DOPPLER_TOKEN: Redacted.value(token) },
        ),
        (raw) => Redacted.make(raw.trim()),
    );

// NonEmptyString: an empty exported override means unset, per XDG semantics. Ambient credentials short-circuit their broker.
const _settings = Config.all({
    passphraseRef: Config.NonEmptyString('SERVICES_PASSPHRASE_REF').pipe(Config.withDefault('op://Tokens/PULUMI_CONFIG_PASSPHRASE/password')),
    tokenRef: Config.NonEmptyString('SERVICES_DOPPLER_TOKEN_REF').pipe(Config.withDefault('op://Tokens/DOPPLER_IAC_TOKEN/token')),
    stateDir: Config.NonEmptyString('SERVICES_STATE_DIR').pipe(
        Config.orElse(() => Config.map(Config.NonEmptyString('XDG_STATE_HOME'), (root) => path.join(root, 'services'))),
        Config.withDefault(path.join(homedir(), '.local', 'state', 'services')),
    ),
    passphrase: Config.option(Config.Redacted('PULUMI_CONFIG_PASSPHRASE')),
    token: Config.option(Config.Redacted('DOPPLER_TOKEN')),
    githubToken: Config.option(Config.Redacted('GITHUB_TOKEN')),
    ghToken: Config.option(Config.Redacted('GH_TOKEN')),
});

// Ambient env short-circuits 1Password; otherwise the op reference resolves per run.
const _brokered = (ambient: Option.Option<Redacted.Redacted<string>>, ref: string) =>
    Option.match(ambient, {
        onSome: (value) => Effect.succeed(value),
        onNone: () => Effect.map(_shell('op', 'read', ref), (raw) => Redacted.make(raw.trim())),
    });

const _githubToken = (ambient: Option.Option<Redacted.Redacted<string>>, dopplerToken: Redacted.Redacted<string>) =>
    Option.match(ambient, {
        onSome: (value) => Effect.succeed(value),
        onNone: () => _dopplerSecret(dopplerToken, Topology.githubCredential),
    });

const _openStack = (flags: Flags) =>
    Effect.gen(function* () {
        const cfg = yield* _settings;
        const fs = yield* FileSystem.FileSystem;
        yield* fs.makeDirectory(cfg.stateDir, { recursive: true });
        yield* fs.chmod(cfg.stateDir, 0o700);
        const [passphrase, token] = yield* Effect.all([_brokered(cfg.passphrase, cfg.passphraseRef), _brokered(cfg.token, cfg.tokenRef)], {
            concurrency: 2,
        });
        const backendUrl = `file://${cfg.stateDir}`;
        const githubToken = yield* _githubToken(
            Option.orElse(cfg.githubToken, () => cfg.ghToken),
            token,
        );
        return yield* Effect.tryPromise({
            // BOUNDARY ADAPTER: Pulumi Automation API is promise-native; secrets unwrap only into the engine's child process environment.
            try: () =>
                LocalWorkspace.createOrSelectStack(
                    {
                        stackName: STACK,
                        projectName: PROJECT,
                        program: program(flags),
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

// BOUNDARY ADAPTER: Pulumi onOutput sink — the engine hands raw chunks to a void callback outside the rail.
const _echo = (chunk: string): void => {
    process.stdout.write(chunk);
};

// --- [SCOPE_RAIL] ----------------------------------------------------------------------

const _ScopeTable = Schema.fromJsonString(Schema.Record(Schema.String, Schema.Record(Schema.String, Schema.Unknown)));

const _scopeTable = Effect.flatMap(_shell('doppler', 'configure', '--all', '--json'), Schema.decodeUnknownEffect(_ScopeTable));

const _declaredDirs: HashSet.HashSet<string> = HashSet.fromIterable(Arr.map(_scopes, (row) => row.dir));

const _strayScopes = Effect.map(_scopeTable, (table) =>
    Record.keys(
        Record.filter(
            table,
            (entry, dir) =>
                dir.startsWith(`${_scopeRoot}/`) &&
                !HashSet.has(_declaredDirs, dir) &&
                (Record.has(entry, 'enclave.project') || Record.has(entry, 'enclave.config')),
        ),
    ),
);

// Applies declared rows for existing directories, then unsets stray scopeRoot rows; scope `/`, tokens, and the CLI config file stay untouched.
const _applyScopes = Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem;
    const rows = yield* Effect.filter(_scopes, (row) => fs.exists(row.dir), { concurrency: 4 });
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

// --- [ENTRY] ---------------------------------------------------------------------------

const USAGE =
    'services driver\n' +
    '  preview|up|refresh [--adopt] [--refresh] [--expect-no-changes] [--target=<project>/<config>/<token>]\n' +
    '  outputs [name] [--reveal]\n' +
    '  scopes';

// One flag anchor: `=`-suffixed flags match by prefix, the rest match whole.
const _FLAGS = { adopt: '--adopt', reveal: '--reveal', refresh: '--refresh', expectNoChanges: '--expect-no-changes', target: '--target=' } as const;

const _known = (arg: string): boolean =>
    Arr.some(Struct.keys(_FLAGS), (key) => (_FLAGS[key].endsWith('=') ? arg.startsWith(_FLAGS[key]) : arg === _FLAGS[key]));

const _flags = (argv: ReadonlyArray<string>): Flags => ({
    adopt: Arr.contains(argv, _FLAGS.adopt),
    reveal: Arr.contains(argv, _FLAGS.reveal),
    refresh: Arr.contains(argv, _FLAGS.refresh),
    expectNoChanges: Arr.contains(argv, _FLAGS.expectNoChanges),
    targets: Arr.filterMap(argv, (arg) => (arg.startsWith(_FLAGS.target) ? Result.succeed(arg.slice(_FLAGS.target.length)) : Result.failVoid)),
});

// Remint rail: a token coordinate maps onto its ServiceToken URN so drop/restore applies touch nothing else even under unrelated drift.
const _tokenUrn = (coordinate: string): string =>
    `urn:pulumi:${STACK}::${PROJECT}::doppler:index/serviceToken:ServiceToken::${coordinate.split('/').join('-')}`;

const _targeted = (flags: Flags): { readonly target?: string[] } => (flags.targets.length === 0 ? {} : { target: flags.targets.map(_tokenUrn) });

// Plan modes fold as engine options: --refresh diffs against refreshed live state (drift probe), --expect-no-changes turns steady state into a gate.
const _modes = (flags: Flags): { readonly refresh?: true; readonly expectNoChanges?: true } => ({
    ...(flags.refresh ? { refresh: true as const } : {}),
    ...(flags.expectNoChanges ? { expectNoChanges: true as const } : {}),
});

const _verbs = {
    preview: (flags: Flags, _positional: ReadonlyArray<string>) =>
        Effect.flatMap(
            _stackAct('preview', flags, (stack) => stack.preview({ diff: true, onOutput: _echo, ..._targeted(flags), ..._modes(flags) })),
            (result) => Console.log(JSON.stringify(result.changeSummary ?? {})),
        ),
    up: (flags: Flags, _positional: ReadonlyArray<string>) =>
        Effect.flatMap(
            _stackAct('up', flags, (stack) => stack.up({ onOutput: _echo, ..._targeted(flags), ..._modes(flags) })),
            (result) => Console.log(JSON.stringify(result.summary.resourceChanges ?? {})),
        ),
    refresh: (flags: Flags, _positional: ReadonlyArray<string>) =>
        Effect.asVoid(
            _stackAct('refresh', flags, (stack) => stack.refresh({ onOutput: _echo, ..._targeted(flags), ..._modes({ ...flags, refresh: false }) })),
        ),
    outputs: (flags: Flags, positional: ReadonlyArray<string>) =>
        Effect.flatMap(
            _stackAct('outputs', flags, (stack) => stack.outputs()),
            (outputs) =>
                Option.match(Option.fromNullishOr(positional[1]), {
                    onNone: () =>
                        Effect.forEach(
                            Record.toEntries(outputs),
                            ([name, value]) => Console.log(`${name}\t${value.secret ? '<secret>' : String(value.value)}`),
                            { concurrency: 1, discard: true },
                        ),
                    onSome: (selected) =>
                        Option.match(
                            Option.orElse(Option.fromNullishOr(outputs[`token:${selected}`]), () => Option.fromNullishOr(outputs[selected])),
                            {
                                onNone: () => Effect.fail(new UsageFault({ wanted: `no output named ${selected}` })),
                                onSome: (matched) =>
                                    matched.secret && !flags.reveal
                                        ? Console.log('secret output; pass --reveal for one-time handoff')
                                        : Console.log(String(matched.value)),
                            },
                        ),
                }),
        ),
    scopes: (_flags2: Flags, _positional: ReadonlyArray<string>) => _applyScopes,
} as const;

const _verb = Schema.decodeUnknownOption(Schema.Literals(Struct.keys(_verbs)));

const _program = Effect.gen(function* () {
    const argv = process.argv.slice(2);
    const positional = Arr.filter(argv, (arg) => !arg.startsWith('--'));
    const flags = _flags(argv);
    const stray = Arr.findFirst(argv, (arg) => arg.startsWith('--') && !_known(arg));
    const malformed = Arr.findFirst(flags.targets, (coordinate) => coordinate.split('/').length !== 3);
    // Ordered shape-elimination probe: usage faults first, every arm terminal.
    return yield* Option.isSome(stray)
        ? Effect.fail(new UsageFault({ wanted: `unknown flag ${stray.value}\n${USAGE}` }))
        : Option.isSome(malformed)
          ? Effect.fail(
                new UsageFault({
                    wanted: `--target wants <project>/<config>/<token>, got ${malformed.value}`,
                }),
            )
          : Option.match(_verb(positional[0]), {
                onNone: () => Effect.fail(new UsageFault({ wanted: USAGE })),
                onSome: (verb) => _verbs[verb](flags, positional),
            });
});

NodeRuntime.runMain(Effect.provide(_program, NodeServices.layer));
