-- 15_rr_repeat_a: REPEATABLE READ: повторное чтение, цена предмета
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Первое чтение создаёт снимок.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_15_Item';

-- ШАГ 3 — T1. Повторить тот же SELECT.
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_15_Item';

-- ШАГ 4 — T1. После завершения транзакции.
COMMIT;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_15_Item';
