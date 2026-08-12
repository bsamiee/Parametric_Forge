# [VALIDATION]

Each item gates PostgreSQL 18 SQL at merge; run after writing or modifying SQL, and correct every violation before merge.

## [01]-[TYPE_INTEGRITY]

- [ ] Every semantic concept has ONE domain type — no duplicate CHECK constraints across tables
- [ ] Range columns use range types (`tstzrange`, etc.) — no dual `start`/`end` column pairs
- [ ] `NOT NULL` is default — every nullable column has documented justification
- [ ] `uuidv7()` for new PK generation — no `uuid-ossp` or `pgcrypto` dependency for IDs
- [ ] Virtual generated columns for read-computed projections — stored only when indexing required
- [ ] Enum types used only for truly fixed sets — domain-constrained text for evolving vocabularies

## [02]-[QUERY_INTEGRITY]

- [ ] Set-algebraic operations — no row-at-a-time PL/pgSQL loops for transformations expressible as single statements
- [ ] `MERGE` for conditional writes — no separate INSERT/UPDATE/SELECT sequences
- [ ] `MERGE RETURNING OLD.*, NEW.*, merge_action()` for write-audit fusion — no trigger-based audit
- [ ] `LATERAL JOIN` for correlated subqueries — no scalar subqueries in SELECT list
- [ ] `JSON_TABLE` / `jsonb_path_query` for structured JSON extraction — no application-side JSON parsing
- [ ] Window functions with appropriate framing — no GROUP BY + self-join for running calculations
- [ ] Keyset pagination — no OFFSET pagination
- [ ] `FILTER (WHERE ...)` for conditional aggregation — no `CASE WHEN ... THEN value ELSE NULL END` inside aggregate
- [ ] `NOT EXISTS` for anti-joins — no `NOT IN` (NULL-unsafe: any NULL in subquery makes entire predicate UNKNOWN)
- [ ] `EXISTS` for semi-joins — no `SELECT DISTINCT` on correlated/joined data (forces sort/dedup instead of early-exit)
- [ ] VALUES-based dispatch in PL/pgSQL — no IF/THEN/ELSIF chains for operation routing
- [ ] Composable aggregates in hierarchical CAGGs (avg/count/sum/stddev) — no PERCENTILE_CONT across tiers

## [03]-[INDEX_INTEGRITY]

- [ ] Every WHERE clause pattern on tables > 10K rows has a corresponding index
- [ ] Partial indexes for selective predicates (< 20% selectivity)
- [ ] `INCLUDE` columns on high-frequency index-only scan paths
- [ ] GIN for JSONB containment, array overlap, full-text search — not B-tree
- [ ] GiST for range overlap, spatial queries, exclusion constraints — not B-tree
- [ ] BRIN for append-only monotonic columns — verify `pg_stats.correlation` > 0.9
- [ ] Bloom index for wide tables with arbitrary equality combinations (>5 columns) — not N single-column B-trees
- [ ] No redundant indexes — composite (a, b) subsumes single-column (a)
- [ ] All indexes created with `CONCURRENTLY` in production migrations
- [ ] `pg_stat_user_indexes.idx_scan = 0` indexes investigated and justified or removed

## [04]-[DDL_INTEGRITY]

- [ ] Temporal constraints use `WITHOUT OVERLAPS` (PG 18) — no trigger-based overlap prevention
- [ ] Exclusion constraints for business-rule overlap prevention — not application-side checks
- [ ] `SET LOCAL lock_timeout = '2s'` before DDL taking AccessExclusiveLock
- [ ] Partition key included in PRIMARY KEY and all UNIQUE constraints
- [ ] `clock_timestamp()` for insert timestamps — not `now()` (which returns transaction start)
- [ ] Foreign keys explicitly named — no auto-generated constraint names
- [ ] `DETACH PARTITION ... CONCURRENTLY` for online partition removal

## [05]-[SECURITY_INTEGRITY]

- [ ] RLS enabled and FORCED on every tenant-scoped table
- [ ] RLS policies use `nullif(current_setting('app.current_tenant', true), '')` for fail-closed tenant scoping — no hardcoded literals
- [ ] `SECURITY INVOKER` explicit on all new functions — `SECURITY DEFINER` only with `SET search_path`
- [ ] Column-level GRANT for sensitive data — password hashes, MFA secrets, tokens never granted to readonly roles
- [ ] Application connections use non-superuser role without BYPASSRLS
- [ ] `scram-sha-256` authentication — no md5 (deprecated PG 18)

## [06]-[PERFORMANCE_INTEGRITY]

- [ ] `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` verified for new query patterns
- [ ] Index Only Scan achieved where expected — `Heap Fetches` near zero after VACUUM
- [ ] Row estimate accuracy within 10x of actual — stale statistics triggers ANALYZE
- [ ] `FOR UPDATE SKIP LOCKED` for concurrent batch processing — no bare `FOR UPDATE` on queue tables
- [ ] Functions marked `IMMUTABLE`/`STABLE`/`VOLATILE` accurately
- [ ] Functions marked `PARALLEL SAFE` when eligible

