-- HW6. CTE, UNION/INTERSECT/EXCEPT и оконные функции.
-- PostgreSQL 16.15; таблицы nf из HW3.
-- Сначала выполнить cte_demo_data.sql (добавляет учебные данные без перезаписи старых).
-- 21 запрос. Можно запускать по номерам в pgAdmin Query Tool или весь файл.
-- Файл содержит только чтение данных; команды psql не используются.

-- 1.1. CTE — команды со средним MMR от 10000
-- Найти команды, у которых средний MMR игроков не меньше 10000.
WITH team_mmr AS (
    SELECT p.team_id, count(*) AS players_count, avg(p.mmr) AS avg_mmr
    FROM nf.Players p
    GROUP BY p.team_id
)
SELECT t.name AS team_name, tm.players_count, round(tm.avg_mmr, 2) AS avg_mmr
FROM team_mmr tm
JOIN nf.Teams t ON t.team_id = tm.team_id
WHERE tm.avg_mmr >= 10000
ORDER BY tm.avg_mmr DESC, t.name;

-- 1.2. CTE — игроки выше средней суммы убийств
-- Найти игроков, сумма убийств которых больше средней суммы по игрокам с записанной статистикой.
WITH player_totals AS (
    SELECT s.player_id, sum(s.kills) AS total_kills
    FROM nf.PlayerMatchStats s
    GROUP BY s.player_id
), benchmark AS (
    SELECT avg(total_kills) AS avg_total FROM player_totals
)
SELECT p.nickname, pt.total_kills, round(b.avg_total, 2) AS avg_total
FROM player_totals pt
JOIN nf.Players p ON p.player_id = pt.player_id
CROSS JOIN benchmark b
WHERE pt.total_kills > b.avg_total
ORDER BY pt.total_kills DESC, p.nickname;

-- 1.3. Рекурсивное CTE — связи команд через матчи
-- Найти команды, достижимые от HW6_Academy по цепочке общих матчей, и минимальное число переходов.
WITH RECURSIVE edges AS (
    SELECT DISTINCT a.team_id AS src, b.team_id AS dst
    FROM nf.MatchTeams a
    JOIN nf.MatchTeams b ON b.match_id = a.match_id AND b.team_id <> a.team_id
), paths AS (
    SELECT t.team_id, 0 AS hops, ARRAY[t.team_id] AS path
    FROM nf.Teams t
    WHERE t.name = 'HW6_Academy'
    UNION ALL
    SELECT e.dst, p.hops + 1, p.path || e.dst
    FROM paths p
    JOIN edges e ON e.src = p.team_id
    WHERE NOT (e.dst = ANY (p.path))
)
SELECT t.name AS team_name, min(p.hops) AS min_hops
FROM paths p
JOIN nf.Teams t ON t.team_id = p.team_id
WHERE p.hops > 0
GROUP BY t.team_id, t.name
ORDER BY min_hops, t.name;

-- 2.1. UNION — регионы команд или игроков
-- Вывести уникальные названия регионов, используемых командами или игроками.
SELECT r.region_name
FROM nf.Teams t
JOIN nf.Regions r ON r.region_id = t.region_id
UNION
SELECT r.region_name
FROM nf.Players p
JOIN nf.Regions r ON r.region_id = p.region_id
ORDER BY region_name;

-- 2.2. INTERSECT — игроки со статистикой и покупками
-- Найти игроков, которые присутствуют и в индивидуальной статистике, и в инвентаре.
SELECT p.nickname
FROM nf.Players p
JOIN nf.PlayerMatchStats s ON s.player_id = p.player_id
INTERSECT
SELECT p.nickname
FROM nf.Players p
JOIN nf.PlayerInventory pi ON pi.player_id = p.player_id
ORDER BY nickname;

-- 2.3. EXCEPT — игроки без статистики
-- Найти зарегистрированных игроков, для которых нет ни одной записи статистики.
SELECT p.nickname FROM nf.Players p
EXCEPT
SELECT p.nickname
FROM nf.Players p
JOIN nf.PlayerMatchStats s ON s.player_id = p.player_id
ORDER BY nickname;

-- 3.1. PARTITION BY — средний MMR команды
-- Показать каждого игрока, размер его состава и средний MMR команды без сворачивания строк.
SELECT p.nickname, t.name AS team_name, p.mmr,
       count(*) OVER (PARTITION BY p.team_id) AS players_count,
       round(avg(p.mmr) OVER (PARTITION BY p.team_id), 2) AS team_avg_mmr
