SET client_min_messages TO warning;
CREATE TEMP TABLE forge_extension_target(
  ordinal integer NOT NULL,
  name text PRIMARY KEY,
  category text NOT NULL,
  required boolean NOT NULL,
  create_on_apply boolean NOT NULL
);
CREATE TEMP TABLE forge_extension_runtime(
  name text PRIMARY KEY,
  state text NOT NULL
);
INSERT INTO forge_extension_target(ordinal, name, category, required, create_on_apply) VALUES
__FORGE_EXTENSION_VALUES__;
DO $$
DECLARE target record;
BEGIN
  FOR target IN
    SELECT name
    FROM forge_extension_target
    WHERE create_on_apply
      AND EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = forge_extension_target.name)
    ORDER BY ordinal
  LOOP
    BEGIN
      EXECUTE format('CREATE EXTENSION IF NOT EXISTS %I', target.name);
    EXCEPTION
      WHEN insufficient_privilege OR feature_not_supported OR undefined_file OR undefined_object OR invalid_parameter_value OR object_not_in_prerequisite_state THEN
        NULL;
    END;
  END LOOP;
END
$$;
CREATE TEMP TABLE forge_pg_cron_probe_context(
  probe_id text PRIMARY KEY,
  job_name text NOT NULL,
  scratch_schema text NOT NULL
);
CREATE TEMP TABLE forge_pg_cron_job(job_id bigint);
INSERT INTO forge_pg_cron_probe_context(probe_id, job_name, scratch_schema)
SELECT probe_id,
       'forge_pg_cron_' || substr(probe_id, 7, 16),
       'forge_apply_' || substr(md5(__FORGE_CONTEXT_SQL__ || probe_id), 1, 10) || '_' || substr(probe_id, 7, 16)
FROM (SELECT 'probe_' || md5(clock_timestamp()::text || random()::text) AS probe_id) seed
WHERE EXISTS (SELECT 1 FROM forge_extension_target WHERE name = 'pg_cron' AND required)
  AND EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron');
DO $$
DECLARE
  job_id bigint;
  probe_id text;
  scratch_schema text;
BEGIN
  SELECT c.probe_id, c.scratch_schema INTO probe_id, scratch_schema
  FROM forge_pg_cron_probe_context c
  LIMIT 1;

  IF probe_id IS NULL THEN
    RETURN;
  END IF;

  EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', scratch_schema);
  EXECUTE format('CREATE SCHEMA %I', scratch_schema);
  EXECUTE format(
    'CREATE TABLE %I.forge_pg_cron_probe(id text PRIMARY KEY, observed_at timestamptz NOT NULL DEFAULT clock_timestamp())',
    scratch_schema
  );

  SELECT cron.schedule(
           c.job_name,
           '1 seconds',
           format('INSERT INTO %I.forge_pg_cron_probe(id) VALUES (%L) ON CONFLICT DO NOTHING', c.scratch_schema, c.probe_id)
         )
  INTO job_id
  FROM forge_pg_cron_probe_context c
  LIMIT 1;

  IF job_id IS NOT NULL THEN
    INSERT INTO forge_pg_cron_job(job_id) VALUES (job_id);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      IF job_id IS NOT NULL THEN
        PERFORM cron.unschedule(job_id);
      END IF;
      IF scratch_schema IS NOT NULL THEN
        EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', scratch_schema);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    INSERT INTO forge_extension_runtime(name, state) VALUES ('pg_cron', 'scheduler-failed')
    ON CONFLICT (name) DO UPDATE SET state = excluded.state;
END
$$;
DO $$
DECLARE
  probe_id text;
  job_id bigint;
  scratch_schema text;
  observed boolean := false;
  deadline timestamptz := clock_timestamp() + interval '20 seconds';
BEGIN
  SELECT c.probe_id, j.job_id, c.scratch_schema
  INTO probe_id, job_id, scratch_schema
  FROM forge_pg_cron_probe_context c
  CROSS JOIN forge_pg_cron_job j
  LIMIT 1;

  IF job_id IS NULL THEN
    IF scratch_schema IS NOT NULL THEN
      EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', scratch_schema);
    END IF;
    RETURN;
  END IF;

  LOOP
    EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I.forge_pg_cron_probe WHERE id = $1)', scratch_schema)
    USING probe_id
    INTO observed;
    EXIT WHEN observed;
    EXIT WHEN clock_timestamp() >= deadline;
    PERFORM pg_sleep(1);
  END LOOP;

  PERFORM cron.unschedule(job_id);

  IF observed THEN
    INSERT INTO forge_extension_runtime(name, state) VALUES ('pg_cron', 'ok')
    ON CONFLICT (name) DO UPDATE SET state = excluded.state;
  ELSE
    INSERT INTO forge_extension_runtime(name, state) VALUES ('pg_cron', 'scheduler-timeout')
    ON CONFLICT (name) DO UPDATE SET state = excluded.state;
  END IF;

  EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', scratch_schema);
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      IF job_id IS NOT NULL THEN
        PERFORM cron.unschedule(job_id);
      END IF;
      IF scratch_schema IS NOT NULL THEN
        EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', scratch_schema);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    INSERT INTO forge_extension_runtime(name, state) VALUES ('pg_cron', 'scheduler-failed')
    ON CONFLICT (name) DO UPDATE SET state = excluded.state;
END
$$;
SELECT __FORGE_SERVICE_SQL__,
       t.name,
       CASE
         WHEN t.name = 'pg_cron'
              AND t.required
              AND e.extname IS NOT NULL
              AND (
                current_setting('cron.database_name', true) IS DISTINCT FROM current_database()
                OR current_setting('cron.use_background_workers', true) IS DISTINCT FROM 'on'
              ) THEN 'misconfigured'
         WHEN t.name = 'pg_cron'
              AND t.required
              AND e.extname IS NOT NULL
              AND COALESCE(r.state, 'scheduler-not-run') != 'ok' THEN COALESCE(r.state, 'scheduler-not-run')
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
LEFT JOIN pg_available_extensions a ON a.name = t.name
LEFT JOIN pg_extension e ON e.extname = t.name
LEFT JOIN forge_extension_runtime r ON r.name = t.name
ORDER BY t.ordinal;