## [07]-[INTEGRATION_INTEGRITY_EFFECT_SQL]

PG type to Effect Schema mapping:

| [INDEX] | [PG_TYPE]     | [EFFECT_SCHEMA]             | [NOTES]                                   |
| :-----: | :------------ | :-------------------------- | :---------------------------------------- |
|  [01]   | `int4`        | `S.Int`                     | 32-bit signed integer                     |
|  [02]   | `int8`        | `S.BigInt`                  | 64-bit — JS Number overflows              |
|  [03]   | `numeric`     | `S.BigDecimal`              | Arbitrary precision                       |
|  [04]   | `text`        | `S.String`                  | Unbounded text                            |
|  [05]   | `boolean`     | `S.Boolean`                 | Boolean                                   |
|  [06]   | `uuid`        | `S.UUID`                    | UUID string with format validation        |
|  [07]   | `timestamptz` | `S.DateTimeUtc`             | Timezone-aware timestamp                  |
|  [08]   | `jsonb`       | `Model.JsonFromString(...)` | Schema-validated JSON column              |
|  [09]   | `bytea`       | `S.Uint8ArrayFromBase64`    | Binary data with base64 codec             |
|  [10]   | `tstzrange`   | `S.Unknown` + custom codec  | No native mapping — hand-roll range parse |

PG error codes to Effect tagged errors:

| [INDEX] | [PG_ERROR_CODE] | [NAME]                  | [EFFECT_STRATEGY]                    |
| :-----: | :-------------- | :---------------------- | :----------------------------------- |
|  [01]   | `23505`         | `unique_violation`      | Map to `ConflictError`               |
|  [02]   | `23503`         | `foreign_key_violation` | Map to `NotFoundError` (referential) |
|  [03]   | `40001`         | `serialization_failure` | Retry with `Schedule.exponential`    |
|  [04]   | `40P01`         | `deadlock_detected`     | Retry with `Schedule.exponential`    |
|  [05]   | `57014`         | `query_canceled`        | Map to timeout tagged error          |

- [ ] Server-defaulted columns (`DEFAULT uuidv7()`, `DEFAULT clock_timestamp()`, `GENERATED ALWAYS AS`) use `Model.Generated` — never `Model.GeneratedByApp` (which signals client-side generation)
- [ ] `Model.Generated` implies the column has a DDL-level default and must NOT appear in INSERT payloads
- [ ] `Model.FieldOption` fields are nullable in DDL — NOT NULL + FieldOption is a schema conflict
- [ ] `transformQueryNames: camelToSnake` and `transformResultNames: snakeToCamel` configured on PgClient
- [ ] SqlResolver batch queries have supporting indexes on grouping/lookup keys
- [ ] `set_config('app.current_tenant', ..., true)` with `local=true` for transaction-scoped RLS
- [ ] `sql.reserve` used for session-pinned operations (advisory locks, temp tables) through PgBouncer
- [ ] Migration uses `Effect.gen` + `SqlClient` — not raw SQL strings
- [ ] Entity ID fields use `S.UUID.pipe(S.brand('EntityNameId'))` — raw `S.UUID` is forbidden for PKs and FKs. Domain types in DDL must have corresponding branded schemas in TypeScript
- [ ] Batch operations use `unnest(array[])` — not row-at-a-time PL/pgSQL loops or application-side iteration
- [ ] RAG chunks table carries HNSW on embedding and GIN on tsvector
- [ ] RAG chunks `document_id` FK uses ON DELETE CASCADE
- [ ] RAG chunks `tenant_id` scoped under RLS

## [08]-[MIGRATION_SAFETY]

### [08.1]-[LOCK_LEVEL_AWARENESS]

| [INDEX] | [DDL_STATEMENT]                        | [LOCK_LEVEL]             | [ONLINE_SAFE]                                        |
| :-----: | :------------------------------------- | :----------------------- | :--------------------------------------------------- |
|  [01]   | `CREATE INDEX CONCURRENTLY`            | ShareUpdateExclusiveLock | Yes                                                  |
|  [02]   | `CREATE INDEX` (non-concurrent)        | ShareLock                | Blocks writes                                        |
|  [03]   | `ALTER TABLE ADD COLUMN` (nullable)    | AccessExclusiveLock      | Brief                                                |
|  [04]   | `ALTER TABLE ADD COLUMN DEFAULT`       | AccessExclusiveLock      | Brief (PG 11+: no rewrite for non-volatile defaults) |
|  [05]   | `ALTER TABLE SET NOT NULL`             | AccessExclusiveLock      | Scans table                                          |
|  [06]   | `ALTER TABLE ADD CONSTRAINT`           | AccessExclusiveLock      | Scans table                                          |
|  [07]   | `ALTER TABLE ADD CONSTRAINT NOT VALID` | AccessExclusiveLock      | Brief                                                |
|  [08]   | `VALIDATE CONSTRAINT`                  | ShareUpdateExclusiveLock | Yes                                                  |
|  [09]   | `DROP INDEX CONCURRENTLY`              | ShareUpdateExclusiveLock | Yes                                                  |
|  [10]   | `ALTER TABLE DROP COLUMN`              | AccessExclusiveLock      | Brief                                                |

