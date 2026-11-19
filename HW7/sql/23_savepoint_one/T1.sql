-- 23_savepoint_one: SAVEPOINT: сохранить изменения до точки
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Изменения до точки сохранения.
BEGIN;
UPDATE nf.Teams SET foundation_date = DATE '2010-01-01' WHERE name = 'HW7_TX_23_Team';
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_23_Before', 8000, team_id FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
SAVEPOINT before_extra;

-- ШАГ 2 — T1. Изменения после точки.
UPDATE nf.Teams SET foundation_date = DATE '2020-01-01' WHERE name = 'HW7_TX_23_Team';
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_23_After', 9000, team_id FROM nf.Teams WHERE name = 'HW7_TX_23_Team';

-- ШАГ 3 — T1. Перед частичным откатом.
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
SELECT nickname FROM nf.Players WHERE nickname IN ('HW7_TX_23_Before', 'HW7_TX_23_After') ORDER BY nickname;

-- ШАГ 4 — T1. Изменения до SAVEPOINT остались.
ROLLBACK TO SAVEPOINT before_extra;
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
SELECT nickname FROM nf.Players WHERE nickname IN ('HW7_TX_23_Before', 'HW7_TX_23_After') ORDER BY nickname;

-- ШАГ 5 — T1. Оставшиеся изменения зафиксированы.
COMMIT;
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
SELECT nickname FROM nf.Players WHERE nickname IN ('HW7_TX_23_Before', 'HW7_TX_23_After') ORDER BY nickname;
