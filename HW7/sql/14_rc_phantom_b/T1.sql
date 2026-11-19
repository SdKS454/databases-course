-- 14_rc_phantom_b: READ COMMITTED: новый предмет в выборке
-- T1. Выполнять по одному пронумерованному шагу по порядку из transaction.md.
-- НЕ ЗАПУСКАТЬ ФАЙЛ ЦЕЛИКОМ: между шагами нужны команды другой сессии / обработка ошибок.

-- ШАГ 1 — T1. Первое чтение набора строк.
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_14_Group' AND cost >= 100;

-- ШАГ 3 — T1. Повторить тот же запрос.
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_14_Group' AND cost >= 100;

-- ШАГ 4 — T1. После завершения T1 новая строка видна.
COMMIT;
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_14_Group' AND cost >= 100;
