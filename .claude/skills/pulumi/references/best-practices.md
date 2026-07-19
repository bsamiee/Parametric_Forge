# [PULUMI_BEST_PRACTICES]

Program-level law for writing, reviewing, and refactoring Pulumi code.

## [01]-[NO_RESOURCES_IN_APPLY]

Resources created inside `apply()` never appear in `pulumi preview` and break dependency tracking. Detection signals: resource constructors inside `.apply()` callbacks, creation inside `pulumi.all([...]).apply()`, dynamic resource counts computed at runtime inside apply.

```typescript rejected
const bucket = new aws.s3.Bucket('bucket');
bucket.id.apply((bucketId) => {
    new aws.s3.BucketObject('object', { bucket: bucketId, content: 'hello' });
});
```

```typescript accepted
const bucket = new aws.s3.Bucket('bucket');
const object = new aws.s3.BucketObject('object', {
    bucket: bucket.id, // Output<string> passes directly; Pulumi owns the dependency
    content: 'hello',
});
```

`apply()` remains correct for transforming output values into tags, names, or computed strings, for logging, and for conditional logic that affects resource properties — never resource existence.

## [02]-[OUTPUTS_AS_INPUTS]

Pulumi builds its DAG from input/output relationships; manually unwrapped values break the chain, so resources deploy out of order or reference values that never resolved. Detection signals: variables extracted from `.apply()` used later as inputs, `await` on outputs outside apply, string concatenation with outputs.

```typescript rejected
const vpc = new aws.ec2.Vpc('vpc', { cidrBlock: '10.0.0.0/16' });
let vpcId: string;
vpc.id.apply((id) => {
    vpcId = id;
});
const subnet = new aws.ec2.Subnet('subnet', { vpcId: vpcId, cidrBlock: '10.0.1.0/24' });
```

```typescript accepted
const vpc = new aws.ec2.Vpc('vpc', { cidrBlock: '10.0.0.0/16' });
const subnet = new aws.ec2.Subnet('subnet', { vpcId: vpc.id, cidrBlock: '10.0.1.0/24' });

// String building over outputs:
const name = pulumi.interpolate`prefix-${bucket.id}-suffix`;
const alt = pulumi.concat('prefix-', bucket.id, '-suffix');
```

## [03]-[COMPONENTS_FOR_RELATED_RESOURCES]

Related resources group into `ComponentResource` classes; a flat top-level graph hides ownership and blocks reuse. Detection signals: repeated resource patterns across stacks, related resources created at top level without grouping.

```typescript accepted
class StaticSite extends pulumi.ComponentResource {
    public readonly url: pulumi.Output<string>;
    constructor(name: string, args: StaticSiteArgs, opts?: pulumi.ComponentResourceOptions) {
        super('myorg:components:StaticSite', name, args, opts);
        const bucket = new aws.s3.Bucket(`${name}-bucket`, {}, { parent: this });
        // ...
        this.url = distribution.domainName;
        this.registerOutputs({ url: this.url });
    }
}
```

## [04]-[PARENT_THIS]

Every child inside a component carries `{ parent: this }`; without it children land at the stack root, the console hierarchy collapses, and aliases on the component stop reaching them. Parenting also cascades deletion and provider inheritance.

```typescript rejected
class MyComponent extends pulumi.ComponentResource {
    constructor(name: string, opts?: pulumi.ComponentResourceOptions) {
        super('myorg:components:MyComponent', name, {}, opts);
        const bucket = new aws.s3.Bucket(`${name}-bucket`); // lands at root level
    }
}
```

```typescript accepted
class MyComponent extends pulumi.ComponentResource {
    constructor(name: string, opts?: pulumi.ComponentResourceOptions) {
        super('myorg:components:MyComponent', name, {}, opts);
        const bucket = new aws.s3.Bucket(`${name}-bucket`, {}, { parent: this });
    }
}
```

## [05]-[SECRETS_FROM_DAY_ONE]

