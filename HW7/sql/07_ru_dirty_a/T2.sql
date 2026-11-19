-- 07_ru_dirty_a: READ UNCOMMITTED: грязное чтение, цена предмета
-- T2. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 2 — T2. Начать независимую читающую транзакцию.
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SHOW transaction_isolation;

-- ШАГ 3 — T2. Читается старое подтверждённое значение, без ожидания UPDATE.
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_07_Item';

-- ШАГ 5 — T2. Повторное чтение.
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_07_Item';

-- ШАГ 6 — T2. Завершить T2.
COMMIT;
