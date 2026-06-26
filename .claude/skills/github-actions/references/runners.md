# [H1][RUNNERS]

## [01]-[STANDARD_LABELS]

| [INDEX] | [OS]        | [LABELS]                                         | [DEFAULT]    |
| :-----: | ----------- | ------------------------------------------------ | ------------ |
|  [01]   | **Ubuntu**  | `ubuntu-latest`, `ubuntu-24.04`, `ubuntu-22.04`  | ubuntu-24.04 |
|  [02]   | **Windows** | `windows-latest`, `windows-2025`, `windows-2022` | windows-2025 |
|  [03]   | **macOS**   | `macos-latest`, `macos-15`, `macos-14`           | macos-15     |

## [02]-[DEPRECATED_AND_RETIRED]

| [INDEX] | [LABEL]            | [STATUS]                    | [DATE]         | [REPLACEMENT]   |
| :-----: | ------------------ | --------------------------- | -------------- | --------------- |
|  [01]   | **`ubuntu-18.04`** | Retired.                    | Removed.       | `ubuntu-24.04`. |
|  [02]   | **`ubuntu-20.04`** | Retired.                    | April 2025.    | `ubuntu-24.04`. |
|  [03]   | **`ubuntu-22.04`** | Supported (EOL April 2027). | Migrate early. | `ubuntu-24.04`. |
|  [04]   | **`macos-12`**     | Retired.                    | Removed.       | `macos-15`.     |
|  [05]   | **`macos-13`**     | Retired.                    | Nov 2025.      | `macos-15`.     |
|  [06]   | **`windows-2019`** | Retired.                    | June 2025.     | `windows-2025`. |
|  [07]   | **`windows-2022`** | Supported (phasing out).    | Migrate early. | `windows-2025`. |

### [2.1]-[MACOS_INTEL_DEPRECATION]

| [INDEX] | [LABEL]                                | [STATUS]              | [REPLACEMENT]      |
| :-----: | -------------------------------------- | --------------------- | ------------------ |
|  [01]   | **`macos-15-intel`, `macos-14-large`** | Long-term deprecated. | ARM64 equivalents. |
|  [02]   | **`macos-15-large`**                   | Long-term deprecated. | `macos-15-xlarge`. |

Apple Silicon (ARM64) required after Fall 2027. Flag Intel macOS labels with deprecation warning.

## [03]-[ARM64_RUNNERS]

| [INDEX] | [LABEL]                | [AVAILABILITY]                                                |
| :-----: | ---------------------- | ------------------------------------------------------------- |
|  [01]   | **`ubuntu-24.04-arm`** | Free for public repos; private repos require Team/Enterprise. |
|  [02]   | **`ubuntu-22.04-arm`** | Free for public repos; private repos require Team/Enterprise. |

[IMPORTANT] ARM64 labels: canonical format is `-arm` suffix (NOT `-arm64`). `ubuntu-latest-arm64` and `ubuntu-24.04-arm64` are **invalid** — flag as incorrect label.

### [3.1]-[DETECTION_RULES]

| [INDEX] | [CHECK]                 | [TAG]      | [WHAT_TO_FLAG]                                                 |
| :-----: | ----------------------- | ---------- | -------------------------------------------------------------- |
|  [01]   | **`-arm64` suffix**     | `[RUNNER]` | Invalid label — use `-arm` suffix (`ubuntu-24.04-arm`).        |
|  [02]   | **`ubuntu-latest-arm`** | `[RUNNER]` | Not a valid label — use explicit version (`ubuntu-24.04-arm`). |
|  [03]   | **ARM in private repo** | `[RUNNER]` | Requires Team or Enterprise plan — free only for public repos. |

## [04]-[GPU_RUNNERS]

| [INDEX] | [LABEL]             | [GPU]                                            | [PRICING] |
| :-----: | ------------------- | ------------------------------------------------ | --------- |
|  [01]   | **`gpu-t4-4-core`** | NVIDIA Tesla T4 (16 GB VRAM), 4 vCPU, 28 GB RAM. | $0.07/min |

