.[0] as $container
| ($container.Config.Image == $image
  and ($container.NetworkSettings.Networks[$net] != null)
  and any($container.Mounts[]?; .Name == $volume and .Destination == $mount)) as $ok
| [$ok, (if $ok then "-" elif $container.Config.Image != $image then "image-mismatch" elif ($container.NetworkSettings.Networks[$net] == null) then "network-mismatch" else "volume-mount-mismatch" end)]
| @tsv
