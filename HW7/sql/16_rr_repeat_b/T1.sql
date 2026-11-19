-- 16_rr_repeat_b: REPEATABLE READ: повторное чтение, MMR игрока
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Первое чтение создаёт снимок.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_16_Player';

-- ШАГ 3 — T1. Повторить тот же SELECT.
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_16_Player';

-- ШАГ 4 — T1. После завершения транзакции.
COMMIT;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_16_Player';
