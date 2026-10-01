-- ============================================================
-- HW3. Этап 2. Перенос данных из схемы HW2 в нормализованную
-- СУБД: PostgreSQL 16
--
-- Скрипт читает старые таблицы из public (teams, players, heroes,
-- matches, items, playermatchstats, playermatchitems — в нижнем
-- регистре, как их создал PostgreSQL) и наполняет таблицы
-- схемы nf. Значения справочников выводятся из старых данных,
-- ничего не выдумывается.
--
-- Запуск: сначала normalized_schema.sql, затем этот файл.
-- ============================================================

SET search_path TO nf, public;

-- ============================================================
-- СПРАВОЧНИКИ
-- ============================================================

-- Регионы. Исходные значения нормализуются: 'Western Europe (EU)'
-- приводится к 'Western Europe'. В HW2 один и тот же регион был
-- записан двумя способами, поэтому прямое копирование дало бы
-- два разных региона.
INSERT INTO Regions (region_name)
SELECT DISTINCT
       regexp_replace(trim(t.region), '\s*\([^)]*\)\s*$', '') AS region_name
FROM public.teams t
WHERE t.region IS NOT NULL AND trim(t.region) <> ''
UNION
SELECT DISTINCT
       regexp_replace(trim(p.region), '\s*\([^)]*\)\s*$', '')
FROM public.players p
WHERE p.region IS NOT NULL AND trim(p.region) <> '';

-- Первичные атрибуты героев: код из HW2 + человекочитаемое имя.
INSERT INTO Attributes (attribute_code, attribute_name)
SELECT DISTINCT
       h.primary_attribute,
       CASE h.primary_attribute
           WHEN 'STR' THEN 'Сила'
           WHEN 'AGI' THEN 'Ловкость'
           WHEN 'INT' THEN 'Интеллект'
           ELSE h.primary_attribute
       END
FROM public.heroes h;

-- Роли. Составное значение 'Support/Roamer' из HW2 разбирается
-- на две отдельные роли.
INSERT INTO Roles (role_name)
SELECT DISTINCT trim(x.role)
FROM (
    SELECT unnest(string_to_array(h.role, '/')) AS role
    FROM public.heroes h
    WHERE h.role IS NOT NULL
) AS x
WHERE trim(x.role) <> '';

-- Режимы игры.
INSERT INTO GameModes (mode_name)
SELECT DISTINCT trim(m.game_mode)
FROM public.matches m
WHERE m.game_mode IS NOT NULL AND trim(m.game_mode) <> '';

-- Ранги. Лестница званий с диапазонами MMR — справочные данные
-- самой игры, а не вывод из конкретных игроков: диапазоны должны
-- быть известны заранее, иначе новый игрок с любым MMR не
-- попадёт ни в один диапазон. Верхняя граница Immortal открыта.
INSERT INTO Ranks (rank_name, min_mmr, max_mmr) VALUES
    ('Herald',     0,  2000),
    ('Guardian',   2000,  3000),
    ('Crusader',   3000,  4000),
    ('Archon',     4000,  5000),
    ('Legend',     5000,  6000),
    ('Ancient',    6000,  7000),
    ('Divine',     7000,  8000),
    ('Immortal',   8000,  100000);

-- ============================================================
-- ОСНОВНЫЕ СУЩНОСТИ
-- ============================================================

-- Регион приводится к тому же виду, что и в Regions, иначе
-- ссылка не найдётся.
INSERT INTO Teams (name, region_id, foundation_date)
SELECT t.name,
       r.region_id,
       t.foundation_date
FROM public.teams t
LEFT JOIN Regions r
       ON r.region_name = regexp_replace(trim(t.region), '\s*\([^)]*\)\s*$', '')
-- Регион ищется в объединённом справочнике команд и игроков,
-- LEFT JOIN по нормализованному имени.
ORDER BY t.team_id;

INSERT INTO Players (nickname, mmr, region_id, registration_date, team_id)
SELECT p.nickname,
       COALESCE(p.mmr, 0),
       r.region_id,
       p.registration_date,
       t_new.team_id
FROM public.players p
LEFT JOIN Regions r
       ON r.region_name = regexp_replace(trim(p.region), '\s*\([^)]*\)\s*$', '')
LEFT JOIN Teams t_old ON t_old.team_id = p.team_id
LEFT JOIN Teams t_new ON t_new.name = t_old.name;

INSERT INTO Heroes (name, primary_attribute)
SELECT h.name, h.primary_attribute
FROM public.heroes h;

INSERT INTO HeroRoles (hero_id, role_id)
SELECT h.hero_id, ro.role_id
FROM public.heroes h
CROSS JOIN LATERAL unnest(string_to_array(h.role, '/')) AS raw(role)
JOIN Roles ro ON ro.role_name = trim(raw.role)
WHERE h.role IS NOT NULL;

INSERT INTO Items (name, cost, description)
SELECT i.name, i.cost, i.description
FROM public.items i;

INSERT INTO Matches (duration_sec, game_mode_id, match_date)
SELECT m.duration_sec, gm.game_mode_id, m.match_date
FROM public.matches m
LEFT JOIN GameModes gm ON gm.mode_name = trim(m.game_mode);

