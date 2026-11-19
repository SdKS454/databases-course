-- 21_serial_update_a: SERIALIZABLE: конкурентное обновление цены
-- T2. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 2 — T2. Создать снимок T2 до изменения строки.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_21_Item';

-- ШАГ 4 — T2. Ожидается именно ошибка concurrent update.
-- Ожидаемая ошибка SQLSTATE 40001; следующий шаг выполнить отдельно.
UPDATE nf.Items SET cost = cost + 20 WHERE name = 'HW7_TX_21_Item';

-- ШАГ 5 — T2. Закрыть неудачную транзакцию.
ROLLBACK;

-- ШАГ 6 — T2. Повторить транзакцию с самого начала.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_21_Item';

-- ШАГ 7 — T2. Повторное обновление на свежем снимке.
UPDATE nf.Items SET cost = cost + 20 WHERE name = 'HW7_TX_21_Item';
COMMIT;
