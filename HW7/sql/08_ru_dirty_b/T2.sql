-- 08_ru_dirty_b: READ UNCOMMITTED: грязное чтение, MMR игрока
-- T2. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 2 — T2. Начать независимую читающую транзакцию.
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SHOW transaction_isolation;

-- ШАГ 3 — T2. Читается старое подтверждённое значение, без ожидания UPDATE.
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_08_Player';

-- ШАГ 5 — T2. Повторное чтение.
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_08_Player';

-- ШАГ 6 — T2. Завершить T2.
COMMIT;
