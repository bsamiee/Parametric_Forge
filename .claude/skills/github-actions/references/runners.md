# [RUNNERS]

## [01]-[STANDARD_LABELS]

| [INDEX] | [OS]    | [LABELS]                                         | [DEFAULT]    |
| :-----: | :------ | :----------------------------------------------- | :----------- |
|  [01]   | Ubuntu  | `ubuntu-latest`, `ubuntu-24.04`, `ubuntu-22.04`  | ubuntu-24.04 |
|  [02]   | Windows | `windows-latest`, `windows-2025`, `windows-2022` | windows-2025 |
|  [03]   | macOS   | `macos-latest`, `macos-15`, `macos-14`           | macos-15     |

## [02]-[DEPRECATED_AND_RETIRED]

| [INDEX] | [LABEL]        | [STATUS]  | [TIMELINE]     | [REPLACEMENT]  |
| :-----: | :------------- | :-------- | :------------- | :------------- |
|  [01]   | `ubuntu-18.04` | Retired   | Removed        | `ubuntu-24.04` |
|  [02]   | `ubuntu-20.04` | Retired   | April 2025     | `ubuntu-24.04` |
|  [03]   | `ubuntu-22.04` | Supported | EOL April 2027 | `ubuntu-24.04` |
|  [04]   | `macos-12`     | Retired   | Removed        | `macos-15`     |
|  [05]   | `macos-13`     | Retired   | Nov 2025       | `macos-15`     |
|  [06]   | `windows-2019` | Retired   | June 2025      | `windows-2025` |
|  [07]   | `windows-2022` | Supported | Phasing out    | `windows-2025` |

### [02.1]-[MACOS_INTEL_DEPRECATION]

Long-term deprecated Intel and large macOS labels and their replacements:

| [INDEX] | [LABEL]          | [REPLACEMENT]     |
| :-----: | :--------------- | :---------------- |
|  [01]   | `macos-15-intel` | ARM64 equivalents |
|  [02]   | `macos-14-large` | ARM64 equivalents |
|  [03]   | `macos-15-large` | `macos-15-xlarge` |

Apple Silicon (ARM64) is required after Fall 2027; flag Intel macOS labels with a deprecation warning.

## [03]-[ARM64_RUNNERS]

Both are free for public repos; private repos require Team or Enterprise:

- `ubuntu-24.04-arm`
- `ubuntu-22.04-arm`

[IMPORTANT] ARM64 labels: canonical format is `-arm` suffix (NOT `-arm64`). `ubuntu-latest-arm64` and `ubuntu-24.04-arm64` are invalid — flag as incorrect label.

### [03.1]-[DETECTION_RULES]

[TAG]: `[RUNNER]`

| [INDEX] | [CHECK]             | [WHAT_TO_FLAG]                                                 |
| :-----: | :------------------ | :------------------------------------------------------------- |
|  [01]   | `-arm64` suffix     | Invalid label — use `-arm` suffix (`ubuntu-24.04-arm`).        |
|  [02]   | `ubuntu-latest-arm` | Not a valid label — use explicit version (`ubuntu-24.04-arm`). |
|  [03]   | ARM in private repo | Requires Team or Enterprise plan — free only for public repos. |

## [04]-[GPU_RUNNERS]

`gpu-t4-4-core`:

- GPU: NVIDIA Tesla T4 (16 GB VRAM), 4 vCPU, 28 GB RAM
- Pricing: $0.07/min
- Plan: Team or Enterprise Cloud

Flag `gpu-*` labels in workflows targeting Free/Pro plans.

## [05]-[XLARGE_RUNNERS]

xlarge macOS runners — 5-core M2 Pro, 8-core GPU, 14 GB, $0.16/min:

- `macos-latest-xlarge`
- `macos-15-xlarge`
- `macos-14-xlarge`

## [06]-[LARGER_RUNNERS]

| [INDEX] | [TYPE]    | [SPEC]         | [NOTES]                            |
| :-----: | :-------- | :------------- | :--------------------------------- |
|  [01]   | Standard  | 2 vCPU / 7 GB  | Default `ubuntu-latest`.           |
|  [02]   | 4-core    | 4 vCPU / 16 GB | Team/Enterprise plans; SSD-backed. |
|  [03]   | 8-64-core | 8-64 vCPU      | Up to 256 GB RAM; SSD-backed.      |

Larger runners (Team/Enterprise): up to 1,000 concurrent jobs; 100 GPU max.

## [07]-[MULTI_ARCHITECTURE]

```yaml conceptual
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

### [08.1]-[ACTIONLINT_LABELS]

```yaml conceptual
# .github/actionlint.yaml
self-hosted-runner:
    labels: [my-custom-runner, gpu-runner, arm-runner]
```

Custom labels must be declared for actionlint validation — unlisted labels produce false-positive errors.

### [08.2]-[SECURITY_CHECKS]

[TAG]: `[SELF-HOSTED]`

| [INDEX] | [CHECK]                   | [WHAT_TO_FLAG]                                                   |
| :-----: | :------------------------ | :--------------------------------------------------------------- |
|  [01]   | Public repo + self-hosted | Fork PRs can execute arbitrary code on self-hosted runners.      |
|  [02]   | Non-ephemeral runners     | Persistent runners accumulate state — use `--ephemeral` flag.    |
|  [03]   | Missing harden-runner     | Self-hosted runners need runtime monitoring (K8s support in v2). |
|  [04]   | No runner group isolation | Runner groups left open across org/repo boundaries.              |

## [09]-[SELECTION_CHECKLIST]

- [01]-[ARCHITECTURE]: ARM64 via `-arm` suffix — free for public repos only.
- [02]-[COST]: Standard included; ARM64 (public) free; GPU $0.07/min; xlarge $0.16/min.
- [03]-[GPU_NEEDS]: ML/AI workloads need `gpu-t4-4-core` — Team/Enterprise only.
- [04]-[DEPRECATIONS]: Retired `ubuntu-20.04`, `macos-12/13`, `windows-2019`; plan Intel macOS exit by Fall 2027.
- [05]-[TIMEOUTS]: Flag every job missing `timeout-minutes:` — prevents runaway billing.