Requires Team or Enterprise Cloud plan. Flag `gpu-*` labels in workflows targeting Free/Pro plans.

## [05]-[XLARGE_RUNNERS]

| [INDEX] | [LABEL]                                      | [SPECS]                           | [PRICING] |
| :-----: | -------------------------------------------- | --------------------------------- | --------- |
|  [01]   | **`macos-latest-xlarge`, `macos-15-xlarge`** | 5-core M2 Pro, 8-core GPU, 14 GB. | $0.16/min |
|  [02]   | **`macos-14-xlarge`**                        | 5-core M2 Pro, 8-core GPU, 14 GB. | $0.16/min |

## [06]-[LARGER_RUNNERS]

| [INDEX] | [TYPE]        | [SPEC]         | [NOTES]                            |
| :-----: | ------------- | -------------- | ---------------------------------- |
|  [01]   | **Standard**  | 2 vCPU / 7 GB  | Default `ubuntu-latest`.           |
|  [02]   | **4-core**    | 4 vCPU / 16 GB | Team/Enterprise plans; SSD-backed. |
|  [03]   | **8-64-core** | 8-64 vCPU      | Up to 256 GB RAM; SSD-backed.      |

Larger runners (Team/Enterprise): up to 1,000 concurrent jobs; 100 GPU max.

## [07]-[MULTI_ARCHITECTURE]

```yaml
strategy:
  matrix:
    include:
      - runner: ubuntu-latest
        arch: x64
      - runner: ubuntu-24.04-arm
        arch: arm64
runs-on: ${{ matrix.runner }}
```

[IMPORTANT] Validate ARM64 matrix uses `-arm` suffix (not `-arm64`). Flag `ubuntu-latest-arm64` in matrix definitions.

## [08]-[SELF_HOSTED]

### [8.1]-[ACTIONLINT_LABELS]

```yaml
# .github/actionlint.yaml
self-hosted-runner:
  labels: [my-custom-runner, gpu-runner, arm-runner]
```

Custom labels must be declared for actionlint validation — unlisted labels produce false-positive errors.

### [8.2]-[SECURITY_CHECKS]

| [INDEX] | [CHECK]                       | [TAG]           | [WHAT_TO_FLAG]                                                   |
| :-----: | ----------------------------- | --------------- | ---------------------------------------------------------------- |
|  [01]   | **Public repo + self-hosted** | `[SELF-HOSTED]` | Fork PRs can execute arbitrary code on self-hosted runners.      |
|  [02]   | **Non-ephemeral runners**     | `[SELF-HOSTED]` | Persistent runners accumulate state — use `--ephemeral` flag.    |
|  [03]   | **Missing harden-runner**     | `[SELF-HOSTED]` | Self-hosted runners need runtime monitoring (K8s support in v2). |
|  [04]   | **No runner group isolation** | `[SELF-HOSTED]` | Runner groups should restrict org/repo access boundaries.        |

## [09]-[SELECTION_CHECKLIST]

| [INDEX] | [CRITERION]      | [GUIDANCE]                                                                                  |
| :-----: | ---------------- | ------------------------------------------------------------------------------------------- |
|  [01]   | **Architecture** | ARM64 via `-arm` suffix — free for public repos only.                                       |
|  [02]   | **Cost**         | Standard included; ARM64 (public) free; GPU $0.07/min; xlarge $0.16/min.                    |
|  [03]   | **GPU needs**    | ML/AI workloads need `gpu-t4-4-core` — Team/Enterprise only.                                |
|  [04]   | **Deprecations** | Retired: `ubuntu-20.04`, `macos-12/13`, `windows-2019`. Plan Intel macOS exit by Fall 2027. |
|  [05]   | **Timeouts**     | Flag every job missing `timeout-minutes:` — prevents runaway billing.                       |
