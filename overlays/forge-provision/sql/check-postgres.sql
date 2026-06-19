WITH forge_extension_target(ordinal, name, category, required, create_on_apply) AS (
  VALUES
  __FORGE_EXTENSION_VALUES__
),
forge_settings AS (
  SELECT name, setting
  FROM pg_settings
  WHERE name IN ('cron.database_name', 'cron.use_background_workers')
),
forge_runtime AS (
  SELECT extname, extversion
  FROM pg_extension
),
forge_available AS (
  SELECT name, default_version
  FROM pg_available_extensions
)
SELECT __FORGE_SERVICE_SQL__,
       t.name,
       CASE
         WHEN t.name = 'pg_cron'
              AND t.required
              AND e.extname IS NOT NULL
              AND (
                (SELECT setting FROM forge_settings WHERE name = 'cron.database_name') IS DISTINCT FROM current_database()
                OR (SELECT setting FROM forge_settings WHERE name = 'cron.use_background_workers') IS DISTINCT FROM 'on'
              ) THEN 'misconfigured'
         WHEN e.extname IS NOT NULL THEN 'ok'
         WHEN a.name IS NULL AND t.required THEN 'missing'
         WHEN a.name IS NULL THEN 'unavailable'
         WHEN t.create_on_apply THEN 'not-created'
         ELSE 'available'
       END,
       COALESCE(e.extversion, a.default_version, '-'),
       t.category,
       CASE WHEN t.required THEN 'required' ELSE 'optional' END
FROM forge_extension_target t
LEFT JOIN forge_available a ON a.name = t.name
LEFT JOIN forge_runtime e ON e.extname = t.name
ORDER BY t.ordinal;
