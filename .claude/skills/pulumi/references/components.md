# [PULUMI_COMPONENTS]

`ComponentResource` authoring in full: anatomy, args interface design, output exposure, design patterns, multi-language packaging, and distribution. A component groups related resources into one reusable node with children nested underneath in preview, up, and the Pulumi Cloud console.

## [01]-[ANATOMY]

Every component carries four elements: extend `ComponentResource` and call `super()` with a type URN; accept name, args, and `ComponentResourceOptions`; set `parent: this` on every child; call `registerOutputs()` as the constructor's last act.

```typescript
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

interface StaticSiteArgs {
    indexDocument?: pulumi.Input<string>;
    errorDocument?: pulumi.Input<string>;
}

class StaticSite extends pulumi.ComponentResource {
    public readonly bucketName: pulumi.Output<string>;
    public readonly websiteUrl: pulumi.Output<string>;

    constructor(name: string, args: StaticSiteArgs, opts?: pulumi.ComponentResourceOptions) {
        super("myorg:index:StaticSite", name, {}, opts);

        const bucket = new aws.s3.Bucket(`${name}-bucket`, {}, { parent: this });
        const website = new aws.s3.BucketWebsiteConfigurationV2(`${name}-website`, {
            bucket: bucket.id,
            indexDocument: { suffix: args.indexDocument ?? "index.html" },
            errorDocument: { key: args.errorDocument ?? "error.html" },
        }, { parent: this });

        this.bucketName = bucket.id;
        this.websiteUrl = website.websiteEndpoint;
        this.registerOutputs({ bucketName: this.bucketName, websiteUrl: this.websiteUrl });
    }
}
```

```python
import pulumi
import pulumi_aws as aws

class StaticSite(pulumi.ComponentResource):
    def __init__(self, name: str, args: StaticSiteArgs, opts: pulumi.ResourceOptions = None):
        super().__init__("myorg:index:StaticSite", name, None, opts)
        bucket = aws.s3.Bucket(f"{name}-bucket", opts=pulumi.ResourceOptions(parent=self))
        # ... children with parent=self ...
        self.bucket_name = bucket.id
        self.register_outputs({"bucket_name": self.bucket_name})
```

The type URN is `<package>:<module>:<type>` — organization or package name, module usually `index`, PascalCase type: `myorg:index:StaticSite`.

A missing `registerOutputs()` leaves the component stuck "creating" in the console and its outputs unpersisted — it is always the constructor's last line. Child names derive from the component name (`${name}-bucket`); a hardcoded child name collides the moment two instances exist.

## [02]-[ARGS_DESIGN]

The args interface defines what consumers configure and how composable the component is.

- [INPUT_WRAP]: Every property wraps in `Input<T>` so it accepts plain values and `Output<T>` alike; a bare `string` forces consumers to unwrap outputs with `.apply()`.
- [FLAT]: Flat interfaces with optional properties beat nested arg objects; deep nesting is hard to use and harder to evolve.
- [NO_UNIONS]: Union types (`string | number`) break Python, Go, and C# SDK generation; variants become separate optional properties (`sizeGb`, `sizeMb`).
- [NO_FUNCTIONS]: Callbacks cannot serialize across language boundaries; configuration properties (`namePrefix`, `nameSuffix`) replace them.
- [DEFAULTS]: Sensible defaults land in the constructor via `??` so consumers configure only what they need; security posture defaults on (`args.enableVersioning !== false` gates the opt-out).

```typescript
interface DatabaseArgs {
    instanceClass: pulumi.Input<string>;
    storageGb: pulumi.Input<number>;
    enableBackups?: pulumi.Input<boolean>;
    backupRetentionDays?: pulumi.Input<number>;
}
```

## [03]-[OUTPUTS]

A component exposes only what consumers need — endpoint, port, security group id — never every internal resource; over-exposure leaks implementation detail into every consumer. Composite values derive with `pulumi.interpolate` or `pulumi.concat`:

