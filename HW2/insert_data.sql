-- ============================================================
-- HW2. Этап 3. Заполнение таблиц тестовыми данными (INSERT)
-- 3–5 записей в каждую таблицу. Порядок важен (внешние ключи).
-- ============================================================

-- 1) Teams (3 записи)
INSERT INTO Teams (name, region, foundation_date) VALUES
    ('Team Spirit',  'Eastern Europe',  '2015-10-01'),
    ('Team Secret',  'Western Europe',  '2014-11-20'),
    ('PSG.LGD',      'China',           '2017-04-09'),
    ('Team Liquid',  'Western Europe',  '2015-05-18');

-- 2) Players (5 записей)
INSERT INTO Players (nickname, rank, region, registration_date, team_id) VALUES
    ('Yatoro',     'Immortal', 'Eastern Europe', '2020-01-15', 1),
    ('Collapse',   'Immortal', 'Eastern Europe', '2020-03-02', 1),
    ('Miposhka',   'Divine',   'Eastern Europe', '2018-07-22', 1),
    ('Puppey',     'Immortal', 'Western Europe', '2014-12-01', 2),
    ('Ame',        'Immortal', 'China',          '2017-05-11', 3);

-- 3) Heroes (5 записей)
INSERT INTO Heroes (name, role, primary_attribute) VALUES
    ('Invoker',         'Mid Laner',    'INT'),
    ('Anti-Mage',       'Carry',        'AGI'),
    ('Pudge',           'Support/Roamer','STR'),
    ('Crystal Maiden',  'Support',      'INT'),
    ('Faceless Void',   'Carry',        'AGI');

-- 4) Items (5 записей)
INSERT INTO Items (name, cost, description) VALUES
    ('Black King Bar',   4050, 'Даёт иммунитет к большинству заклинаний'),
    ('Aghanim''s Scepter', 4200, 'Улучшает способности героя'),
    ('Blink Dagger',     2250, 'Телепортация на небольшое расстояние'),
    ('Tango',            90,   'Восстанавливает здоровье, поедая дерево'),
    ('Town Portal Scroll', 50, 'Возвращает к фонтану или зданию');

-- 5) Matches (4 записи)
INSERT INTO Matches (duration_sec, winner_side, game_mode, match_date, radiant_team_id, dire_team_id) VALUES
    (3420, 'Radiant', 'Captain''s Mode', '2024-03-04', 1, 2),
    (2775, 'Radiant', 'Captain''s Mode', '2024-03-04', 2, 1),  -- ошибочный результат (исправит UPDATE)
    (3105, 'Radiant', 'All Pick',        '2024-03-10', 1, 3),
    (2900, 'Dire',    'Captain''s Mode', '2024-03-12', 3, 4);

-- 6) PlayerMatchStats (5 записей) — статистика игроков в матчах
INSERT INTO PlayerMatchStats (player_id, match_id, hero_id, kills, deaths, assists, gold_earned, total_xp) VALUES
    (1, 1, 2, 12, 3, 6, 28500, 34000),  -- Yatoro (Anti-Mage) в матче 1
    (2, 1, 1,  8, 5, 9, 26400, 31800),  -- Collapse (Invoker) в матче 1
    (3, 1, 4,  2, 6, 17, 15700, 22300), -- Miposhka (CM) в матче 1
    (4, 1, 3,  5, 7, 11, 19800, 24700), -- Puppey (Pudge) в матче 1
    (1, 2, 1, 15, 4, 8, 31200, 36500);  -- Yatoro (Invoker) в матче 2

-- 7) PlayerMatchItems (5 записей) — предметы, купленные в матчах
INSERT INTO PlayerMatchItems (player_id, match_id, item_id, slot_index) VALUES
    (1, 1, 1, 1),   -- Yatoro купил BKB первым
    (1, 1, 2, 2),   -- Yatoro купил Aghanim''s Scepter вторым
    (2, 1, 3, 1),   -- Collapse купил Blink Dagger
    (4, 1, 4, 1),   -- Puppey купил Tango
    (1, 2, 1, 1);   -- Yatoro (матч 2) купил BKB