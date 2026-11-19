-- Подготовка только собственных строк HW7_TX_ в существующих таблицах nf.
-- Исходные строки HW2-HW6 не изменяются. Можно повторять после закрытия всех T1/T2.
-- Повторная подготовка удаляет результаты прошлых опытов HW7_TX_.
BEGIN;
DO $$
BEGIN
    IF to_regclass('nf.players') IS NULL OR to_regclass('nf.teams') IS NULL
       OR to_regclass('nf.items') IS NULL OR to_regclass('nf.matches') IS NULL
       OR to_regclass('nf.gamemodes') IS NULL OR to_regclass('nf.regions') IS NULL THEN
        RAISE EXCEPTION 'Нужна нормализованная схема nf из HW3. Не запускайте пересоздание схемы в заполненной базе.';
    END IF;
END $$;
-- Удаляются только демонстрационные строки HW7_TX_.
-- Выполнять после завершения всех T1/T2; чужие данные и последовательности не сбрасываются.
DELETE FROM nf.Players WHERE left(nickname, 7) = 'HW7_TX_';
DELETE FROM nf.Teams WHERE left(name, 7) = 'HW7_TX_';
DELETE FROM nf.Items WHERE left(name, 7) = 'HW7_TX_';
DELETE FROM nf.Matches WHERE game_mode_id IN
    (SELECT game_mode_id FROM nf.GameModes WHERE left(mode_name, 7) = 'HW7_TX_');
DELETE FROM nf.GameModes WHERE left(mode_name, 7) = 'HW7_TX_';
DELETE FROM nf.Regions WHERE left(region_name, 7) = 'HW7_TX_';
INSERT INTO nf.Regions (region_name) VALUES ('HW7_TX_02_Region');
INSERT INTO nf.Regions (region_name) VALUES ('HW7_TX_04_Region');
INSERT INTO nf.Regions (region_name) VALUES ('HW7_TX_06_Region');
INSERT INTO nf.Teams (name, foundation_date) VALUES ('HW7_TX_01_Team', DATE '2000-01-01');
INSERT INTO nf.Teams (name, foundation_date) VALUES ('HW7_TX_03_Team', DATE '2000-01-01');
INSERT INTO nf.Teams (name, foundation_date) VALUES ('HW7_TX_05_Team', DATE '2000-01-01');
INSERT INTO nf.Teams (name, foundation_date) VALUES ('HW7_TX_13_Team', DATE '2000-01-01');
INSERT INTO nf.Teams (name, foundation_date) VALUES ('HW7_TX_17_Team', DATE '2000-01-01');
INSERT INTO nf.Teams (name, foundation_date) VALUES ('HW7_TX_23_Team', DATE '2000-01-01');
INSERT INTO nf.Players (nickname, mmr, team_id) VALUES ('HW7_TX_08_Player', 8000, NULL);
INSERT INTO nf.Players (nickname, mmr, team_id) VALUES ('HW7_TX_10_Player', 8000, NULL);
INSERT INTO nf.Players (nickname, mmr, team_id) VALUES ('HW7_TX_12_Player', 8000, NULL);
INSERT INTO nf.Players (nickname, mmr, team_id) VALUES ('HW7_TX_16_Player', 8000, NULL);
INSERT INTO nf.Players (nickname, mmr, team_id) VALUES ('HW7_TX_13_Base', 8000, (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team'));
INSERT INTO nf.Players (nickname, mmr, team_id) VALUES ('HW7_TX_17_Base', 8000, (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_17_Team'));
INSERT INTO nf.Players (nickname, mmr, team_id) VALUES ('HW7_TX_22_Player', 8000, NULL);
INSERT INTO nf.Items (name, cost, description) VALUES ('HW7_TX_07_Item', 100, 'HW7_TX_demo');
INSERT INTO nf.Items (name, cost, description) VALUES ('HW7_TX_09_Item', 100, 'HW7_TX_demo');
INSERT INTO nf.Items (name, cost, description) VALUES ('HW7_TX_11_Item', 100, 'HW7_TX_demo');
INSERT INTO nf.Items (name, cost, description) VALUES ('HW7_TX_15_Item', 100, 'HW7_TX_demo');
INSERT INTO nf.Items (name, cost, description) VALUES ('HW7_TX_14_Item', 100, 'HW7_TX_14_Group');
INSERT INTO nf.Items (name, cost, description) VALUES ('HW7_TX_18_Item', 100, 'HW7_TX_18_Group');
INSERT INTO nf.Items (name, cost, description) VALUES ('HW7_TX_21_Item', 100, 'HW7_TX_demo');
INSERT INTO nf.Items (name, cost, description) VALUES ('HW7_TX_24_Item', 100, 'HW7_TX_demo');
INSERT INTO nf.GameModes (mode_name) VALUES ('HW7_TX_19_Mode');
INSERT INTO nf.GameModes (mode_name) VALUES ('HW7_TX_20_Mode');
COMMIT;

SELECT 'teams' AS table_name, count(*) AS demo_rows FROM nf.Teams WHERE left(name, 7) = 'HW7_TX_'
UNION ALL SELECT 'players', count(*) FROM nf.Players WHERE left(nickname, 7) = 'HW7_TX_'
UNION ALL SELECT 'items', count(*) FROM nf.Items WHERE left(name, 7) = 'HW7_TX_'
UNION ALL SELECT 'regions', count(*) FROM nf.Regions WHERE left(region_name, 7) = 'HW7_TX_'
UNION ALL SELECT 'gamemodes', count(*) FROM nf.GameModes WHERE left(mode_name, 7) = 'HW7_TX_';