```typescript
this.connectionString = pulumi.interpolate`postgresql://${args.username}:${args.password}@${cluster.endpoint}:${cluster.port}/${args.databaseName}`;
this.registerOutputs({ connectionString: this.connectionString });
```

## [04]-[PATTERNS]

- [CONDITIONAL_CREATION]: Optional args gate sub-resource creation — `if (args.enableMonitoring)` wraps the topic, subscription, and alarm block; absent means absent.
- [COMPOSITION]: Higher-level components compose lower-level ones, each level owning one concern — a `Platform` instantiates a `VpcNetwork` child with `{ parent: this }` and feeds its outputs into a cluster.
- [PROVIDER_PASSTHROUGH]: `ComponentResourceOptions` carries explicit providers to children automatically; a consumer passes `{ providers: [usWest] }` for multi-region or multi-account deployments and every `parent: this` child inherits it with no extra code.

## [05]-[MULTI_LANGUAGE]

Packaging is required the moment any consumer uses a different language than the author — including YAML programs, which always require it. A single-language component internal to one codebase imports directly with no packaging. A TypeScript platform team without packaging ships components invisible to Python and YAML application developers.

A `PulumiPlugin.yaml` in the component directory declares the runtime (`runtime: nodejs`, `runtime: python`). Serialization constraints bind regardless of authoring language: primitives, `Input<T>` wrappers, arrays and maps of primitives, and enums serialize; unions, functions, complex nested generics, and platform-specific types do not.

Entry points by language: TypeScript exports component classes from `index.ts` (Pulumi introspects them); Python calls `component_provider_host(name=..., components=[...])` from `pulumi.provider.experimental` in `__main__.py`; Go builds the provider with `infer.NewProviderBuilder().WithComponents(...)`; C# serves `Pulumi.Experimental.Provider.ComponentProviderHost.Serve(args)`.

Consumers install with `pulumi package add <git-repo-url>[@vX.Y.Z]`, which downloads the plugin, generates a local SDK in the consumer's language, and updates `Pulumi.yaml`; `pulumi install` restores dependencies on fresh checkouts. `pulumi package gen-sdk` exists only for authors publishing SDKs to package managers.

## [06]-[DISTRIBUTION]

| [INDEX] | [AUDIENCE]         | [METHOD]         | [HOW]                                         |
| :-----: | :----------------- | :--------------- | :-------------------------------------------- |
|  [01]   | Same project       | Direct import    | Standard language import                      |
|  [02]   | Same organization  | Private registry | `pulumi package publish` to Pulumi Cloud      |
|  [03]   | Same organization  | Git repository   | `pulumi package add <repo>` with version tags |
|  [04]   | Language ecosystem | Package manager  | npm, PyPI, NuGet, Maven                       |
|  [05]   | Public community   | Pulumi Registry  | Submit via the pulumi/registry GitHub repo    |

The private registry gives automatic API documentation, version management, and org-wide discoverability. Versions are `v`-prefixed git tags; a README is required and becomes the registry documentation page; type annotations (JSDoc, docstrings, Go `Annotate()`) enrich generated SDK docs.

```bash
pulumi package publish https://github.com/myorg/my-component --publisher myorg
```

```yaml
# CI publish on tag push, OIDC-authenticated
on: { push: { tags: ["v*"] } }
permissions: { id-token: write, contents: read }
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: pulumi/auth-actions@v1
        with:
          organization: myorg
          requested-token-type: urn:pulumi:token-type:access_token:organization
      - run: pulumi package publish https://github.com/${{ github.repository }} --publisher myorg
```

## [07]-[ANTI_PATTERNS]

| [INDEX] | [ANTI_PATTERN]          | [PROBLEM]                   | [FIX]                                          |
| :-----: | :---------------------- | :-------------------------- | :--------------------------------------------- |
|  [01]   | Resources inside apply  | Invisible in preview        | Create outside apply; pass Outputs directly    |
|  [02]   | Missing registerOutputs | Component stuck creating    | Last line of every constructor                 |
|  [03]   | Missing parent this     | Children at root level      | `{ parent: this }` on every child              |
|  [04]   | Union types in args     | Breaks Python, Go, C# SDKs  | Single types; separate properties for variants |
|  [05]   | Functions in args       | Cannot serialize            | Configuration properties                       |
|  [06]   | Hardcoded child names   | Collisions across instances | Derive from `${name}-suffix`                   |
|  [07]   | Over-exposed outputs    | Leaks implementation detail | Export only what consumers need                |
|  [08]   | Single-use component    | Abstraction overhead        | Inline resources until a pattern repeats       |
|  [09]   | Deeply nested args      | Hard to use and evolve      | Flat interfaces with optional properties       |
