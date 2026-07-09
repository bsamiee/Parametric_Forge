($extensions | flatten) as $extensionRows
| . + {
    ports: $ports,
    extensions: {
      catalog: [],
      results: $extensionRows,
      summary: {
        ok: ([ $extensionRows[] | select(.state == "ok") ] | length),
        requiredOk: ([ $extensionRows[] | select(.required and .state == "ok") ] | length),
        requiredMissing: ([ $extensionRows[] | select(.required and .state != "ok") ] | length),
        available: ([ $extensionRows[] | select(.state == "available") ] | length),
        unavailable: ([ $extensionRows[] | select(.state == "unavailable") ] | length),
        disabled: ([ $extensionRows[] | select(.state == "disabled") ] | length)
      }
    }
  }
+ if $ok then {} else {error: {code: "required-extension-unavailable", message: "required extension check failed", exitCode: 1}} end
