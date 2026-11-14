import { homedir } from 'node:os';
import * as path from 'node:path';
import { NodeRuntime, NodeServices } from '@effect/platform-node';
import { LocalWorkspace, type Stack } from '@pulumi/pulumi/automation/index.js';
import { Array as Arr, Config, Console, Data, Effect, FileSystem, Option, Redacted, Schema, Stream, Struct } from 'effect';
import { ChildProcess } from 'effect/process';
import { program } from './program.ts';
import { Topology } from './topology.ts';

// --- [CONSTANTS] -----------------------------------------------------------------------

const PROJECT = 'services';
const STACK = Topology.owner;

// --- [TYPES] ---------------------------------------------------------------------------

type Flags = {
    readonly adopt: boolean;
    readonly refresh: boolean;
    readonly expectNoChanges: boolean;
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

const _opRead = (ref: string) =>
    Effect.gen(function* () {
        const spawned = yield* ChildProcess.make('op', ['read', ref], {});
        const [code, out, err] = yield* Effect.all(
            [spawned.exitCode, Stream.mkString(Stream.decodeText(spawned.stdout)), Stream.mkString(Stream.decodeText(spawned.stderr))],
            { concurrency: 3 },
        );
        return code === 0 ? Redacted.make(out.trim()) : yield* new ShellFault({ command: `op read ${ref}`, detail: err.trim() || `exit ${code}` });
    }).pipe(
        Effect.scoped,
        Effect.catchTag('PlatformError', (fault) => Effect.fail(new ShellFault({ command: `op read ${ref}`, detail: fault.message }))),
    );

const _settings = Config.all({
    passphraseRef: Config.NonEmptyString('SERVICES_PASSPHRASE_REF').pipe(Config.withDefault('op://Tokens/PULUMI_CONFIG_PASSPHRASE/password')),
    tokenRef: Config.NonEmptyString('SERVICES_DOPPLER_TOKEN_REF').pipe(Config.withDefault('op://Tokens/DOPPLER_IAC_TOKEN/token')),
    githubRef: Config.NonEmptyString('SERVICES_GITHUB_TOKEN_REF').pipe(Config.withDefault('op://Tokens/GITHUB_TOKEN/token')),
    stateDir: Config.NonEmptyString('SERVICES_STATE_DIR').pipe(
        Config.orElse(() => Config.map(Config.NonEmptyString('XDG_STATE_HOME'), (root) => path.join(root, 'services'))),
        Config.withDefault(path.join(homedir(), '.local', 'state', 'services')),
    ),
    passphrase: Config.option(Config.Redacted('PULUMI_CONFIG_PASSPHRASE')),
    token: Config.option(Config.Redacted('DOPPLER_TOKEN')),
    githubToken: Config.option(Config.Redacted('GITHUB_TOKEN')),
    ghToken: Config.option(Config.Redacted('GH_TOKEN')),
});

const _brokered = (ambient: Option.Option<Redacted.Redacted<string>>, ref: string) =>
    Option.match(ambient, {
        onSome: (value) => Effect.succeed(value),
        onNone: () => _opRead(ref),
    });

const _openStack = (flags: Flags) =>
    Effect.gen(function* () {
        const cfg = yield* _settings;
        const fs = yield* FileSystem.FileSystem;
        yield* fs.makeDirectory(cfg.stateDir, { recursive: true });
        yield* fs.chmod(cfg.stateDir, 0o700);
        const [passphrase, token, githubToken] = yield* Effect.all(
            [
                _brokered(cfg.passphrase, cfg.passphraseRef),
                _brokered(cfg.token, cfg.tokenRef),
                _brokered(
                    Option.orElse(cfg.githubToken, () => cfg.ghToken),
                    cfg.githubRef,
                ),
            ],
            { concurrency: 3 },
        );
        const backendUrl = `file://${cfg.stateDir}`;
        return yield* Effect.tryPromise({
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

const _echo = (chunk: string): void => {
    process.stdout.write(chunk);
};

// --- [ENTRY] ---------------------------------------------------------------------------

const USAGE = 'services driver\n  preview|up|refresh [--adopt] [--refresh] [--expect-no-changes]';

const _FLAGS = { adopt: '--adopt', refresh: '--refresh', expectNoChanges: '--expect-no-changes' } as const;

const _flags = (argv: ReadonlyArray<string>): Flags => ({
    adopt: Arr.contains(argv, _FLAGS.adopt),
    refresh: Arr.contains(argv, _FLAGS.refresh),
    expectNoChanges: Arr.contains(argv, _FLAGS.expectNoChanges),
});

const _modes = (flags: Flags): { readonly refresh?: true; readonly expectNoChanges?: true } => ({
    ...(flags.refresh ? { refresh: true as const } : {}),
    ...(flags.expectNoChanges ? { expectNoChanges: true as const } : {}),
});

const _verbs = {
    preview: (flags: Flags) =>
        Effect.flatMap(
            _stackAct('preview', flags, (stack) => stack.preview({ diff: true, onOutput: _echo, ..._modes(flags) })),
            (result) => Console.log(JSON.stringify(result.changeSummary ?? {})),
        ),
    up: (flags: Flags) =>
        Effect.flatMap(
            _stackAct('up', flags, (stack) => stack.up({ onOutput: _echo, ..._modes(flags) })),
            (result) => Console.log(JSON.stringify(result.summary.resourceChanges ?? {})),
        ),
    refresh: (flags: Flags) =>
        Effect.asVoid(_stackAct('refresh', flags, (stack) => stack.refresh({ onOutput: _echo, ..._modes({ ...flags, refresh: false }) }))),
} as const;

const _verb = Schema.decodeUnknownOption(Schema.Literals(Struct.keys(_verbs)));

const _program = Effect.gen(function* () {
    const argv = process.argv.slice(2);
    const stray = Arr.findFirst(argv, (arg) => arg.startsWith('--') && !Arr.contains(Object.values(_FLAGS), arg));
    return yield* Option.isSome(stray)
        ? Effect.fail(new UsageFault({ wanted: `unknown flag ${stray.value}\n${USAGE}` }))
        : Option.match(_verb(Arr.findFirst(argv, (arg) => !arg.startsWith('--')).pipe(Option.getOrUndefined)), {
              onNone: () => Effect.fail(new UsageFault({ wanted: USAGE })),
              onSome: (verb) => _verbs[verb](_flags(argv)),
          });
});

NodeRuntime.runMain(Effect.provide(_program, NodeServices.layer));
