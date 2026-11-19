-- 06_error_b: ERROR: команда и регион
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. До изменений.
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_06_Region', 'HW7_TX_06_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_06_NewTeam';

-- ШАГ 2 — T1. INSERT в одну таблицу и UPDATE связанной записи в другой.
BEGIN;
INSERT INTO nf.Teams (name, region_id)
SELECT 'HW7_TX_06_NewTeam', region_id FROM nf.Regions WHERE region_name = 'HW7_TX_06_Region';
UPDATE nf.Regions SET region_name = 'HW7_TX_06_Region_OK' WHERE region_name = 'HW7_TX_06_Region';

-- ШАГ 3 — T1. Внутри своей транзакции изменения уже видны.
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_06_Region', 'HW7_TX_06_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_06_NewTeam';

-- ШАГ 4 — T1. Ожидаемая ошибка. Выполнить только этот шаг.
-- Ожидаемая ошибка SQLSTATE 22012; следующий шаг выполнить отдельно.
SELECT 1 / 0;

-- ШАГ 5 — T1. Транзакция в ошибочном состоянии: новые команды не выполняются.
-- Ожидаемая ошибка SQLSTATE 25P02; следующий шаг выполнить отдельно.
SELECT 1;

-- ШАГ 6 — T1. Выполнить отдельным запуском после ошибки: полностью отменить транзакцию.
ROLLBACK;

-- ШАГ 7 — T1. Проверка после завершения.
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_06_Region', 'HW7_TX_06_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_06_NewTeam';
