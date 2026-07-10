# [PULUMI_DEBUGGING]

A failed `pulumi up` or `pulumi preview` already recorded its error; debugging reads that record, traces the cause, and places the fix — nothing reruns to reproduce. The commands reach Pulumi Cloud through `pulumi api`, addressing a stack by explicit `{orgName}/{projectName}/{stackName}` path, so the stack need not be selected locally to read its record; selection matters only when applying the fix.

## [01]-[IDENTIFY_THE_OPERATION]

The operation arrives as org, project, stack, and an update version or preview id — usually in prose ("debug update 161 of vvm-dev"). Missing fields fill from context: the selected stack (`pulumi stack --show-name`, `pulumi stack ls`) or `Pulumi.yaml`; a missing version means the most recent update. Confirm the landed-on operation — version or preview id and stack — with the operator before reading further, lightly.

When nothing identifies the operation, the target is the operator's most recent one. The update list does not record who ran each update, so it resolves through the API: `pulumi whoami` gives the login; `pulumi api /api/stacks/{orgName}/{projectName}/{stackName}/updates/latest` gives the latest update and its `requestedBy.githubLogin`; on mismatch, walk back one version at a time via `/updates/<n>` until the login matches. State which operation was landed on — version, kind, result — and confirm before going further.

## [02]-[READ_WHAT_FAILED]

Failed updates and failed previews both record engine events; the error lives in the diagnostic messages inside them.

```bash template
# Failed update — by version number
pulumi api /api/stacks/{orgName}/{projectName}/{stackName}/update/<version>/events \
  | jq -r '.events[].diagnosticEvent | select(. != null) | "[\(.severity)] \(.message)"' \
  | sed 's/<{%reset%}>//g'

# Failed preview — by preview id
pulumi api /api/stacks/{orgName}/{projectName}/{stackName}/preview/<preview-id>/events \
  | jq -r '.events[].diagnosticEvent | select(. != null) | "[\(.severity)] \(.message)"' \
  | sed 's/<{%reset%}>//g'
```

Every message matters, not only `severity == "error"`: a provider error carries the `error` tag, but a program error — the common case when a preview fails — arrives as a stderr diagnostic tagged `info#err`. The trailing `sed` strips the terminal color codes Pulumi embeds.

## [03]-[PLACE_THE_FIX]

An operation can fail with errors from more than one resource: read all diagnostics first, then trace each error to the resource that raised it (URN and type), its declaration in the program, and the inputs feeding it. The error text names the problem kind, and the kind names where the fix belongs:

- [PROGRAM]: The code is wrong — a bad reference, wrong type, rejected input, or a value used before it resolved. The usual failed-preview cause: the plan never built. Fix by editing the code.
- [STATE]: The code is correct but stored state and cloud reality disagree. Reconcile drift with `pulumi refresh`; bring an already-existing external resource under management with `pulumi import` rather than recreating it. An operation that failed partway may have already changed resources — check current state before deciding.
- [ENVIRONMENT]: The problem is outside Pulumi — credentials, permissions, OIDC, quota. Fix the role, the ESC environment, or the capacity the provider rejected, never the resource code.

The smallest change addressing the root cause wins; confirmation and delivery of the fix follow the active mode's workflow.
