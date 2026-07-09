{
  ok: true,
  executable: "sqlite-forge",
  catalog: $catalog,
  probe: (($rows[0] // {}) + {rowCount: ($rows | length)})
}
