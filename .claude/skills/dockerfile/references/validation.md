# [H1][DOCKERFILE_REFERENCE]

[IMPORTANT] Docker Engine 29.2+ | BuildKit 0.27+ | Dockerfile syntax 1 (auto-resolving) | February 2026

## [01]-[BASE_IMAGES]

| [INDEX] | [IMAGE]                                     | [SIZE] | [SHELL] |
| :-----: | ------------------------------------------- | :----: | :-----: |
|  [01]   | `scratch`                                   |  0 MB  |   No    |
|  [02]   | `gcr.io/distroless/static-debian12:nonroot` |  2 MB  |   No    |
|  [03]   | `gcr.io/distroless/base-debian12:nonroot`   | 20 MB  |   No    |
|  [04]   | `alpine:3.23`                               |  7 MB  |   Yes   |
|  [05]   | `node:24-slim-trixie`                       | 80 MB  |   Yes   |
|  [06]   | `python:3.15-rc-slim-trixie`                | 50 MB  |   Yes   |
|  [07]   | `golang:1.26-alpine3.23`                    | 250 MB |   Yes   |
|  [08]   | `eclipse-temurin:{21,25}-jre-alpine`        | 190 MB |   Yes   |
|  [09]   | `cgr.dev/chainguard/*`                      | varies |   No    |

**Use Cases:**
1. Go/Rust static binaries — zero attack surface
2. Static binaries needing ca-certs (UID 65532)
3. Dynamic binaries needing glibc
4. General minimal — musl libc (test glibc compatibility)
5. Node.js runtime (glibc, Debian 13 security)
6. Python runtime (Debian 13)
7. Go build stage only
8. Java runtime (Alpine, LTS 21 or current 25)
9. Daily-rebuilt, zero CVEs, SBOM included

Pin: `alpine:3.23` (good), `alpine:3.23@sha256:...` (reproducible). Never `:latest`.

Chainguard: daily rebuilds (vs Google distroless periodic), multi-layer OCI caching, FIPS variants, free at `:latest`, production requires subscription.

## [02]-[SECURITY_RULES]

| [INDEX] | [RULE]                          | [FIX]                                                                     |
| :-----: | ------------------------------- | ------------------------------------------------------------------------- |
|  [01]   | **Non-root USER required**      | `groupadd`/`useradd` + `USER 1001:1001` (or distroless `nonroot`).        |
|  [02]   | **No secrets in ENV/ARG**       | `--mount=type=secret,id=key,env=VAR` or runtime injection.                |
|  [03]   | **COPY over ADD**               | ADD auto-extracts tars + fetches URLs; use `COPY` for local files.        |
|  [04]   | **Exec-form CMD/ENTRYPOINT**    | Shell form wraps in `/bin/sh -c` -- PID 1 cannot receive signals.         |
|  [05]   | **Pipefail**                    | `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` or `set -o pipefail`.       |
|  [06]   | **No sudo**                     | Run privileged ops before `USER`, drop with `USER`.                       |
|  [07]   | **No cert bypass**              | `-k`, `--no-check-certificate`, `--trusted-host` enable MITM.             |
|  [08]   | **`--no-install-recommends`**   | Prevents apt from pulling ~100 MB suggested packages.                     |
|  [09]   | **`--chown`/`--chmod` on COPY** | `COPY --link --chown=1001:1001 --chmod=555 src dst` (single layer).       |
|  [10]   | **OCI labels**                  | `LABEL org.opencontainers.image.title="..." ...revision/created/version`. |
|  [11]   | **Non-privileged ports**        | Ports < 1024 require root capability; use 3000/8000/8080.                 |
|  [12]   | **STOPSIGNAL**                  | `STOPSIGNAL SIGTERM` (or `SIGQUIT` for nginx).                            |

## [03]-[HEALTHCHECK]

