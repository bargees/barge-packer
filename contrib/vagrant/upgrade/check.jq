.machines | with_entries(
  select(.value.extra_data.box.name == $box)
  |
  select(.value.extra_data.box.version != $version)
)
