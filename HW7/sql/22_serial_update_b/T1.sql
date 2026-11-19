-- 22_serial_update_b: SERIALIZABLE: конкурентное обновление MMR
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Создать снимок T1.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_22_Player';

-- ШАГ 3 — T1. Первое обновление фиксируется.
UPDATE nf.Players SET mmr = mmr + 100 WHERE nickname = 'HW7_TX_22_Player';
COMMIT;

-- ШАГ 8 — T1. Обе прибавки сохранены.
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_22_Player';