| [INDEX] | [APP_TYPE]            | [INTERVAL] | [TIMEOUT] | [START_PERIOD] | [START_INTERVAL] | [RETRIES] | [CHECK_METHOD]                                                      |
| :-----: | --------------------- | :--------: | :-------: | :------------: | :--------------: | :-------: | ------------------------------------------------------------------- |
|  [01]   | **Node.js API**       |    30s     |    5s     |      10s       |        2s        |     3     | `CMD ["node", "-e", "require('http').get(...)"]`                    |
|  [02]   | **Python API**        |    30s     |    5s     |      10s       |        2s        |     3     | `CMD ["python", "-c", "import urllib.request; ..."]`                |
|  [03]   | **Java (Spring)**     |    30s     |    10s    |      40s       |        5s        |     3     | `CMD ["wget", "--spider", "http://localhost:8080/actuator/health"]` |
|  [04]   | **Background worker** |    60s     |    10s    |      15s       |        5s        |     3     | Check PID file or queue connection.                                 |
|  [05]   | **Distroless**        |    N/A     |    N/A    |      N/A       |       N/A        |    N/A    | Orchestrator probes (K8s/ECS) -- no shell.                          |

`--start-interval` (Docker Engine 25+, default 5s): probing frequency during `--start-period` warmup. Set lower (2s) for fast-starting services, higher (5s) for JVM/heavy apps.

**STOPSIGNAL by application:** Node.js/Python/Go/Java = `SIGTERM`. nginx = `SIGQUIT` (graceful drain).

## [04]-[HADOLINT_RULES]

| [INDEX] | [RULE]     | [SEV] | [DESCRIPTION]                                                        |
| :-----: | ---------- | :---: | -------------------------------------------------------------------- |
|  [01]   | **DL3000** | error | Absolute WORKDIR required -- relative paths ambiguous across stages. |
|  [02]   | **DL3002** | warn  | Last USER not root -- container compromise = host root.              |
|  [03]   | **DL3004** | error | No sudo -- breaks audit trail.                                       |
|  [04]   | **DL3006** | warn  | Always tag image versions -- `:latest` non-reproducible.             |
|  [05]   | **DL3007** | warn  | No `:latest` tag -- same tag, different digests.                     |
|  [06]   | **DL3008** | warn  | Pin apt-get versions -- unpinned = rebuild variance.                 |
|  [07]   | **DL3013** | warn  | Pin pip versions -- same as DL3008 for Python.                       |
|  [08]   | **DL3015** | info  | `--no-install-recommends` -- prevents ~100 MB bloat.                 |
|  [09]   | **DL3018** | warn  | Pin apk versions -- same as DL3008 for Alpine.                       |
|  [10]   | **DL3020** | error | COPY not ADD for files -- ADD has implicit extraction.               |
|  [11]   | **DL3025** | warn  | Exec-form CMD/ENTRYPOINT -- shell form breaks signal handling.       |
|  [12]   | **DL3027** | warn  | `apt-get` not `apt` -- apt is interactive frontend.                  |
|  [13]   | **DL3042** | warn  | pip: `--no-cache-dir` or `--mount=type=cache`.                       |
|  [14]   | **DL3047** | info  | HEALTHCHECK exec-form CMD -- avoid shell conditionals.               |
|  [15]   | **DL3059** | info  | Combine consecutive RUN -- each = 1 layer.                           |
|  [16]   | **DL4006** | warn  | Set pipefail -- pipe failures silently swallowed without it.         |

## [05]-[CHECKOV_POLICIES]

**CKV_DOCKER (11 policies):**

