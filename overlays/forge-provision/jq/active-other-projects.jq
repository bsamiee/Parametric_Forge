[.[] | .Config.Labels[$project_label] // empty | select(. != $current)]
| unique
| length
