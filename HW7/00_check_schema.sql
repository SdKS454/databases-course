-- Только чтение: выбрать в pgAdmin ту же базу, что для HW6.
SELECT current_database() AS database_name, version() AS postgres_version;
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'nf'
  AND table_name IN ('teams','players','regions','items','matches','gamemodes')
ORDER BY table_name, ordinal_position;
SELECT 'teams' AS table_name, count(*) FROM nf.Teams
UNION ALL SELECT 'players', count(*) FROM nf.Players
UNION ALL SELECT 'items', count(*) FROM nf.Items;
