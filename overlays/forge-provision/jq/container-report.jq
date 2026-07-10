(.[0] // null) as $c
| (($c.Config.Labels // {})[$service_label] // "") as $service
| ($identities[$service] // null) as $expected
| (if $c == null or $expected == null then [false, "unknown-service"]
   elif ($c.Config.Image // "") != $expected.image then [false, "image-mismatch"]
   elif (($c.NetworkSettings.Networks // {})[$net]) == null then [false, "network-mismatch"]
   elif (any($c.Mounts[]?; .Name == $expected.volume and .Destination == $expected.mount) | not) then [false, "volume-mount-mismatch"]
   else [true, "-"]
   end) as $identity
| (if $c == null then ["-", "-", "-", "-"]
   else [
       (($c.Name // "-") | ltrimstr("/")),
       ($c.Config.Image // "-"),
       ($c.State.Status // "-"),
       (if $c.State.Health then $c.State.Health.Status else "none" end)
     ]
   end) as $fields
| [$service] + $fields + [($identity[0] | tostring), $identity[1]]
| join("\u001f")
