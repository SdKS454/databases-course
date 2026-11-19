-- 11_rc_repeat_a: READ COMMITTED: повторное чтение, цена предмета
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Первое чтение создаёт снимок.
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_11_Item';

-- ШАГ 3 — T1. Повторить тот же SELECT.
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_11_Item';

-- ШАГ 4 — T1. После завершения транзакции.
COMMIT;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_11_Item';
