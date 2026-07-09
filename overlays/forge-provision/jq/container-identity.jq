.[0] as $container
| ($container.NetworkSettings.Networks[$net] != null)
and any($container.Mounts[]?; .Name == $volume and .Destination == $mount)
