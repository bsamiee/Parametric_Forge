map({
  id: .Id,
  name: .Name,
  driver: .Driver,
  service: (.Labels[$service_label] // ""),
  owner: (.Labels[$owner_label] // ""),
  root: (.Labels[$root_label] // ""),
  project: (.Labels[$project_label] // ""),
  attachedContainerCount: ((.Containers // {}) | length)
} + if $diagnostic then {attachedContainers: (.Containers // {})} else {} end) | sort_by(.service, .name)
