# [<tier-token>_API_<package-token>]

<catalog-charter-2-4-sentences>

## [01]-[PACKAGE_SURFACE]

- package: <package-id>
- license: <license>
- namespace: <namespace-or-import>
- asset: <asset-or-dll>
- rail: <one-file-rail>

## [02]-[PUBLIC_TYPES]

| [INDEX] | [SYMBOL]   | [KIND]           | [CAPABILITY]                |
| :-----: | :--------- | :--------------- | :-------------------------- |
|  [01]   | `<symbol>` | <kind-1-2-words> | <capability-phrase>         |
|  [02]   | `Shape`    | union            | the closed shape vocabulary |

## [03]-[ENTRYPOINTS]

| [INDEX] | [SURFACE]             | [KIND]           | [CAPABILITY]                       |
| :-----: | :-------------------- | :--------------- | :--------------------------------- |
|  [01]   | `<surface-signature>` | <kind-1-2-words> | <capability-phrase>                |
|  [02]   | `refine(shape)`       | fold             | refine one shape to canonical form |

## [04]-[IMPLEMENTATION_LAW]

[<package-token>_TOPOLOGY]:
- <topology-invariant-law>
- the shape kernel folds every op through one dispatch surface

[STACKING]:
- `<sibling-package>`(`.api/<sibling-path>`): <exact-integration-shape>
- `row-codec`(`.api/data/row-codec.md`): shapes fold into the content-keyed frame

[LOCAL_ADMISSION]:
- <accept-in-repo-rule>
- the shape kernel is admitted at the primary domain tier

[RAIL_LAW]:
- Package: <rail-package-id>
- Owns: <owned-concern>
- Accept: <accept-rule>
- Reject: <reject-rule>
