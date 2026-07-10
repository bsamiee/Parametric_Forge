---
name: coding-pg
description: >-
    Use for PostgreSQL 18 SQL, migrations, DDL, functions, RLS policies,
    indexes, query plans, extensions, and SQL embedded in TypeScript via
    @effect/sql-pg. Enforces set-algebraic queries, schema-level invariants,
    current PostgreSQL features, extension-first design, tenant security,
    observability, and migration safety.
---

# [CODING_PG]

All SQL follows these governing principles:

- [POLYMORPHIC] — one function/query per concern, generic over specific via parameter dispatch and dynamic SQL
- [SET_ALGEBRAIC] — express operations as set transformations; zero row-at-a-time iteration
- [STRONGLY_TYPED] — domain types, composite types, range types; zero untyped `text` columns for structured data
- [PROGRAMMATIC] — variable-driven predicates, parameterized DDL, zero stringly-typed identifiers
- [DECLARATIVE_FIRST] — constraints, generated columns, and RLS policies enforce invariants at the schema level; application logic is last resort
- [SOURCE_CURRENT] — every example states PostgreSQL 18 semantics

## [01]-[ROUTING]

[FOUNDATION]: always load.

- [01]-[VALIDATION](references/validation.md): compliance checklist, Effect-SQL alignment, migration safety

[TASK_ROUTED_REFERENCES]: load when the task matches.

- [01]-[DDL](references/ddl.md): schema design, domain/composite/range types, temporal constraints, generated columns, partitioning, lock levels
- [02]-[QUERIES](references/queries.md): CTE algebra, MERGE, window functions, JSON_TABLE, recursive patterns
- [03]-[INDEXES](references/indexes.md): index type selection, partial indexes, covering indexes, maintenance
- [04]-[FUNCTIONS](references/functions.md): polymorphic functions, custom aggregates, procedures, PL/pgSQL dispatch
- [05]-[EXTENSIONS](references/extensions.md): pgvector, pg_trgm, PostGIS, TimescaleDB, pg_cron, pg_partman, pg_duckdb, embeddings, similarity search, time-series, spatial, partitioning automation, analytics, OLAP, analytical
- [06]-[SECURITY](references/security.md): RLS, row-level security, tenant isolation, privileges, audit, pgaudit
- [07]-[OBSERVABILITY](references/observability.md): monitoring, statistics, auto_explain, wait events, lock contention
- [08]-[PERFORMANCE](references/performance.md): tuning, io_uring, JIT, parallel query, vacuum, SSD, NVMe, EXPLAIN
- [09]-[REPLICATION](references/replication.md): replication, publications, subscriptions, conflict tracking, CDC

## [02]-[PARADIGM]

- [IMMUTABILITY]: append-only event tables, temporal versioning via `tstzrange` + `WITHOUT OVERLAPS`, soft-delete via `archived_at` timestamp — zero in-place mutation of historical records
- [TYPE_ANCHORING]: one `CREATE TYPE` or `CREATE DOMAIN` per semantic concept — derive column declarations from domain types, never redeclare equivalent `CHECK` constraints across tables
- [EXPRESSION_CONTROL_FLOW]: `CASE`-free query design via `COALESCE`, `NULLIF`, `GREATEST`/`LEAST`, lateral joins, and `FILTER (WHERE ...)` — reserve `CASE` for irreducible multi-branch projection only
- [SET_COMPOSITION]: CTEs as named relational algebra steps; `UNION ALL` over procedural accumulation; `MERGE` over conditional INSERT/UPDATE sequences
- [CONSTRAINT_DRIVEN_INTEGRITY]: `CHECK`, `EXCLUDE`, `WITHOUT OVERLAPS`, `GENERATED ALWAYS AS` — push validation into DDL; application-layer checks are redundant defense, not primary enforcement
- [EXTENSION_FIRST]: pgvector for embeddings, pg_trgm for fuzzy search, PostGIS for spatial, TimescaleDB for time-series — never hand-roll what an extension owns

## [03]-[CONVENTIONS]

| [INDEX] | [LAYER]        | [MECHANISM]                       | [OWNS]                                                         |
| :-----: | :------------- | :-------------------------------- | :------------------------------------------------------------- |
|  [01]   | Identity       | `uuidv7()`                        | PK generation — timestamp-ordered, B-tree friendly             |
|  [02]   | Temporal       | `WITHOUT OVERLAPS` + `PERIOD`     | Range integrity — temporal PKs, FKs, exclusion constraints     |
|  [03]   | Projection     | Virtual generated columns         | Computed fields — zero storage, instant `ALTER TABLE`          |
|  [04]   | Write strategy | `MERGE ... RETURNING OLD/NEW`     | Upsert + audit trail in single statement                       |
|  [05]   | Type safety    | Domain types + composite types    | Semantic column typing — branded scalars, structured records   |
|  [06]   | Search         | GIN + pg_trgm / pgvector          | Full-text, trigram similarity, vector nearest-neighbor         |
|  [07]   | Partitioning   | Declarative + pg_partman          | Time/hash/list partitioning with automatic lifecycle           |
|  [08]   | Scheduling     | pg_cron                           | In-database job scheduling — maintenance, materialized views   |
|  [09]   | Security       | RLS + SECURITY INVOKER            | Row-level tenant isolation, least-privilege function execution |
|  [10]   | Observability  | pg_stat_statements + auto_explain | Query fingerprinting, automatic slow-query plan capture        |

