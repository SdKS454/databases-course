-- 20_serial_insert_b: SERIALIZABLE: две одинаковые заявки на матч (2400 секунд)
-- T2. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 2 — T2. T2 также видит отсутствие матча.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 2400;

-- ШАГ 4 — T2. Ожидаемая ошибка сериализации, не ошибка UNIQUE.
-- Ожидаемая ошибка SQLSTATE 40001; следующий шаг выполнить отдельно.
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 2400, game_mode_id, DATE '2026-11-19' FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode';

-- ШАГ 5 — T2. Завершить неудачную транзакцию отдельной командой.
ROLLBACK;

-- ШАГ 6 — T2. Повтор всей транзакции: снимок и проверка создаются заново.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 2400;

-- ШАГ 7 — T2. На свежем снимке NOT EXISTS ложно: INSERT 0 0.
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 2400, game_mode_id, DATE '2026-11-19' FROM nf.GameModes
WHERE mode_name = 'HW7_TX_20_Mode'
  AND NOT EXISTS (SELECT 1 FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 2400);
COMMIT;
