-- ============================================================
-- HW2. Этап 4. Изменение данных (UPDATE)
-- 5 запросов
-- ============================================================

-- 1) Повышаем рейтинг MMR и ранг игрока Yatoro (он сыграл лучший матч)
UPDATE Players
SET rank = 'Immortal',
    mmr  = 12500
WHERE nickname = 'Yatoro';

-- 2) Исправляем ошибку в результате матча: у матча 2 победила сторона Dire
UPDATE Matches
SET winner_side = 'Dire'
WHERE match_id = 2;

-- 3) Повышаем цену предмета Tango на 10 золота
UPDATE Items
SET cost = cost + 10
WHERE name = 'Tango';

-- 4) Увеличиваем количество убийств игрока Collapse в матче 1 на 1
UPDATE PlayerMatchStats
SET kills = kills + 1
WHERE player_id = 2 AND match_id = 1;

-- 5) Меняем регион команды Team Secret на 'Western Europe (EU)'
UPDATE Teams
SET region = 'Western Europe (EU)'
WHERE name = 'Team Secret';

-- Устанавливаем MMR для остальных игроков (заполняем новый столбец)
UPDATE Players
SET mmr = 9800
WHERE mmr IS NULL;