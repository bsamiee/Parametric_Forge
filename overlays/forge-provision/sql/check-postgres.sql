WITH forge_extension_target (
    ordinal,
    name,
    category,
    required,
    create_on_apply,
    create_policy,
    load_policy,
    probe_kind,
    probe_sql_key,
    requires_shared_preload,
    shared_preload_library
) AS (
    VALUES
    __FORGE_EXTENSION_VALUES__
),

forge_settings AS (
    SELECT name, setting
    FROM pg_settings
    WHERE name IN ('cron.database_name', 'cron.use_background_workers', 'shared_preload_libraries')
),

forge_preload_libraries AS (
    SELECT lower(trim(library)) AS library
    FROM forge_settings s
    CROSS JOIN LATERAL regexp_split_to_table(coalesce(s.setting, ''), '[[:space:]]*,[[:space:]]*') AS split (library)
    WHERE
        s.name = 'shared_preload_libraries'
        AND trim(library) <> ''
),

forge_runtime AS (
    SELECT extname, extversion
    FROM pg_extension
),

forge_available AS (
    SELECT name, default_version
    FROM pg_available_extensions
)

SELECT
    __forge_service_sql__,
    t.name,
    CASE
        WHEN
            t.probe_sql_key = 'pg-cron-scheduler'
            AND t.required
            AND e.extname IS NOT NULL
            AND (
                (SELECT setting FROM forge_settings WHERE name = 'cron.database_name') IS DISTINCT FROM current_database()
                OR (SELECT setting FROM forge_settings WHERE name = 'cron.use_background_workers') IS DISTINCT FROM 'on'
            ) THEN 'misconfigured'
        WHEN
            t.required
            AND t.requires_shared_preload
            AND t.shared_preload_library <> ''
            AND NOT EXISTS (
                SELECT 1
                FROM forge_preload_libraries l
                WHERE l.library = lower(t.shared_preload_library)
            ) THEN 'preload-missing'
        WHEN e.extname IS NOT NULL THEN 'ok'
        WHEN a.name IS NULL AND t.required THEN 'missing'
        WHEN a.name IS NULL THEN 'unavailable'
        WHEN t.create_on_apply THEN 'not-created'
        ELSE 'available'
    END AS state,
    coalesce(e.extversion, a.default_version, '-') AS version,
    t.category,
    CASE WHEN t.required THEN 'required' ELSE 'optional' END AS requirement
FROM forge_extension_target t
LEFT JOIN forge_available a ON a.name = t.name
LEFT JOIN forge_runtime e ON e.extname = t.name
ORDER BY t.ordinal;
