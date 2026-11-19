-- 10_rc_dirty_b: READ COMMITTED: грязное чтение, MMR игрока
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Оставить транзакцию открытой, не нажимать COMMIT.
BEGIN;
UPDATE nf.Players SET mmr = 9000 WHERE nickname = 'HW7_TX_10_Player';

-- ШАГ 4 — T1. Завершить T1 через COMMIT.
COMMIT;
