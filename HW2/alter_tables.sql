-- ============================================================
-- HW2. Этап 2. Изменение структуры таблиц (ALTER TABLE)
-- 5 ALTER-запросов
-- ============================================================

-- 1) Добавляем новый столбец mmr (рейтинг MMR игрока)
ALTER TABLE Players
    ADD COLUMN mmr INT;

-- 2) Расширяем тип столбца rank: VARCHAR(20) -> VARCHAR(30)
ALTER TABLE Players
    ALTER COLUMN rank TYPE VARCHAR(30);

-- 3) Переименовываем столбец purchase_order -> slot_index
--    (порядковый номер предмета в ячейке инвентаря)
ALTER TABLE PlayerMatchItems
    RENAME COLUMN purchase_order TO slot_index;

-- 4) Добавляем ограничение CHECK: количество убийств не может быть отрицательным
ALTER TABLE PlayerMatchStats
    ADD CONSTRAINT check_kills_non_negative CHECK (kills >= 0);

-- 5) Уточняем тип описания предмета и добавляем значение по умолчанию
ALTER TABLE Items
    ALTER COLUMN description TYPE VARCHAR(200);
ALTER TABLE Items
    ALTER COLUMN description SET DEFAULT 'без описания';