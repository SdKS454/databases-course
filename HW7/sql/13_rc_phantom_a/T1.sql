-- 13_rc_phantom_a: READ COMMITTED: новый игрок команды
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Первое чтение набора строк.
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team');

-- ШАГ 3 — T1. Повторить тот же запрос.
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team');

-- ШАГ 4 — T1. После завершения T1 новая строка видна.
COMMIT;
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team');
