-- ============================================================
-- HW5. Агрегатные функции и группировка (GROUP BY / HAVING /
--       GROUPING SETS / ROLLUP / CUBE)
-- Предметная область: Dota 2 (схема nf из HW3)
-- СУБД: PostgreSQL
--
-- Запуск:
--   SET search_path TO nf, public;
--   \i HW2/create_tables.sql
--   \i HW2/alter_tables.sql
--   \i HW2/insert_data.sql
--   \i HW2/update_data.sql
--   \i HW3/normalized_schema.sql
--   \i HW3/migrate_to_nf.sql
--   \i HW5/queries.sql
-- ============================================================

SET search_path TO nf, public;


-- ============================================================
-- 1.1. Агрегатные функции COUNT(), SUM(), AVG(), MIN(), MAX()
--
-- Что хотим получить: сводку по всей статистике игроков —
-- сколько записей и сколько разных матчей/игроков попало
-- в PlayerMatchStats, суммарные и средние значения убийств,
-- минимум/максимум смертей и заработанного золота.
-- ============================================================
SELECT count(*)                    AS stat_rows,
       count(DISTINCT s.match_id)  AS matches_played,
       count(DISTINCT s.player_id) AS players,
       sum(s.kills)                AS total_kills,
       round(avg(s.kills), 2)      AS avg_kills,
       min(s.deaths)               AS min_deaths,
       max(s.deaths)               AS max_deaths,
       sum(s.gold_earned)          AS total_gold,
       min(s.gold_earned)          AS min_gold,
       max(s.gold_earned)          AS max_gold,
       round(avg(s.total_xp))      AS avg_xp
FROM nf.PlayerMatchStats s;


-- ============================================================
-- 1.2. STRING_AGG — склейка значений в одну строку
--
-- Что хотим получить: по каждой команде — число игроков,
-- минимальный/максимальный/средний MMR и весь состав
-- команды одной строкой через STRING_AGG.
-- Команда без игроков (Team Liquid) тоже попадает
-- в результат, но состав остаётся NULL.
-- ============================================================
SELECT t.name                                            AS team_name,
       count(p.player_id)                                AS players_count,
       min(p.mmr)                                        AS min_mmr,
       max(p.mmr)                                        AS max_mmr,
       round(avg(p.mmr))                                 AS avg_mmr,
       string_agg(p.nickname, ', ' ORDER BY p.nickname)  AS roster
FROM nf.Teams t
LEFT JOIN nf.Players p ON p.team_id = t.team_id
GROUP BY t.team_id, t.name
ORDER BY t.name;


-- ============================================================
-- 2.1. GROUP BY — агрегаты по группам
--
-- Что хотим получить: результативность каждой команды:
-- сколько строк статистики за ней записано, сколько
-- разных игроков играло, суммарные убийства и золото.
-- ============================================================
SELECT t.name                        AS team_name,
       count(*)                      AS stat_rows,
       count(DISTINCT p.player_id)   AS players,
       sum(s.kills)                  AS total_kills,
       sum(s.deaths)                 AS total_deaths,
       round(avg(s.kills), 2)        AS avg_kills,
       sum(s.gold_earned)            AS total_gold
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Teams   t ON t.team_id   = p.team_id
GROUP BY t.team_id, t.name
ORDER BY total_kills DESC, t.name;


-- ============================================================
-- 2.2. GROUP BY + HAVING — фильтр готовых групп
--
-- Что хотим получить: только тех героев, у которых среднее
-- число убийств за игру не меньше 8. WHERE отбрасывает
-- строки до группировки, HAVING — уже готовые группы.
-- ============================================================
SELECT h.name                    AS hero_name,
       a.attribute_name          AS attribute,
       count(*)                  AS games_played,
       sum(s.kills)              AS total_kills,
       round(avg(s.kills), 1)    AS avg_kills,
       round(avg(s.gold_earned)) AS avg_gold
FROM nf.PlayerMatchStats s
JOIN nf.Heroes     h ON h.hero_id        = s.hero_id
JOIN nf.Attributes a ON a.attribute_code = h.primary_attribute
GROUP BY h.hero_id, h.name, a.attribute_name
HAVING round(avg(s.kills), 1) >= 8
ORDER BY avg_kills DESC, total_kills DESC, h.name;


-- ============================================================
-- 3.1. ROLLUP — промежуточные итоги «сверху вниз»
--
-- Что хотим получить: статистику команд в разрезе регионов
-- и итоги: по каждой команде, по каждому региону и общий
-- итог по всем регионам. GROUPING() показывает, какая часть
-- строки является итогом (1) и какая — обычным значением (0).
--
-- ROLLUP (r.region_name, t.name) — это сокращение для
--   GROUPING SETS ((r.region_name, t.name),
--                   (r.region_name),
--                   ())
-- ============================================================
SELECT CASE
           WHEN grouping(r.region_name) = 1
            AND grouping(t.name) = 1 THEN 'ВСЕ РЕГИОНЫ'
           WHEN grouping(t.name) = 1
                THEN 'ВСЕ КОМАНДЫ: ' || r.region_name
           ELSE r.region_name
       END                          AS region_or_total,
       CASE WHEN grouping(t.name) = 1
            THEN '(итог)' ELSE t.name END AS team_or_total,
       grouping(r.region_name)     AS g_region,
       grouping(t.name)            AS g_team,
       count(*)                    AS stat_rows,
       sum(s.kills)                AS total_kills,
       round(avg(s.kills), 1)      AS avg_kills,
       sum(s.gold_earned)          AS total_gold
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Teams   t ON t.team_id   = p.team_id
JOIN nf.Regions r ON r.region_id = t.region_id
GROUP BY ROLLUP (r.region_name, t.name)
ORDER BY grouping(r.region_name), r.region_name NULLS LAST,
         grouping(t.name),        t.name NULLS LAST;


