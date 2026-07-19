# [PULUMI_AUTOMATION_API]

Automation API drives Pulumi operations from code instead of the CLI: multi-stack orchestration, self-service infrastructure platforms, embedded per-tenant provisioning, and the replacement of fragile shell scripts stitching `pulumi` commands. A single project with standard deployment needs stays on the CLI.

```typescript conceptual
import * as automation from "@pulumi/pulumi/automation";

const stack = await automation.LocalWorkspace.createOrSelectStack({
    stackName: "dev",
    projectName: "my-project",
    program: async () => {
        /* Pulumi program */
    },
});
const upResult = await stack.up({ onOutput: console.log });
```

## [01]-[SOURCE_MODEL]

- [LOCAL_SOURCE]: `workDir` points at an existing Pulumi project on disk. Fits separate ownership — a platform team orchestrating application-team programs, independent version control and release cycles.
- [INLINE_SOURCE]: `program` embeds the Pulumi program as a function in the orchestrator. Fits single-team ownership, tight coupling by design, and compiled-binary distribution with no source files.
- [LANGUAGE_INDEPENDENCE]: Orchestrator and orchestrated programs choose languages independently — a Go orchestrator manages TypeScript programs.

```typescript conceptual
// Local source
const local = await automation.LocalWorkspace.createOrSelectStack({
    stackName: "dev",
    workDir: "./infrastructure",
});

// Inline source
const inline = await automation.LocalWorkspace.createOrSelectStack({
    stackName: "dev",
    projectName: "my-project",
    program: async () => {
        const bucket = new aws.s3.Bucket("my-bucket");
        return { bucketName: bucket.id };
    },
});
```

## [02]-[ORCHESTRATION]

Dependent stacks deploy sequentially in dependency order and destroy in reverse; independent stacks deploy in parallel.

```typescript conceptual
// Sequential: infrastructure → platform → application
for (const info of [
    { name: "infrastructure", dir: "./infra" },
    { name: "platform", dir: "./platform" },
    { name: "application", dir: "./app" },
]) {
    const stack = await automation.LocalWorkspace.createOrSelectStack({ stackName: "prod", workDir: info.dir });
    await stack.up({ onOutput: console.log });
}
// destroy(): same list reversed, selectStack + stack.destroy()

// Parallel for independent stacks
await Promise.all(
    independentStacks.map(async (info) => {
        const stack = await automation.LocalWorkspace.createOrSelectStack({ stackName: "prod", workDir: info.dir });
        return stack.up({ onOutput: (msg) => console.log(`[${info.name}] ${msg}`) });
    }),
);
```

## [03]-[CONFIG_OUTPUTS_ERRORS]

```typescript conceptual
// Configuration lands programmatically before up
await stack.setConfig("aws:region", { value: "us-west-2" });
await stack.setConfig("dbPassword", { value: "secret", secret: true });

// Outputs read after deployment — the cross-stack value channel
const outputs = await stack.outputs();
console.log(`VPC ID: ${outputs["vpcId"].value}`);

// Failure handling: the summary result and thrown errors both matter
try {
    const result = await stack.up({ onOutput: console.log });
    if (result.summary.result === "failed") process.exit(1);
} catch (error) {
    throw error;
}
```

## [04]-[OPERATIONAL_SHAPE]

- [EXTERNAL_CONFIG]: Stack lists, environments, and deploy parameters live in a config file or environment variables the orchestrator reads — enabling compiled-binary distribution without source exposure.
- [STREAMED_OUTPUT]: `onOutput` streams long operations in real time to stdout, a logging system, or a websocket.

| [INDEX] | [SCENARIO]                   | [APPROACH]                             |
| :-----: | :--------------------------- | :------------------------------------- |
|  [01]   | Existing Pulumi projects     | Local source with `workDir`            |
|  [02]   | New embedded infrastructure  | Inline source with `program`           |
|  [03]   | Separate team ownership      | Local source for independence          |
|  [04]   | Compiled binary distribution | Inline source or bundled local         |
|  [05]   | Dependent stacks             | Sequential deployment in order         |
|  [06]   | Independent stacks           | Parallel deployment with `Promise.all` |

Full reference: https://www.pulumi.com/docs/using-pulumi/automation-api/
