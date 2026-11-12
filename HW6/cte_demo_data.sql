-- HW6: дополнительные данные для CTE и оконных функций.
-- Запускать один раз перед cte_queries.sql в базе со схемой nf из HW3.
-- Повторный запуск не добавляет дубликаты. Старые строки не изменяются.
-- Имена HW6_* зарезервированы для этих учебных данных.
BEGIN;

INSERT INTO nf.Teams (name)
SELECT 'HW6_Academy'
WHERE NOT EXISTS (SELECT 1 FROM nf.Teams WHERE name = 'HW6_Academy');

INSERT INTO nf.Players (nickname, mmr, registration_date, team_id)
SELECT v.nickname, v.mmr, DATE '2026-10-01', t.team_id
FROM (VALUES ('HW6_Atlas', 11000), ('HW6_Boreal', 10000),
             ('HW6_Cinder', 10000), ('HW6_Delta', 9000)) AS v(nickname, mmr)
JOIN nf.Teams t ON t.name = 'HW6_Academy'
WHERE NOT EXISTS (SELECT 1 FROM nf.Players p WHERE p.nickname = v.nickname);

-- У Matches нет уникального естественного ключа. Для демонстрационных матчей
-- используем выделенные сочетания даты, длительности и режима All Pick.
INSERT INTO nf.Matches (match_date, duration_sec, game_mode_id)
SELECT v.match_date, v.duration_sec, gm.game_mode_id
FROM (VALUES (DATE '2026-11-01', 1801), (DATE '2026-11-01', 1802),
             (DATE '2026-11-02', 1803), (DATE '2026-11-04', 1804))
     AS v(match_date, duration_sec)
JOIN nf.GameModes gm ON gm.mode_name = 'All Pick'
WHERE NOT EXISTS (
    SELECT 1 FROM nf.Matches m
    WHERE m.match_date = v.match_date AND m.duration_sec = v.duration_sec
      AND m.game_mode_id = gm.game_mode_id
);

INSERT INTO nf.MatchTeams (match_id, team_id, side, is_winner)
SELECT m.match_id, t.team_id, v.side,
       CASE WHEN v.side = 'Radiant' THEN m.duration_sec IN (1801, 1804)
            ELSE m.duration_sec NOT IN (1801, 1804) END
FROM nf.Matches m
JOIN nf.GameModes gm ON gm.game_mode_id = m.game_mode_id
CROSS JOIN (VALUES ('HW6_Academy', 'Radiant'), ('Team Spirit', 'Dire'))
           AS v(team_name, side)
JOIN nf.Teams t ON t.name = v.team_name
WHERE gm.mode_name = 'All Pick'
  AND (m.match_date, m.duration_sec) IN (
      (DATE '2026-11-01', 1801), (DATE '2026-11-01', 1802),
      (DATE '2026-11-02', 1803), (DATE '2026-11-04', 1804))
  AND NOT EXISTS (
      SELECT 1 FROM nf.MatchTeams mt
      WHERE mt.match_id = m.match_id AND mt.team_id = t.team_id
  );

INSERT INTO nf.PlayerMatchStats
    (player_id, match_id, hero_id, kills, deaths, assists, gold_earned, total_xp)
SELECT p.player_id, m.match_id, h.hero_id, v.kills, 4, 7,
       10000 + v.kills * 1000, 15000 + v.kills * 1000
FROM (VALUES
    ('HW6_Atlas',  DATE '2026-11-01', 1801, 'Anti-Mage', 10),
    ('HW6_Atlas',  DATE '2026-11-01', 1802, 'Invoker',   14),
    ('HW6_Atlas',  DATE '2026-11-02', 1803, 'Anti-Mage',  6),
    ('HW6_Atlas',  DATE '2026-11-04', 1804, 'Invoker',   20),
    ('HW6_Boreal', DATE '2026-11-01', 1801, 'Invoker',    8),
    ('HW6_Boreal', DATE '2026-11-02', 1803, 'Invoker',   12),
    ('HW6_Cinder', DATE '2026-11-01', 1801, 'Pudge',      8),
    ('HW6_Delta',  DATE '2026-11-01', 1801, 'Crystal Maiden', 3)
) AS v(nickname, match_date, duration_sec, hero_name, kills)
JOIN nf.Players p ON p.nickname = v.nickname
JOIN nf.Matches m ON m.match_date = v.match_date AND m.duration_sec = v.duration_sec
JOIN nf.GameModes gm ON gm.game_mode_id = m.game_mode_id AND gm.mode_name = 'All Pick'
JOIN nf.Heroes h ON h.name = v.hero_name
WHERE NOT EXISTS (
    SELECT 1 FROM nf.PlayerMatchStats s
    WHERE s.player_id = p.player_id AND s.match_id = m.match_id
);

-- Проверки не дают молча завершить загрузку в неподходящую/изменённую схему.
DO $$
BEGIN
    IF (SELECT count(*) FROM nf.Players p JOIN nf.Teams t USING (team_id)
        WHERE t.name = 'HW6_Academy'
          AND p.nickname IN ('HW6_Atlas', 'HW6_Boreal', 'HW6_Cinder', 'HW6_Delta')) <> 4
    THEN RAISE EXCEPTION 'Не загружены четыре игрока HW6_Academy'; END IF;
    IF (SELECT count(*) FROM nf.PlayerMatchStats s
        JOIN nf.Players p USING (player_id)
        WHERE p.nickname IN ('HW6_Atlas', 'HW6_Boreal', 'HW6_Cinder', 'HW6_Delta')) <> 8
    THEN RAISE EXCEPTION 'Ожидалось 8 демонстрационных записей статистики'; END IF;
    IF EXISTS (
        SELECT 1 FROM nf.Matches m
        JOIN nf.MatchTeams mt USING (match_id)
        JOIN nf.Teams t USING (team_id)
        WHERE t.name = 'HW6_Academy'
          AND (SELECT count(*) FROM nf.MatchTeams all_mt
               WHERE all_mt.match_id = m.match_id AND all_mt.is_winner) <> 1
    ) THEN RAISE EXCEPTION 'У демонстрационного матча должно быть ровно по одному победителю';
    END IF;
END $$;

COMMIT;
