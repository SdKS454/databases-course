-- 21_serial_update_a: SERIALIZABLE: конкурентное обновление цены
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Создать снимок T1.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_21_Item';

-- ШАГ 3 — T1. Первое обновление фиксируется.
UPDATE nf.Items SET cost = cost + 10 WHERE name = 'HW7_TX_21_Item';
COMMIT;

-- ШАГ 8 — T1. Обе прибавки сохранены.
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_21_Item';