- Effect-SQL (`@effect/sql` + `@effect/sql-pg`) is the assumed TypeScript integration layer.
- `Model.Class` field modifiers (`Generated`, `FieldOnly`, `FieldExcept`, `Sensitive`) must align with DDL constraints — `Generated` fields map to `DEFAULT` or `GENERATED ALWAYS AS` columns.
- All SQL identifiers use `snake_case`; TypeScript receives `camelCase` via `transformResultNames`.

## [04]-[CONTRACTS]

[TYPE_DISCIPLINE]:

- One domain type per semantic concept; column declarations reference the domain, never inline `CHECK` constraints.
- Composite types for structured return values from functions — never `OUT` parameter proliferation.
- Range types (`tstzrange`, `int4range`, custom) for interval semantics — never dual `start`/`end` columns.
- `NOT NULL` is default posture; nullable columns require documented justification.

[QUERY_ALGEBRA]:

- CTEs for named intermediate results; recursive CTEs with `SEARCH BREADTH FIRST` or `CYCLE` for graph traversal.
- `MERGE` with `RETURNING OLD.*, NEW.*, merge_action()` for write-audit fusion.
- Window functions with `GROUPS`/`EXCLUDE` framing where row-count framing is insufficient.
- `JSON_TABLE` / `jsonb_path_query` for structured JSON extraction — never application-side JSON parsing of database-resident JSON.
- `LATERAL JOIN` for correlated subquery materialization — never scalar subqueries in SELECT list.

[INDEX_STRATEGY]:

- Every `WHERE` clause pattern has a corresponding index; partial indexes for selective predicates.
- `INCLUDE` columns for index-only scans on high-frequency read paths.
- GIN for JSONB containment (`@>`), array overlap (`&&`), full-text (`@@`).
- GiST for range overlap, spatial queries, nearest-neighbor when combined with `ORDER BY <-> LIMIT`.
- BRIN for append-only monotonic columns (timestamps, serial IDs) — orders of magnitude smaller than B-tree.

[SECURITY]:

- RLS enabled on every tenant-scoped table; policies use fail-closed `nullif(current_setting('app.current_tenant', true), '')` tenant scoping.
- Functions default to `SECURITY INVOKER` (always the default); `SECURITY DEFINER` only with `SET search_path = pg_catalog, public`.
- Column-level `GRANT` for sensitive fields — never rely on view-based column hiding alone.

[PERFORMANCE]:

- `EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)` is the verification tool; assertions against plan shape, not just row counts.
- AIO (`io_method = io_uring`) for sequential scan and vacuum workloads on Linux.
- Parallel query enabled for aggregation, hash join, index scan — `max_parallel_workers_per_gather` tuned to workload.
- `FOR UPDATE SKIP LOCKED` for concurrent batch processing — never `SELECT ... FOR UPDATE` without `SKIP LOCKED` on queue tables.

## [05]-[ANTI_PATTERNS]