FROM nf.Players p
LEFT JOIN nf.Teams t ON t.team_id = p.team_id
ORDER BY t.name NULLS LAST, p.nickname;

-- 3.2. PARTITION BY — доля убийств выступления
-- Для каждой записи статистики показать сумму убийств игрока и долю текущего выступления в этой сумме.
SELECT p.nickname, s.match_id, s.kills,
       sum(s.kills) OVER (PARTITION BY s.player_id) AS player_total_kills,
       round(100.0 * s.kills /
             nullif(sum(s.kills) OVER (PARTITION BY s.player_id), 0), 2) AS kill_share_pct
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
ORDER BY p.nickname, s.match_id;

-- 4.1. PARTITION BY + ORDER BY — накопленные убийства
-- Показать, как накапливаются убийства HW6_Atlas и HW6_Boreal по их матчам.
SELECT p.nickname, m.match_date, m.duration_sec, s.kills,
       sum(s.kills) OVER (
           PARTITION BY s.player_id
           ORDER BY m.match_date, m.duration_sec, m.match_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_kills
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Matches m ON m.match_id = s.match_id
WHERE p.nickname IN ('HW6_Atlas', 'HW6_Boreal')
ORDER BY p.nickname, m.match_date, m.duration_sec, m.match_id;

-- 4.2. PARTITION BY + ORDER BY — накопленные победы
-- Для каждого матча HW6_Academy показать число побед команды с начала её записанной истории.
SELECT t.name AS team_name, m.match_date, m.duration_sec, mt.is_winner,
       sum(CASE WHEN mt.is_winner THEN 1 ELSE 0 END) OVER (
           PARTITION BY mt.team_id
           ORDER BY m.match_date, m.duration_sec, m.match_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_wins
FROM nf.MatchTeams mt
JOIN nf.Teams t ON t.team_id = mt.team_id
JOIN nf.Matches m ON m.match_id = mt.match_id
WHERE t.name = 'HW6_Academy'
ORDER BY m.match_date, m.duration_sec, m.match_id;

-- 5.1. ROWS — среднее за текущее и предыдущее выступление
-- Для HW6_Atlas посчитать скользящее среднее убийств по текущему и одному предыдущему выступлению.
SELECT p.nickname, m.match_date, m.duration_sec, s.kills,
       round(avg(s.kills) OVER (
           PARTITION BY s.player_id
           ORDER BY m.match_date, m.duration_sec, m.match_id
           ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
       ), 2) AS moving_avg_kills
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Matches m ON m.match_id = s.match_id
WHERE p.nickname = 'HW6_Atlas'
ORDER BY m.match_date, m.duration_sec, m.match_id;

-- 5.2. ROWS — сумма от текущего выступления до последнего
-- Для каждой строки HW6_Atlas посчитать сумму убийств в текущем и всех последующих записанных выступлениях.
SELECT p.nickname, m.match_date, m.duration_sec, s.kills,
       sum(s.kills) OVER (
           PARTITION BY s.player_id
           ORDER BY m.match_date, m.duration_sec, m.match_id
           ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
       ) AS remaining_kills
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Matches m ON m.match_id = s.match_id
WHERE p.nickname = 'HW6_Atlas'
ORDER BY m.match_date, m.duration_sec, m.match_id;

-- 6.1. RANGE — накопление с объединением одинаковых дат
-- Посчитать накопленные убийства HW6_Atlas до конца даты текущего матча.
SELECT p.nickname, m.match_date, m.duration_sec, s.kills,
       sum(s.kills) OVER (
           PARTITION BY s.player_id
           ORDER BY m.match_date
           RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS kills_through_date
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Matches m ON m.match_id = s.match_id
WHERE p.nickname = 'HW6_Atlas'
ORDER BY m.match_date, m.duration_sec, m.match_id;

-- 6.2. RANGE — сумма за текущую и предыдущую дату
-- Для HW6_Atlas посчитать убийства в диапазоне от предыдущей календарной даты до текущей включительно.
SELECT p.nickname, m.match_date, m.duration_sec, s.kills,
       sum(s.kills) OVER (
           PARTITION BY s.player_id
           ORDER BY m.match_date
           RANGE BETWEEN INTERVAL '1 day' PRECEDING AND CURRENT ROW
       ) AS kills_in_date_range
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Matches m ON m.match_id = s.match_id
WHERE p.nickname = 'HW6_Atlas'
ORDER BY m.match_date, m.duration_sec, m.match_id;

-- 7.1. ROW_NUMBER — уникальный номер игрока по MMR
-- Пронумеровать игроков HW6_Academy по убыванию MMR.
SELECT p.nickname, p.mmr,
       row_number() OVER (
           PARTITION BY p.team_id ORDER BY p.mmr DESC, p.nickname, p.player_id
       ) AS row_num
FROM nf.Players p
JOIN nf.Teams t ON t.team_id = p.team_id
WHERE t.name = 'HW6_Academy'
ORDER BY row_num;

-- 7.2. RANK — места с пропусками
-- Распределить игроков HW6_Academy по местам по MMR с одинаковым местом при равенстве.
SELECT p.nickname, p.mmr,
       rank() OVER (PARTITION BY p.team_id ORDER BY p.mmr DESC) AS mmr_rank
FROM nf.Players p
JOIN nf.Teams t ON t.team_id = p.team_id
WHERE t.name = 'HW6_Academy'
ORDER BY mmr_rank, p.nickname;

-- 7.3. DENSE_RANK — места без пропусков
-- Распределить игроков HW6_Academy по плотным местам по MMR.
SELECT p.nickname, p.mmr,
       dense_rank() OVER (PARTITION BY p.team_id ORDER BY p.mmr DESC) AS dense_mmr_rank
FROM nf.Players p
JOIN nf.Teams t ON t.team_id = p.team_id
WHERE t.name = 'HW6_Academy'
ORDER BY dense_mmr_rank, p.nickname;

-- 8.1. LAG — изменение убийств относительно предыдущего матча
-- Для HW6_Atlas показать убийства в предыдущем выступлении и разницу с текущим.
WITH history AS (
    SELECT p.nickname, m.match_date, m.duration_sec, m.match_id, s.kills,
           lag(s.kills) OVER (
               PARTITION BY s.player_id
               ORDER BY m.match_date, m.duration_sec, m.match_id
           ) AS prev_kills
    FROM nf.PlayerMatchStats s
    JOIN nf.Players p ON p.player_id = s.player_id
    JOIN nf.Matches m ON m.match_id = s.match_id
    WHERE p.nickname = 'HW6_Atlas'
)
SELECT nickname, match_date, duration_sec, kills, prev_kills,
       kills - prev_kills AS kills_change
FROM history
ORDER BY match_date, duration_sec, match_id;

-- 8.2. LEAD — убийства в следующем матче
-- Для HW6_Atlas показать число убийств в следующем записанном выступлении.
SELECT p.nickname, m.match_date, m.duration_sec, s.kills,
       lead(s.kills) OVER (
           PARTITION BY s.player_id
           ORDER BY m.match_date, m.duration_sec, m.match_id
       ) AS next_kills
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Matches m ON m.match_id = s.match_id
WHERE p.nickname = 'HW6_Atlas'
ORDER BY m.match_date, m.duration_sec, m.match_id;

-- 8.3. FIRST_VALUE — результат первого выступления
-- Для каждого выступления HW6_Atlas показать его первое число убийств в записанной истории.
SELECT p.nickname, m.match_date, m.duration_sec, s.kills,
       first_value(s.kills) OVER (
           PARTITION BY s.player_id
           ORDER BY m.match_date, m.duration_sec, m.match_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS first_kills
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Matches m ON m.match_id = s.match_id
WHERE p.nickname = 'HW6_Atlas'
ORDER BY m.match_date, m.duration_sec, m.match_id;

-- 8.4. LAST_VALUE — результат последнего выступления
-- Для каждого выступления HW6_Atlas показать его последнее число убийств в записанной истории.
SELECT p.nickname, m.match_date, m.duration_sec, s.kills,
       last_value(s.kills) OVER (
           PARTITION BY s.player_id
           ORDER BY m.match_date, m.duration_sec, m.match_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS last_kills
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
JOIN nf.Matches m ON m.match_id = s.match_id
WHERE p.nickname = 'HW6_Atlas'
ORDER BY m.match_date, m.duration_sec, m.match_id;