### [08.2]-[SAFE_PATTERN_ADDING_NOT_NULL_COLUMN]

1. `ALTER TABLE t ADD COLUMN col type` — nullable, AccessExclusiveLock (brief, no rewrite)
2. Backfill in batches: `UPDATE t SET col = ... WHERE col IS NULL AND id BETWEEN $1 AND $2`
3. `ALTER TABLE t ADD CONSTRAINT col_nn CHECK (col IS NOT NULL) NOT VALID` — AccessExclusiveLock (brief, no scan)
4. `ALTER TABLE t VALIDATE CONSTRAINT col_nn` — ShareUpdateExclusiveLock (scans, concurrent DML proceeds)
5. Optionally: `ALTER TABLE t ALTER COLUMN col SET NOT NULL` + `ALTER TABLE t DROP CONSTRAINT col_nn` — if native NOT NULL needed (takes AccessExclusiveLock but skips scan when valid CHECK exists)

### [08.3]-[CONTRACTS]

- [ ] `SET LOCAL lock_timeout = '2s'` before any DDL taking AccessExclusiveLock — fail fast, not block traffic
- [ ] Backward compatibility: old application code runs correctly against new schema during rolling deploy
- [ ] Extension policy documented when operationally relevant — availability, permissions, and upgrade posture are explicit
- [ ] No `DROP COLUMN` without prior deploy removing all application references
- [ ] `NOT VALID` + `VALIDATE CONSTRAINT` two-phase pattern for constraints on populated tables
- [ ] Consistent table ordering across migrations prevents deadlock between concurrent runs
- [ ] `CREATE INDEX CONCURRENTLY` cannot run inside a transaction block — migrations must use non-transactional mode for concurrent index ops

## [09]-[DETECTION_HEURISTICS]

| [INDEX] | [GREP_PATTERN]                                      | [VIOLATION]                                                     |
| :-----: | :-------------------------------------------------- | :-------------------------------------------------------------- |
|  [01]   | `start_date.*end_date` or `_start.*_end`            | DUAL_COLUMN_RANGE — use range type                              |
|  [02]   | `LIMIT.*OFFSET`                                     | OFFSET_PAGINATION — use keyset                                  |
|  [03]   | `FOR UPDATE` without `SKIP LOCKED`                  | Missing SKIP LOCKED on queue table                              |
|  [04]   | `SECURITY DEFINER` without `SET`                    | SECURITY_DEFINER_LEAK                                           |
|  [05]   | `now()` in DEFAULT                                  | Use `clock_timestamp()` for wall time                           |
|  [06]   | `CREATE INDEX` without `CONCURRENTLY`               | Missing CONCURRENTLY in migration                               |
|  [07]   | `LOOP` + `UPDATE` in PL/pgSQL                       | IMPERATIVE_BATCH — use set operation                            |
|  [08]   | `uuid_generate_v4()` or `gen_random_uuid()`         | Prefer `uuidv7()` for new ordered identifiers                   |
|  [09]   | `ALTER TABLE.*ADD CONSTRAINT` without `NOT VALID`   | Missing two-phase constraint addition                           |
|  [10]   | `ENABLE ROW LEVEL SECURITY` without `FORCE`         | Table owner bypasses RLS                                        |
|  [11]   | `CREATE EXTENSION` without current extension policy | Verify extension availability, permissions, and upgrade posture |
|  [12]   | `NOT IN` with subquery                              | NULL_UNSAFE_ANTIJOIN — use NOT EXISTS                           |
|  [13]   | `SELECT DISTINCT` on joined tables                  | DISTINCT_OVER_EXISTS — use EXISTS semi-join                     |
|  [14]   | `CREATE POLICY` without `current_setting`           | STRINGLY_POLICY — hardcoded literals in RLS                     |
|  [15]   | `CREATE TRIGGER` in migration                       | TRIGGER_LOGIC — use MERGE RETURNING or generated columns        |
|  [16]   | `IF.*THEN.*ELSIF` in PL/pgSQL                       | IF_THEN_DISPATCH — use VALUES-based dynamic SQL                 |
|  [17]   | `EXCLUDE.*&&` on temporal in PostgreSQL 18          | EXCLUDE_OVER_WITHOUT_OVERLAPS — use WITHOUT OVERLAPS            |
|  [18]   | `S.UUID` not `.pipe(S.brand`                        | RAW_UUID_ID — brand entity IDs in TS                            |

- `uuid_generate_v4()`/`gen_random_uuid()` on a new ordered PK: justify random UUIDs by workload.
- EXCLUDE_OVER_WITHOUT_OVERLAPS: use WITHOUT OVERLAPS when equality + range overlap is enough.
