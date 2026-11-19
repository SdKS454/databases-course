-- 22_serial_update_b: SERIALIZABLE: конкурентное обновление MMR
-- T2. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 2 — T2. Создать снимок T2 до изменения строки.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_22_Player';

-- ШАГ 4 — T2. Ожидается именно ошибка concurrent update.
-- Ожидаемая ошибка SQLSTATE 40001; следующий шаг выполнить отдельно.
UPDATE nf.Players SET mmr = mmr + 200 WHERE nickname = 'HW7_TX_22_Player';

-- ШАГ 5 — T2. Закрыть неудачную транзакцию.
ROLLBACK;

-- ШАГ 6 — T2. Повторить транзакцию с самого начала.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_22_Player';

-- ШАГ 7 — T2. Повторное обновление на свежем снимке.
UPDATE nf.Players SET mmr = mmr + 200 WHERE nickname = 'HW7_TX_22_Player';
COMMIT;
