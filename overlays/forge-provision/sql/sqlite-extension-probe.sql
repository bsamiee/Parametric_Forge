CREATE VIRTUAL TABLE temp.forge_vec_probe USING vec0(embedding float[2]);
INSERT INTO temp.forge_vec_probe(rowid, embedding) VALUES (1, '[0.0, 1.0]');
SELECT 'sqlite-forge' AS surface,
       sqlite_version() AS sqlite_version,
       vec_version() AS sqlite_vec_version,
       spatialite_version() AS spatialite_version,
       regexp_like('abc', 'a.c') AS sqlean_regexp,
       uuid4() IS NOT NULL AS sqlean_uuid,
       (SELECT name FROM pragma_module_list WHERE name = 'vec0') AS sqlite_vec_module,
       (SELECT name FROM pragma_module_list WHERE name = 'VirtualSpatialIndex') AS spatialite_module,
       (SELECT count(*) FROM temp.forge_vec_probe) AS sqlite_forge_vec_rows;
