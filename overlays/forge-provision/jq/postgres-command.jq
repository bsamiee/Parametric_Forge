def words($s): if $s == "" then [] else ($s | split(",") | map(select(length > 0))) end;
(words($base) + [.[] | select(.required == true or .createOnApply == true) | .postgres.sharedPreloadLibrary? | select(. != null and . != "")] | unique) as $preloads
| ([.[] | select(.required == true or .createOnApply == true) | .postgres.settings[]? | select((.name // "") != "" and (.value // "") != "")]) as $settings
| if (($preloads | length) == 0 and ($settings | length) == 0) then empty
  else
    ["postgres"]
    + (if ($preloads | length) == 0 then [] else ["-c", "shared_preload_libraries=" + ($preloads | join(","))] end)
    + ($settings | map(["-c", .name + "=" + .value]) | add // [])
    | @json
  end
