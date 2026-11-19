-- 13_rc_phantom_a: READ COMMITTED: новый игрок команды
-- T2. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 2 — T2. Добавить строку, подходящую под условие, и зафиксировать.
BEGIN;
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_13_New', 8500, team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team';
COMMIT;
