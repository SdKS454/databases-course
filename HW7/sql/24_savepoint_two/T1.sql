-- 24_savepoint_two: SAVEPOINT: возврат ко второй и первой точкам
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Создать две точки.
BEGIN;
UPDATE nf.Items SET cost = 110 WHERE name = 'HW7_TX_24_Item';
SAVEPOINT first_point;
UPDATE nf.Items SET cost = 120 WHERE name = 'HW7_TX_24_Item';
SAVEPOINT second_point;
UPDATE nf.Items SET cost = 130 WHERE name = 'HW7_TX_24_Item';
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_24_Item';

-- ШАГ 2 — T1. Возврат ко второй.
ROLLBACK TO SAVEPOINT second_point;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_24_Item';

-- ШАГ 3 — T1. Возврат к первой.
ROLLBACK TO SAVEPOINT first_point;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_24_Item';

-- ШАГ 4 — T1. Сохранить результат.
RELEASE SAVEPOINT first_point;
COMMIT;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_24_Item';
