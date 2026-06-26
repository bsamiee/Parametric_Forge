---
name: dockerfile
description: >-
  Generates and validates production-ready multi-stage Dockerfiles and .dockerignore files with BuildKit features, pnpm monorepo support, OCI labels, and security hardening.
  Use when creating, editing, reviewing, or validating Dockerfiles for Node.js, Python, Go, Java, or Rust.
---

# [H1][DOCKERFILE]

Docker Engine 27+ | BuildKit 0.27+ | Dockerfile syntax 1.14 | Node 24 LTS Krypton | Alpine 3.23

**Tasks:**
1. Gather requirements -- language, version, framework, entry point, package manager
2. Read [dockerfile_knowledge.md](./references/dockerfile_knowledge.md) -- Generation patterns and language substitution
3. (framework research) Query context7 MCP or WebSearch for `"<framework> <version> dockerfile production 2026"`
4. Generate Dockerfile -- Apply universal template with language-specific substitution
5. Generate .dockerignore -- See exemplar at `examples/example.dockerignore`
6. Validate -- Read [validation.md](./references/validation.md) and apply 5-stage pipeline (hadolint + Checkov + custom)
7. Iterate -- Fix, re-validate, repeat (max 3 iterations)

**Scope:**
- *Generation:* Dockerfiles for Node.js (pnpm/npm), Python (uv), Go, Java, Rust
- *Validation:* All Dockerfile variants (Dockerfile, Dockerfile.prod, Dockerfile.dev)
- *Orchestration:* docker-bake.hcl for monorepo multi-target builds
- *Not:* Building/running containers, debugging runtime issues

## [01]-[REQUIREMENTS]

**Guidance:**
- `Language` -- Language, version, framework, entry point, package manager (pnpm/npm/uv/go mod/maven/gradle)
- `Build` -- Build commands, Nx target (monorepo), compilation flags, system deps.
- `Runtime` -- Port(s), env vars, health endpoint, image size constraints, multi-arch (amd64/arm64).

**Best-Practices:**
- **Base images (February 2026):** `node:24-slim-trixie` (pnpm), `node:24-alpine3.23` (npm), `python:3.15-rc-slim-trixie`, `golang:1.24-alpine3.23`, `rust:1.84-slim-trixie`, `eclipse-temurin:21-jdk-alpine`
- **Chainguard:** `cgr.dev/chainguard/node:latest-dev` (build) / `cgr.dev/chainguard/node:latest` (runtime) -- daily CVE rebuilds, zero known vulnerabilities

[REFERENCE]: [dockerfile_knowledge.md](./references/dockerfile_knowledge.md) -- Generation patterns, language substitution, cache mounts.

## [02]-[MANDATORY_FEATURES]

**Guidance:**
- `Syntax` -- `# syntax=docker/dockerfile:1` as first line (enables BuildKit frontend).
- `Multi-stage` -- Named stages: `deps`, `build`, `runtime` (minimum).
- `Security` -- Non-root `USER 1001:1001`, no secrets in ENV/ARG, exec-form ENTRYPOINT.

**Best-Practices:**
- **BuildKit mounts:** `--mount=type=cache` for all pkg managers, `--mount=type=secret,id=key,env=VAR` for build secrets
- **Layer optimization:** `COPY --link` on every COPY, `COPY --chmod=555` (no extra RUN chmod layer), heredoc `RUN <<EOF` for multi-line scripts
- **Metadata:** OCI labels (`org.opencontainers.image.title/source/licenses/revision/created/version`), Pulumi-injectable ARGs (`GIT_SHA`, `BUILD_DATE`, `IMAGE_VERSION`)
- **Runtime:** `HEALTHCHECK` with `--start-interval=2s` (exec-form CMD), `STOPSIGNAL SIGTERM`, non-privileged ports (>1024)

## [03]-[PNPM_MONOREPO]

**Guidance:**
- `Fetch-first` -- `pnpm fetch --frozen-lockfile` downloads to store without installing (maximizes cache hits).
- `Deploy` -- `pnpm deploy --filter=@scope/app --prod /prod/app` extracts standalone prod deployment.