| [INDEX] | [LABEL]                       | [SYMPTOM]                                                                      |
| :-----: | :---------------------------- | :----------------------------------------------------------------------------- |
|  [01]   | STRING_TYPING                 | `text` for structured data (JSON, enum values, composite structures)           |
|  [02]   | DUAL_COLUMN_RANGE             | `start_date`/`end_date` instead of `tstzrange` with exclusion constraint       |
|  [03]   | IMPERATIVE_BATCH              | PL/pgSQL `LOOP` with row-at-a-time `UPDATE` instead of set-based `MERGE`/CTE   |
|  [04]   | INDEX_SPRAWL                  | Redundant single-column indexes subsumed by existing composite indexes         |
|  [05]   | NULLABLE_DEFAULT              | Columns nullable without documented justification                              |
|  [06]   | TRIGGER_LOGIC                 | Business logic in triggers instead of `MERGE RETURNING` or generated columns   |
|  [07]   | OFFSET_PAGINATION             | `LIMIT/OFFSET` instead of keyset pagination for client-facing endpoints        |
|  [08]   | SECURITY_DEFINER_LEAK         | `SECURITY DEFINER` without `SET search_path` — search_path injection vector    |
|  [09]   | STRINGLY_POLICY               | RLS policy with hardcoded literals instead of `current_setting()`              |
|  [10]   | FUNCTION_PROLIFERATION        | Separate functions for each query variant instead of one polymorphic function  |
|  [11]   | APPLICATION_SIDE_JSON         | Fetching raw JSONB and parsing in application instead of `jsonb_path_query`    |
|  [12]   | MANUAL_PARTITION              | Hand-written partition creation instead of pg_partman lifecycle management     |
|  [13]   | UNVALIDATED_CONSTRAINT        | `ADD CONSTRAINT ... NOT VALID` without subsequent `VALIDATE CONSTRAINT`        |
|  [14]   | IF_THEN_DISPATCH              | PL/pgSQL `IF p_op = 'get' THEN ... ELSIF` instead of VALUES-based dynamic SQL  |
|  [15]   | NONCOMPOSABLE_CAGG            | `PERCENTILE_CONT` in hierarchical CAGG; non-composable across tiers            |
|  [16]   | LEGACY_UUID                   | Non-ordered UUID generation on new ordered PKs where `uuidv7()` fits better    |
|  [17]   | STALE_HEALTH_VIEW             | Materialized views for real-time health monitoring instead of inline queries   |
|  [18]   | EXCLUDE_OVER_WITHOUT_OVERLAPS | EXCLUDE instead of WITHOUT OVERLAPS PK/UNIQUE for temporal overlap in PG 18    |
|  [19]   | RAW_UUID_ID                   | Raw `S.UUID` for PK/FK instead of `S.UUID.pipe(S.brand('EntityId'))`           |
|  [20]   | BARE_FOR_UPDATE               | `FOR UPDATE` without `SKIP LOCKED` on batch/queue processing patterns          |
|  [21]   | NULL_UNSAFE_ANTIJOIN          | `NOT IN (SELECT ...)` instead of `NOT EXISTS`; NULL in subquery yields UNKNOWN |
|  [22]   | DISTINCT_OVER_EXISTS          | `SELECT DISTINCT` on joined data; use `EXISTS` semi-join (avoids sort/dedup)   |

## [06]-[FIRST_CLASS_EXTENSIONS]

| [INDEX] | [EXTENSION]          | [OWNS]                                                  | [LOAD_WHEN]                             |
| :-----: | :------------------- | :------------------------------------------------------ | :-------------------------------------- |
|  [01]   | `pgvector`           | Vector storage, HNSW/IVFFlat/DiskANN indexes            | Embedding search, similarity queries    |
|  [02]   | `pgvectorscale`      | DiskANN index, Statistical Binary Quantization          | >1M vectors, memory-constrained         |
|  [03]   | `pg_search`          | BM25 full-text via Tantivy, `@@@` operator              | Search-quality ranking, hybrid search   |
|  [04]   | `pg_trgm`            | Trigram similarity, GIN trigram indexes, `%` operator   | Fuzzy text search, typo tolerance       |
|  [05]   | `PostGIS`            | Geometry/geography types, spatial indexes, ST\_\* funcs | Geospatial queries, proximity search    |
|  [06]   | `TimescaleDB`        | Hypertables, continuous aggregates, compression         | Time-series ingestion, rollup queries   |
|  [07]   | `pg_cron`            | In-database scheduled jobs                              | Materialized view refresh, maintenance  |
|  [08]   | `pg_partman`         | Partition lifecycle management                          | Non-time-series partitioning            |
|  [09]   | `pg_duckdb`          | Embedded DuckDB, analytical acceleration, lake access   | OLAP queries, Parquet/Iceberg reads     |
|  [10]   | `pg_jsonschema`      | JSONB validation via JSON Schema CHECK constraints      | Structured JSONB columns                |
|  [11]   | `btree_gist`         | GiST equality operators for EXCLUDE constraints         | Range + equality exclusion constraints  |
|  [12]   | `bloom`              | Bloom filter index for wide-table equality              | >5 columns, arbitrary WHERE combos      |
|  [13]   | `pg_stat_statements` | Query fingerprinting, execution statistics              | Performance analysis, regression detect |
|  [14]   | `pgaudit`            | Compliance-grade audit logging (session + object)       | SOC 2, HIPAA, PCI-DSS compliance        |

## [07]-[VALIDATION_GATE]

After writing or modifying SQL, run in order:

1. [AUTOMATED_LINT]: run `bash scripts/pg_lint.sh [PATH...]` from this skill directory; errors (E) block merge, warnings (W) require justification. Flags route to `--help`.
2. [MANUAL_CHECKLIST]: `references/validation.md` — compliance gates not automatable (Effect-SQL alignment, migration safety, lock-level awareness).
