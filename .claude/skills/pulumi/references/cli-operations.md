# [PULUMI_CLI_OPERATIONS]

`pulumi do` mechanics for stateless, one-shot resource operations: command anatomy, property input, resource discovery, output contracts, cross-resource wiring, and graduation into a project.

## [01]-[COMMAND_SHAPE]

```bash copy-safe
npx pulumi do aws:s3:Bucket create --yes --bucket my-data
npx pulumi do aws:s3:Bucket read my-data
```

- `<pkg>` is the provider package (`aws`, `azure-native`, `gcp`, `cloudflare`, `kubernetes`).
- `<mod>` is the module within the package (`compute`, `storage`, `dns`); optional when the module is `index` — `cloudflare:index/record:Record` invokes as `cloudflare:Record`.
- `<type>` is the resource type (`VirtualMachine`, `Bucket`, `Record`).
- `<id>` is the cloud provider's identifier for an existing resource — the value `create` prints as `id`. `create` and `list` take no positional argument; `read`, `patch`, and `delete` take exactly one `<id>`.

There is no Pulumi logical name to choose: the CLI derives an internal name from the type, and existing resources are addressed by cloud id. Two non-CRUD forms exist: `pulumi do <pkg:mod:type> list [flags]` enumerates instances for types that implement listing (native providers broadly; Terraform-bridged `aws`/`azure`/`gcp` with per-type coverage), and `pulumi do <pkg:mod:function> [flags]` invokes a stateless provider function.

## [02]-[PROPERTY_INPUT]

Properties come from per-property flags, a body file, or both; flags overlay the body. Flags set top-level scalar properties only — nested or structured values (`tags`, nested blocks) come from the body file. The body defaults to PCL as flat `name = value` attributes; `--input yaml` selects YAML via the converter plugin.

```bash copy-safe
cat > bucket.pcl <<'EOF'
bucket = "my-data"
tags = {
  Environment = "dev"
}
EOF
npx pulumi do aws:s3:Bucket create --yes --input-file bucket.pcl
```

Before authoring properties for a resource new to the session, `npx pulumi package info <pkg> --module <mod> --resource <Type>` lists its inputs and outputs with descriptions. `npx pulumi package get-schema <pkg>` returns the full machine-readable schema with nested type definitions — tens of MB for a large provider, never read whole. Property names are camelCase; flags take the kebab-case form. `npx pulumi package info <pkg>` with no module lists modules and resources; the catalog lives at https://www.pulumi.com/registry/.

## [03]-[OUTPUT_CONTRACT]

`create`, `read`, and `patch` each write one JSON object to stdout with the resource's properties top-level beside an `id` field holding the cloud identifier — no nested `outputs` object, no `urn`, no echoed type token. `list` writes a JSON array of `{id, name}` entries; a function writes its declared result shape. The exit code is checked on every invocation.

```json output-only
{
    "id": "my-data",
    "bucket": "my-data",
    "arn": "arn:aws:s3:::my-data"
}
```

## [04]-[CONNECTING_RESOURCES]

No state means no resource graph and no `${...}` reference syntax. A value flows between commands by reading a field from one command's JSON output and passing it as a literal flag to the next — across providers as readily as within one.

```bash copy-safe
# create prints JSON containing "id": "vpc-0abc123"
npx pulumi do aws:ec2:Vpc create --yes --cidr-block 10.0.0.0/16
npx pulumi do aws:ec2:Subnet create --yes --vpc-id vpc-0abc123 --cidr-block 10.0.1.0/24

# RandomPet prints "id": "artistic-bull" — globally-unique naming feed
npx pulumi do random:RandomPet create --yes
npx pulumi do aws:s3:Bucket create --yes --bucket assets-artistic-bull
```

A value the chain does not produce — an existing resource id, an API zone id — comes from a provider function, a `list` where supported, or the operator. Never invented.

## [05]-[GRADUATING]

Resources `pulumi do` created are ordinary cloud resources with no Pulumi state behind them; a project adopts them with `pulumi import`, which records each resource in stack state and generates its program code by default.

```bash copy-safe
# import takes the full pkg:mod/type:Type token, not pulumi do's short aws:s3:Bucket
npx pulumi import aws:s3/bucket:Bucket assets my-data
```

The generated code moves into the program, which manages the resource from then on. Bulk adoption passes resources in a `--file`.