Values marked `--secret` are encrypted in state, masked in CLI output, and tracked through transformations; starting plaintext and converting later forces credential rotation and an audit of leaked values in logs and state history. Secrets are passwords, API keys, tokens, private keys, certificates, connection strings with credentials, OAuth client secrets, and encryption keys.

```bash copy-safe
pulumi config set --secret databasePassword hunter2
```

```typescript conceptual
const config = new pulumi.Config();
const dbPassword = config.requireSecret('databasePassword');
// Outputs derived from secrets stay secret:
const connectionString = pulumi.interpolate`postgres://user:${dbPassword}@host/db`;
const computed = pulumi.secret(someValue); // explicit marking
```

ESC centralizes secrets across stacks: a `Pulumi.yaml` `environment:` list pulls a resolved environment, and `esc env set <env> <key> --secret <value>` writes into it.

## [06]-[ALIASES_WHEN_REFACTORING]

Renaming a resource, moving it into a component, or changing its parent reads as delete-plus-create without an alias — destruction and recreation of live infrastructure. Detection signal: preview shows replace or delete+create where update was intended.

```typescript rejected
// was: new aws.s3.Bucket("my-bucket")
const bucket = new aws.s3.Bucket('application-bucket'); // destroys the bucket
```

```typescript accepted
const bucket = new aws.s3.Bucket(
    'application-bucket',
    {},
    {
        aliases: [{ name: 'my-bucket' }],
    },
);

// Moving a root resource into a component records the old parent:
const moved = new aws.s3.Bucket(
    'bucket',
    {},
    {
        parent: this,
        aliases: [{ name: 'my-bucket', parent: pulumi.rootStackResource }],
    },
);

// Full-URN form when the previous URN is known:
// aliases: ["urn:pulumi:stack::project::aws:s3/bucket:Bucket::old-name"]
```

Lifecycle: add the alias, run `pulumi up` on every stack, then optionally drop the alias once all stacks updated.

## [07]-[PREVIEW_BEFORE_UP]

`pulumi preview` shows exactly what will be created, updated, or destroyed at zero cost; `pulumi up --yes` without a reviewed preview is deploying blind. Preview vocabulary: `+ create`, `~ update`, `- delete`, `+-replace` (destroy then recreate — potential downtime), `~+-replace`. Warning signs: unexpected replaces (immutable property changes), deletions of resources meant to stay, more changes than the code diff explains.

```yaml template
# CI shape: preview on every PR, deploy only on merge to main
jobs:
    preview:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@<version>
            - uses: pulumi/actions@<version>
              with: { command: preview, stack-name: production }
              env: { PULUMI_ACCESS_TOKEN: '${{ secrets.PULUMI_ACCESS_TOKEN }}' }
    deploy:
        needs: preview
        if: github.ref == 'refs/heads/main'
        runs-on: ubuntu-latest
        steps:
            - uses: pulumi/actions@<version>
              with: { command: up, stack-name: production }
```

## [08]-[QUICK_REFERENCE]

| [INDEX] | [PRACTICE]            | [KEY_SIGNAL]                          | [FIX]                                  |
| :-----: | :-------------------- | :------------------------------------ | :------------------------------------- |
|  [01]   | No resources in apply | `new Resource()` inside `.apply()`    | Move outside; pass the Output directly |
|  [02]   | Outputs as inputs     | Extracted values used as inputs       | Output objects, `pulumi.interpolate`   |
|  [03]   | Components            | Flat graph, repeated patterns         | `ComponentResource` classes            |
|  [04]   | Parent this           | Component children at root level      | `{ parent: this }` on every child      |
|  [05]   | Secrets day one       | Plaintext passwords or keys in config | `--secret` flag, ESC                   |
|  [06]   | Aliases on refactor   | Delete+create in preview              | Alias with old name or parent          |
|  [07]   | Preview before deploy | `pulumi up --yes` unreviewed          | `pulumi preview` first, always         |