| [INDEX] | [ID]              | [DESCRIPTION]                                                    |
| :-----: | ----------------- | ---------------------------------------------------------------- |
|  [01]   | **CKV_DOCKER_1**  | No SSH port (22) -- lateral movement vector.                     |
|  [02]   | **CKV_DOCKER_2**  | HEALTHCHECK required -- orchestrators need health signal.        |
|  [03]   | **CKV_DOCKER_3**  | Non-root user created -- limits blast radius.                    |
|  [04]   | **CKV_DOCKER_4**  | COPY not ADD -- ADD has implicit extraction.                     |
|  [05]   | **CKV_DOCKER_5**  | `apt-get update` not alone -- creates stale cache layer.         |
|  [06]   | **CKV_DOCKER_6**  | LABEL not MAINTAINER -- MAINTAINER deprecated since Docker 1.13. |
|  [07]   | **CKV_DOCKER_7**  | Version tag not `:latest` -- breaks reproducibility.             |
|  [08]   | **CKV_DOCKER_8**  | Last USER not root.                                              |
|  [09]   | **CKV_DOCKER_9**  | `apt-get` not `apt` -- apt CLI unstable for scripts.             |
|  [10]   | **CKV_DOCKER_10** | Absolute WORKDIR.                                                |
|  [11]   | **CKV_DOCKER_11** | Unique FROM aliases in multi-stage.                              |

**CKV2_DOCKER (17 graph policies) -- all prevent TLS/signature bypass:**

| [INDEX] | [ID_RANGE]            | [PATTERN]                                                      |
| :-----: | --------------------- | -------------------------------------------------------------- |
|  [01]   | **CKV2_DOCKER_1**     | No `sudo`.                                                     |
|  [02]   | **CKV2_DOCKER_2-3**   | No `curl -k`, `wget --no-check-certificate`.                   |
|  [03]   | **CKV2_DOCKER_4-5**   | No `pip --trusted-host`, `PYTHONHTTPSVERIFY=0`.                |
|  [04]   | **CKV2_DOCKER_6**     | No `NODE_TLS_REJECT_UNAUTHORIZED=0`.                           |
|  [05]   | **CKV2_DOCKER_7-8**   | No `apk --allow-untrusted`, `apt-get --allow-unauthenticated`. |
|  [06]   | **CKV2_DOCKER_9-11**  | No `--nogpgcheck`, RPM validation, `--force-yes`.              |
|  [07]   | **CKV2_DOCKER_12-13** | No `NPM_CONFIG_STRICT_SSL=false`, `strict-ssl false`.          |
|  [08]   | **CKV2_DOCKER_14-16** | No `GIT_SSL_NO_VERIFY`, `sslverify=false`, `PIP_TRUSTED_HOST`. |
|  [09]   | **CKV2_DOCKER_17**    | No `chpasswd` -- passwords in layer history.                   |

Suppress: `# checkov:skip=CKV_DOCKER_2:Reason here`

## [06]-[BUILDKIT_VERSION_MATRIX]

| [INDEX] | [FEATURE]                            | [MIN_DOCKER] | [MIN_BUILDKIT] |  [FRONTEND]  |
| :-----: | ------------------------------------ | :----------: | :------------: | :----------: |
|  [01]   | **`# syntax=docker/dockerfile:1`**   |    18.09     |      0.6       |     Any      |
|  [02]   | **`RUN --mount=type=cache`**         |    18.09     |      0.8       |     1.2+     |
|  [03]   | **`RUN --mount=type=secret`**        |    18.09     |      0.8       |     1.2+     |
|  [04]   | **`RUN --mount=type=secret,env=`**   |     27.0     |      0.14      |    1.14+     |
|  [05]   | **`COPY --link`**                    |     23.0     |      0.8       |     1.4+     |
|  [06]   | **`COPY --chmod` (octal)**           |     23.0     |      0.8       |     1.2+     |
|  [07]   | **`COPY --chmod` (symbolic)**        |     27.0     |      0.14      |    1.14+     |
|  [08]   | **Heredoc `RUN <<EOF`**              |     23.0     |      0.10      |     1.4+     |
|  [09]   | **`FROM --platform=$BUILDPLATFORM`** |    18.09     |      0.8       |     1.2+     |
|  [10]   | **SBOM/Provenance attestations**     |     24.0     |      0.11      | N/A (buildx) |
|  [11]   | **`HEALTHCHECK --start-interval`**   |     25.0     |      N/A       |     N/A      |
