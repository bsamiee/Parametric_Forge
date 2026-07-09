. + {
  tools: {
    surfaces: $surfaces,
    summary: {
      selectedSurface: $selected,
      surfaceCount: ($surfaces | keys | length),
      catalogRows: ([ $surfaces[]?.catalog[]? ] | length),
      ok: $ok
    }
  }
} + if $ok then {} else {error: {code: "tool-probe-failed", message: "selected Forge tool surface probe failed", exitCode: 1}} end
