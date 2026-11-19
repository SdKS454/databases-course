-- 12_rc_repeat_b: READ COMMITTED: повторное чтение, MMR игрока
-- T2. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 2 — T2. Изменить значение и зафиксировать.
BEGIN;
UPDATE nf.Players SET mmr = 8100 WHERE nickname = 'HW7_TX_12_Player';
COMMIT;
