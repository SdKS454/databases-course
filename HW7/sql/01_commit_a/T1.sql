-- 01_commit_a: COMMIT: игрок и команда
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. До изменений.
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_01_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_01_NewPlayer';

-- ШАГ 2 — T1. INSERT в одну таблицу и UPDATE связанной записи в другой.
BEGIN;
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_01_NewPlayer', 8500, team_id FROM nf.Teams WHERE name = 'HW7_TX_01_Team';
UPDATE nf.Teams SET foundation_date = DATE '2026-11-19' WHERE name = 'HW7_TX_01_Team';

-- ШАГ 3 — T1. Внутри своей транзакции изменения уже видны.
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_01_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_01_NewPlayer';

-- ШАГ 4 — T1. Завершить транзакцию.
COMMIT;

-- ШАГ 5 — T1. Проверка после завершения.
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_01_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_01_NewPlayer';
