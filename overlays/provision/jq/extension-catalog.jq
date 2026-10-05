def env_enabled($row):
  ($row.gateEnv // "") as $env
  | if $env == "" then true
    else ((env[$env] // ($row.gateDefault // "0")) | ascii_downcase) as $value
    | any(($row.gateEnabledValues // ["1", "true", "yes", "on"])[]; ascii_downcase == $value)
    end;
map(select(.service == $service or .service == "*"))
| if $mode == "rows" then
    .[]
    | .extension as $extension
    | (if env_enabled(.) and .required then "1" else "0" end) as $required
    | (if env_enabled(.) and .createOnApply then "1" else "0" end) as $createOnApply
    | [
        $extension,
        .category,
        $required,
        $createOnApply,
        (.createPolicy // ""),
        (.loadPolicy // ""),
        (.probeKind // ""),
        ((.probeSqlKey // "") | if . == "" then "none" else . end),
        (if .requiresSharedPreload then "1" else "0" end),
        (.postgres.sharedPreloadLibrary // "")
      ]
    | @tsv
  elif $mode == "disabled" then
    .[]
    | select(env_enabled(.) and ((.required // false) or (.createOnApply // false)))
    | [$service, .extension, "disabled", "-", .category, "optional"]
    | @tsv
  else
    map(. + {
      expectedService: $service,
      required: (if env_enabled(.) then (.required // false) else false end),
      createOnApply: (if env_enabled(.) then (.createOnApply // false) else false end),
      createPolicy: (if env_enabled(.) and (.createOnApply // false) then "apply-create" else (.createPolicy // "probe-only") end),
      loadPolicy: (if env_enabled(.) and (.createOnApply // false) then "apply-create" else (.loadPolicy // "probe-only") end)
    })
  end
