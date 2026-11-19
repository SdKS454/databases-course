-- 19_serial_insert_a: SERIALIZABLE: две одинаковые заявки на матч (1800 секунд)
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. T1 проверяет отсутствие матча.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 1800;

-- ШАГ 3 — T1. T1 первой создаёт матч и фиксирует результат.
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 1800, game_mode_id, DATE '2026-11-19' FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode';
COMMIT;

-- ШАГ 8 — T1. Окончательная проверка.
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 1800;