-- ============================================================
-- 3.2. CUBE — все комбинации измерений
--
-- Что хотим получить: пересечение двух измерений
-- (режим игры × атрибут героя) с итогами по каждому измерению
-- и общим итогом.
--
-- CUBE (gm.mode_name, a.attribute_name) — это сокращение для
--   GROUPING SETS ((gm.mode_name, a.attribute_name),
--                   (gm.mode_name),
--                   (a.attribute_name),
--                   ())
-- ============================================================
SELECT CASE
           WHEN grouping(gm.mode_name) = 1
            AND grouping(a.attribute_name) = 1
                THEN 'ВСЕ РЕЖИМЫ И АТРИБУТЫ'
           WHEN grouping(a.attribute_name) = 1 THEN 'все атрибуты'
           WHEN grouping(gm.mode_name) = 1    THEN 'все режимы'
           ELSE gm.mode_name
       END                                 AS mode_or_total,
       CASE WHEN grouping(a.attribute_name) = 1
            THEN '(итог)' ELSE a.attribute_name END AS attribute_or_total,
       grouping(gm.mode_name)              AS g_mode,
       grouping(a.attribute_name)          AS g_attribute,
       count(*)                            AS stat_rows,
       sum(s.kills)                        AS total_kills,
       sum(s.gold_earned)                  AS total_gold
FROM nf.PlayerMatchStats s
JOIN nf.Matches   m  ON m.match_id      = s.match_id
JOIN nf.GameModes gm ON gm.game_mode_id = m.game_mode_id
JOIN nf.Heroes    h  ON h.hero_id       = s.hero_id
JOIN nf.Attributes a  ON a.attribute_code = h.primary_attribute
GROUP BY CUBE (gm.mode_name, a.attribute_name)
ORDER BY grouping(gm.mode_name),    gm.mode_name NULLS LAST,
         grouping(a.attribute_name), a.attribute_name NULLS LAST;


-- 3.2 (тот же отчёт, записанный явно через GROUPING SETS).
-- Результат полностью совпадает с CUBE — это развёрнутая
-- форма того же набора группировок.
SELECT COALESCE(gm.mode_name, 'все режимы')       AS mode_or_total,
       COALESCE(a.attribute_name, 'все атрибуты') AS attribute_or_total,
       count(*)      AS stat_rows,
       sum(s.kills)  AS total_kills,
       sum(s.gold_earned) AS total_gold
FROM nf.PlayerMatchStats s
JOIN nf.Matches   m  ON m.match_id      = s.match_id
JOIN nf.GameModes gm ON gm.game_mode_id = m.game_mode_id
JOIN nf.Heroes    h  ON h.hero_id       = s.hero_id
JOIN nf.Attributes a  ON a.attribute_code = h.primary_attribute
GROUP BY GROUPING SETS (
    (gm.mode_name, a.attribute_name),
    (gm.mode_name),
    (a.attribute_name),
    ()
)
ORDER BY 1, 2;


-- ============================================================
-- 4.1. SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY
--
-- Что хотим получить: команды, чьи игроки в каждой игре
-- набирали не меньше 5 убийств, с суммарными показателями.
-- WHERE отсекает слабые записи статистики, HAVING — группы,
-- которые не набрали нужного порога, ORDER BY — порядок вывода.
-- ============================================================
SELECT t.name                    AS team_name,
       r.region_name             AS region,
       count(*)                  AS stat_rows,
       sum(s.kills)              AS total_kills,
       sum(s.deaths)             AS total_deaths,
       sum(s.gold_earned)        AS total_gold,
       round(avg(s.gold_earned)) AS avg_gold
FROM nf.Teams t
JOIN nf.Regions r ON r.region_id = t.region_id
JOIN nf.Players p ON p.team_id   = t.team_id
JOIN nf.PlayerMatchStats s ON s.player_id = p.player_id
WHERE s.kills >= 5
GROUP BY t.team_id, t.name, r.region_name
HAVING sum(s.kills) >= 5
ORDER BY total_gold DESC, t.name;


-- ============================================================
-- 4.2. SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY
--
-- Что хотим получить: рейтинг игроков, у которых в каждой
-- игре KDA было положительным (kills >= deaths),
-- с разницей K/D и суммарным золотом.
-- ============================================================
SELECT p.nickname                       AS nickname,
       count(*)                         AS matches_played,
       sum(s.kills)                     AS total_kills,
       sum(s.deaths)                    AS total_deaths,
       sum(s.kills) - sum(s.deaths)     AS kd_diff,
       sum(s.assists)                   AS total_assists,
       sum(s.gold_earned)               AS total_gold,
       round(avg(s.total_xp))           AS avg_xp
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
WHERE s.kills >= s.deaths
GROUP BY p.player_id, p.nickname
HAVING sum(s.gold_earned) >= 25000
ORDER BY kd_diff DESC, total_gold DESC, p.nickname;