def noneish: if . == "" or . == "-" or . == "<no value>" then null else . end;
{
  service: $service,
  env: $env,
  value: ($port | tonumber),
  portSource: $source,
  state: $state,
  occupied: $occupied,
  owner: $owner,
  ownerClass: $owner,
  containerId: ($container_id | noneish),
  name: ($name | noneish),
  image: ($image | noneish),
  composeProject: ($compose_project | noneish),
  composeService: ($compose_service | noneish),
  provisionProject: ($provision_project | noneish),
  hostListenerPid: null
}
