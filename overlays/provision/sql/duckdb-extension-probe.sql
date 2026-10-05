SET autoinstall_known_extensions = false;
SET autoload_known_extensions = false;
SET allow_community_extensions = false;
SET allow_unsigned_extensions = false;
SELECT extension_name, loaded, installed, description
FROM duckdb_extensions()
ORDER BY extension_name;
