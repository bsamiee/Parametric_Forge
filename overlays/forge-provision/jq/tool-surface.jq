if $surface == "duckdb" then
  {
    ok: true,
    executable: "duckdb",
    catalog: $catalog,
    probe: {
      extensionRows: ($rows | length),
      security: {
        autoinstallKnownExtensions: false,
        autoloadKnownExtensions: false,
        allowCommunityExtensions: false,
        allowUnsignedExtensions: false
      },
      extensions: ($rows | map({extension: .extension_name, loaded: .loaded, installed: .installed}))
    }
  }
else
  {
    ok: true,
    executable: "sqlite-forge",
    catalog: $catalog,
    probe: (($rows[0] // {}) + {rowCount: ($rows | length)})
  }
end
