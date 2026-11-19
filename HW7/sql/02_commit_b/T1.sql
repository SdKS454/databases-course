-- 02_commit_b: COMMIT: команда и регион
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. До изменений.
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_02_Region', 'HW7_TX_02_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_02_NewTeam';

-- ШАГ 2 — T1. INSERT в одну таблицу и UPDATE связанной записи в другой.
BEGIN;
INSERT INTO nf.Teams (name, region_id)
SELECT 'HW7_TX_02_NewTeam', region_id FROM nf.Regions WHERE region_name = 'HW7_TX_02_Region';
UPDATE nf.Regions SET region_name = 'HW7_TX_02_Region_OK' WHERE region_name = 'HW7_TX_02_Region';

-- ШАГ 3 — T1. Внутри своей транзакции изменения уже видны.
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_02_Region', 'HW7_TX_02_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_02_NewTeam';

-- ШАГ 4 — T1. Завершить транзакцию.
COMMIT;

-- ШАГ 5 — T1. Проверка после завершения.
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_02_Region', 'HW7_TX_02_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_02_NewTeam';