-- Пара «матч — команда» строится из radiant_team_id и dire_team_id.
-- Победитель выражается флагом is_winner, а не отдельным полем
-- winner_side: победившая сторона определяется по названию колонки,
-- которое в базе не хранится.
INSERT INTO MatchTeams (match_id, team_id, side, is_winner)
SELECT m.match_id, tr.team_id, 'Radiant', m.winner_side = 'Radiant'
FROM public.matches m
JOIN public.teams t_old ON t_old.team_id = m.radiant_team_id
JOIN Teams tr          ON tr.name = t_old.name
UNION ALL
SELECT m.match_id, td.team_id, 'Dire', m.winner_side = 'Dire'
FROM public.matches m
JOIN public.teams t_old ON t_old.team_id = m.dire_team_id
JOIN Teams td          ON td.name = t_old.name;

INSERT INTO PlayerMatchStats
    (player_id, match_id, hero_id, kills, deaths, assists, gold_earned, total_xp)
SELECT s.player_id, s.match_id, s.hero_id,
       s.kills, s.deaths, s.assists, s.gold_earned, s.total_xp
FROM public.playermatchstats s;

-- Порядок покупки из HW2 становится номером слота и входит в ключ.
INSERT INTO PlayerInventory
    (player_id, match_id, slot_index, item_id, purchase_time_sec)
SELECT pi.player_id, pi.match_id, pi.slot_index, pi.item_id, NULL
FROM public.playermatchitems pi;

-- ============================================================
-- ОТЧЁТ О ДАННЫХ, КОТОРЫЕ НЕЛЬЗЯ ПЕРЕНЕСТИ МОЛЧА
-- ============================================================

-- В HW2 значения rank и mmr расходились: игрок Miposhka имел
-- rank = 'Divine' при mmr = 9800, что соответствует Immortal.
-- Ранг больше не хранится, поэтому «правильный» ранг выводится
-- из MMR, и старая ошибка исчезает сама. Такие расхождения
-- перечисляются, чтобы потеря не была молчаливой.
SELECT p.nickname,
       p.rank  AS rank_in_hw2,
       p.mmr,
       r.rank_name AS rank_by_mmr
FROM public.players p
JOIN Ranks r ON p.mmr >= r.min_mmr AND p.mmr < r.max_mmr
WHERE p.rank <> r.rank_name;

-- ============================================================
-- ПРОВЕРКА ЦЕЛОСТНОСТИ
-- ============================================================

DO $$
DECLARE
    lost_teams  INT;
    lost_players INT;
    lost_stats  INT;
    lost_items  INT;
    lost_heroes INT;
    bad_ranks   INT;
    bad_winners INT;
BEGIN
    SELECT count(*) INTO lost_teams
    FROM public.teams t
    WHERE NOT EXISTS (SELECT 1 FROM Teams n WHERE n.name = t.name);
    IF lost_teams > 0 THEN
        RAISE EXCEPTION 'потеряны команды: %', lost_teams;
    END IF;

    SELECT count(*) INTO lost_players
    FROM public.players p
    WHERE NOT EXISTS (SELECT 1 FROM Players n WHERE n.nickname = p.nickname);
    IF lost_players > 0 THEN
        RAISE EXCEPTION 'потеряны игроки: %', lost_players;
    END IF;

    SELECT count(*) INTO lost_heroes
    FROM public.heroes h
    WHERE NOT EXISTS (SELECT 1 FROM Heroes n WHERE n.name = h.name);
    IF lost_heroes > 0 THEN
        RAISE EXCEPTION 'потеряны герои: %', lost_heroes;
    END IF;

    SELECT count(*) INTO lost_stats
    FROM public.playermatchstats s
    WHERE NOT EXISTS (SELECT 1 FROM PlayerMatchStats n
                      WHERE n.player_id = s.player_id AND n.match_id = s.match_id);
    IF lost_stats > 0 THEN
        RAISE EXCEPTION 'потеряна статистика: %', lost_stats;
    END IF;

    SELECT count(*) INTO lost_items
    FROM public.playermatchitems pi
    WHERE NOT EXISTS (SELECT 1 FROM PlayerInventory n
                      WHERE n.player_id = pi.player_id
                        AND n.match_id  = pi.match_id
                        AND n.item_id   = pi.item_id);
    IF lost_items > 0 THEN
        RAISE EXCEPTION 'потеряны предметы: %', lost_items;
    END IF;

    -- Каждый игрок должен попадать ровно в один диапазон MMR.
    SELECT count(*) INTO bad_ranks
    FROM Players p
    WHERE NOT EXISTS (SELECT 1 FROM Ranks r
                      WHERE p.mmr >= r.min_mmr AND p.mmr < r.max_mmr);
    IF bad_ranks > 0 THEN
        RAISE EXCEPTION 'игроки вне диапазона рангов: %', bad_ranks;
    END IF;

    -- Ровно один победитель на каждый матч.
    SELECT count(*) INTO bad_winners
    FROM Matches m
    WHERE (SELECT count(*) FROM MatchTeams mt
           WHERE mt.match_id = m.match_id AND mt.is_winner) <> 1;
    IF bad_winners > 0 THEN
        RAISE EXCEPTION 'матчи без ровно одного победителя: %', bad_winners;
    END IF;

    RAISE NOTICE 'Проверка целостности пройдена.';
END $$;