**Best-Practices:**
- **corepack:** `RUN corepack enable` (no global pnpm install)
- **Offline install:** `pnpm install --frozen-lockfile --offline --ignore-scripts`
- **Selective copy:** Only needed workspace package manifests when package roots exist.
- **Base image:** `node:24-slim-trixie` (glibc, Debian 13 -- not alpine for musl compat)
- **Exemplar:** Use the Dockerfile in the physical app root being containerized.

[REFERENCE]: [dockerfile_knowledge.md](./references/dockerfile_knowledge.md) -- pnpm monorepo pattern, cache mount targets.

## [04]-[DELIVERABLES]

| [INDEX] | [LANGUAGE]                | [ESTIMATED_SIZE] |
| :-----: | ------------------------- | :--------------: |
|  [01]   | **Node.js (slim-trixie)** |    80-200 MB     |
|  [02]   | **Python (slim-trixie)**  |    50-250 MB     |
|  [03]   | **Go (distroless)**       |     5-20 MB      |
|  [04]   | **Java (JRE)**            |    200-350 MB    |

**Deliverables:** Validated Dockerfile + .dockerignore + validation summary.

**Build command with attestations:**
```bash
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --sbom=true --provenance=mode=max \
    --build-arg GIT_SHA="$(git rev-parse HEAD)" \
    --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -t myapp:latest --push .
```

## [05]-[VALIDATION]

**Severity classification:**
- `Critical` -- Hardcoded secrets in ENV/ARG, cert bypass flags, no USER directive.
- `High` -- `:latest` tag, sudo usage, SSH port (22), no HEALTHCHECK for services.
- `Medium` -- Missing version pins, cache cleanup, missing OCI labels, no `--no-install-recommends`.
- `Low` -- Style (layer count, STOPSIGNAL, heredoc opportunities).

**Fix order:** Critical first, then high, medium, low. Resolve all critical before moving to high. Max 3 fix-validate cycles.

**Tool installation:**

| [INDEX] | [TOOL]       | [INSTALL]                                                                        |      [MIN_VERSION]       |
| :-----: | ------------ | -------------------------------------------------------------------------------- | :----------------------: |
|  [01]   | **hadolint** | Nix-provided on dev machines. VPS: `bash .claude/scripts/bootstrap-cli-tools.sh` |          2.14.0          |
|  [02]   | **Checkov**  | Nix-provided on dev machines. VPS: `bash .claude/scripts/bootstrap-cli-tools.sh` | latest (Python 3.9-3.14) |

**Troubleshooting:**

| [INDEX] | [ERROR]                            | [FIX]                                                         |
| :-----: | ---------------------------------- | ------------------------------------------------------------- |
|  [01]   | **FROM must be first non-comment** | Move `ARG` defining base tag before `FROM`.                   |
|  [02]   | **Unknown instruction**            | Check spelling (common: RUNS, COPIES, FRUM).                  |
|  [03]   | **COPY failed: file not found**    | Verify path relative to build context, check .dockerignore.   |
|  [04]   | **Hardcoded secrets detected**     | `--mount=type=secret,env=VAR` or runtime config.              |
|  [05]   | **COPY --link not recognized**     | `# syntax=docker/dockerfile:1` as first line, Docker 23.0+.   |
|  [06]   | **Heredoc not recognized**         | `# syntax=docker/dockerfile:1` as first line, BuildKit 0.10+. |

[REFERENCE]: [validation.md](./references/validation.md) -- Security rules, hadolint/Checkov catalogs, BuildKit version matrix.

[VERIFY] Completion:
- [ ] Syntax directive: `# syntax=docker/dockerfile:1` as first line
- [ ] Multi-stage: Named stages with minimal final base
- [ ] Security: Non-root USER, no secrets in ENV/ARG, exec-form ENTRYPOINT
- [ ] BuildKit: `COPY --link`, `--mount=type=cache`, heredoc RUN
- [ ] Metadata: OCI labels, Pulumi ARGs, STOPSIGNAL, HEALTHCHECK with `--start-interval`
- [ ] All critical and high validation issues resolved (medium/low: fix or document rationale)

**Integration:**
- **k8s-debug** -- Container debugging when builds fail at runtime
- **pulumi-k8s-generator** -- Pulumi K8s resources with the container image
