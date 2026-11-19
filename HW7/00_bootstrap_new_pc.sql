-- HW7: создание базы на другом ПК — таблицы и исходные данные HW3 + HW6.
-- Сначала выполнить CREATE DATABASE dota2_hw7; отдельно в базе postgres.
-- Затем открыть Query Tool ИМЕННО базы dota2_hw7 и выполнить этот файл целиком.
-- После него выполнить 01_prepare.sql для добавления строк экспериментов HW7_TX_.
-- Не содержит DROP. Если схема nf уже есть, скрипт остановится без её изменения.
-- Выполнять только один раз в новой учебной базе; не повторять в базе прошлых работ.
BEGIN;
DO $$
BEGIN
    IF to_regnamespace('nf') IS NOT NULL THEN
        RAISE EXCEPTION 'Схема nf уже существует. Ничего не пересоздано. Для повторения HW7 нужен 01_prepare.sql, а не этот файл.';
    END IF;
END $$;

CREATE SCHEMA nf;
SET search_path TO nf, public;

-- Таблицы создаются от справочников к зависимым сущностям.
-- ------------------------------------------------------------
-- СПРАВОЧНИКИ
-- ------------------------------------------------------------

-- Справочник регионов.
-- Устраняет аномалию «один и тот же регион записан по-разному»:
-- в HW2 встречались и 'Western Europe', и 'Western Europe (EU)'.
-- ФЗ: region_id -> region_name; region_name -> region_id (UNIQUE).
-- Оба атрибута — простые ключи, других зависимостей нет => НФБК.
CREATE TABLE Regions (
    region_id   SERIAL PRIMARY KEY,
    region_name VARCHAR(40) NOT NULL UNIQUE
);

-- Справочник рангов (игровых званий) с диапазонами MMR.
-- Устраняет транзитивную зависимость Players.rank <- Players.mmr
-- (ранг однозначно определяется диапазоном MMR).
-- ФЗ: rank_name -> min_mmr, max_mmr; min_mmr -> rank_name, max_mmr;
--     max_mmr -> rank_name, min_mmr.
-- Ключи-кандидаты: {rank_name}, {min_mmr}, {max_mmr} — все простые.
-- Каждая нетривиальная ФЗ имеет простой ключ слева => НФБК.
CREATE TABLE Ranks (
    rank_name VARCHAR(20) PRIMARY KEY,
    min_mmr   INT NOT NULL CHECK (min_mmr >= 0),
    max_mmr   INT NOT NULL CHECK (max_mmr > min_mmr),
    UNIQUE (min_mmr),
    UNIQUE (max_mmr)
);

-- Справочник первичных атрибутов героев.
-- Устраняет зависимость Heroes.attribute_name <- Heroes.primary_attribute.
CREATE TABLE Attributes (
    attribute_code VARCHAR(10) PRIMARY KEY,   -- STR / AGI / INT
    attribute_name VARCHAR(40) NOT NULL
);

-- Справочник ролей.
-- Существует отдельно, потому что роль — справочная величина,
-- повторяющаяся у многих героев.
CREATE TABLE Roles (
    role_id   SERIAL PRIMARY KEY,
    role_name VARCHAR(30) NOT NULL UNIQUE
);

-- Справочник режимов игры.
CREATE TABLE GameModes (
    game_mode_id SERIAL PRIMARY KEY,
    mode_name    VARCHAR(30) NOT NULL UNIQUE
);

-- ------------------------------------------------------------
-- ОСНОВНЫЕ СУЩНОСТИ
-- ------------------------------------------------------------

-- Команды.
-- ФЗ: team_id -> name, region_id, foundation_date.
-- Ключ-кандидат {team_id}; name — альтернативный ключ (UNIQUE).
-- Других зависимостей нет => НФБК.
CREATE TABLE Teams (
    team_id         SERIAL PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE,
    region_id       INT         REFERENCES Regions(region_id),
    foundation_date DATE
);

-- Игроки.
-- Столбец rank УДАЛЁН: он функционально зависит от mmr
-- (транзитивная зависимость через mmr — нарушение 3НФ в HW2).
-- Ранг вычисляется представлением v_players_with_rank.
-- ФЗ: player_id -> nickname, mmr, region_id, registration_date, team_id.
-- Ключи-кандидаты: {player_id}, {nickname}. Нетривиальных ФЗ,
-- кроме идущих от ключей, нет => НФБК.
CREATE TABLE Players (
    player_id         SERIAL PRIMARY KEY,
    nickname          VARCHAR(30) NOT NULL UNIQUE,
    mmr               INT NOT NULL DEFAULT 0 CHECK (mmr >= 0),
    region_id         INT REFERENCES Regions(region_id),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    team_id           INT REFERENCES Teams(team_id)
);

-- Герои.
-- Столбец role УДАЛЁН: в HW2 он содержал составное значение
-- 'Support/Roamer' — нарушение 1НФ. Роли вынесены в HeroRoles.
CREATE TABLE Heroes (
    hero_id           SERIAL PRIMARY KEY,
    name              VARCHAR(30) NOT NULL UNIQUE,
    primary_attribute VARCHAR(10) NOT NULL REFERENCES Attributes(attribute_code)
);

-- Связь «герой — роль» (M:N).
-- Устраняет 1НФ-нарушение составного атрибута Heroes.role.
CREATE TABLE HeroRoles (
    hero_id INT NOT NULL REFERENCES Heroes(hero_id),
    role_id INT NOT NULL REFERENCES Roles(role_id),
    PRIMARY KEY (hero_id, role_id)
);

-- Предметы.
CREATE TABLE Items (
    item_id     SERIAL PRIMARY KEY,
    name        VARCHAR(40) NOT NULL UNIQUE,
    cost        INT  NOT NULL CHECK (cost >= 0),
    description VARCHAR(200) DEFAULT 'без описания'
);

-- Матчи.
-- Столбцы radiant_team_id, dire_team_id, winner_side УДАЛЕНЫ:
-- это повторяющаяся группа (нарушение 1НФ) и дубль информации.
-- Состав участников — в MatchTeams, победитель отмечен флагом is_winner.
-- ФЗ: match_id -> duration_sec, game_mode_id, match_date.
-- Единственный ключ-кандидат {match_id} => НФБК.
CREATE TABLE Matches (
    match_id     SERIAL PRIMARY KEY,
    duration_sec INT  NOT NULL CHECK (duration_sec > 0),
    game_mode_id INT  REFERENCES GameModes(game_mode_id),
    match_date   DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Участники матча: команда + сторона + признак победы.
-- ФЗ: (match_id, team_id) -> side, is_winner;
--     (match_id, side)    -> team_id, is_winner.
-- Ключи-кандидаты: {match_id, team_id} и {match_id, side} —
-- они пересекаются. Обе ФЗ имеют ключ-кандидат слева => НФБК.
CREATE TABLE MatchTeams (
    match_id  INT     NOT NULL REFERENCES Matches(match_id),
    team_id   INT     NOT NULL REFERENCES Teams(team_id),
    side      VARCHAR(7) NOT NULL CHECK (side IN ('Radiant', 'Dire')),
    is_winner BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (match_id, team_id),
    UNIQUE (match_id, side)
);

-- Не более одного победителя на матч: частичный уникальный индекс
-- (CHECK-ограничение на уровне строки этого выразить не может).
CREATE UNIQUE INDEX ux_match_teams_one_winner
    ON MatchTeams (match_id) WHERE is_winner;

-- Статистика игрока в матче.
-- ФЗ: (player_id, match_id) -> hero_id, kills, deaths, assists,
--                            gold_earned, total_xp.
-- Никакой неключевой атрибут не зависит от части составного ключа
-- (=> 2НФ) и нет транзитивных зависимостей (=> 3НФ, НФБК).
CREATE TABLE PlayerMatchStats (
    player_id   INT NOT NULL REFERENCES Players(player_id),
    match_id    INT NOT NULL REFERENCES Matches(match_id),
    hero_id     INT NOT NULL REFERENCES Heroes(hero_id),
    kills       INT NOT NULL CHECK (kills >= 0),
    deaths      INT NOT NULL CHECK (deaths >= 0),
    assists     INT NOT NULL CHECK (assists >= 0),
    gold_earned INT NOT NULL CHECK (gold_earned >= 0),
    total_xp    INT NOT NULL CHECK (total_xp >= 0),
    PRIMARY KEY (player_id, match_id)
);

-- Инвентарь игрока в матче.
-- Ключ — (player_id, match_id, slot_index), потому что слот
-- однозначно идентифицирует предмет; item_id стал неключевым
-- атрибутом (в HW2 он был частью ключа, из-за чего один предмет
-- нельзя было купить дважды за матч).
-- ФЗ: (player_id, match_id, slot_index) -> item_id, purchase_time_sec;
--     (player_id, match_id, item_id)     -> slot_index, purchase_time_sec.
-- Обе ФЗ имеют ключ-кандидат слева => НФБК.
CREATE TABLE PlayerInventory (
    player_id         INT NOT NULL,
    match_id          INT NOT NULL,
    slot_index        INT NOT NULL CHECK (slot_index BETWEEN 1 AND 6),
    item_id           INT NOT NULL REFERENCES Items(item_id),
    purchase_time_sec INT,
    PRIMARY KEY (player_id, match_id, slot_index),
    UNIQUE (player_id, match_id, item_id),
    FOREIGN KEY (player_id, match_id)
        REFERENCES PlayerMatchStats (player_id, match_id)
);

-- ------------------------------------------------------------
-- ПРЕДСТАВЛЕНИЯ
-- ------------------------------------------------------------

-- Ранг игрока выводится из MMR — транзитивная зависимость
-- материализована в удобном виде, но не хранится в базе.
CREATE VIEW v_players_with_rank AS
SELECT p.player_id,
       p.nickname,
       p.mmr,
       r.rank_name
FROM Players p
JOIN Ranks r
  ON p.mmr >= r.min_mmr
 AND p.mmr <  r.max_mmr;

-- Итог матча: команды, их стороны и кто победил.
CREATE VIEW v_match_results AS
SELECT m.match_id,
       m.match_date,
       gm.mode_name,
       rt.name AS radiant_team,
       dt.name AS dire_team,
       CASE WHEN mt_r.is_winner THEN rt.name ELSE dt.name END AS winner
FROM Matches m
JOIN GameModes gm    ON gm.game_mode_id = m.game_mode_id
JOIN MatchTeams mt_r ON mt_r.match_id = m.match_id AND mt_r.side = 'Radiant'
JOIN MatchTeams mt_d ON mt_d.match_id = m.match_id AND mt_d.side = 'Dire'
JOIN Teams rt        ON rt.team_id = mt_r.team_id
JOIN Teams dt        ON dt.team_id = mt_d.team_id;

-- Исходные данные нормализованной схемы и дополнения HW6.

INSERT INTO nf."regions" ("region_id", "region_name") VALUES
    (1, 'China'),
    (2, 'Western Europe'),
    (3, 'Eastern Europe');

INSERT INTO nf."ranks" ("rank_name", "min_mmr", "max_mmr") VALUES
    ('Ancient', 6000, 7000),
    ('Archon', 4000, 5000),
    ('Crusader', 3000, 4000),
    ('Divine', 7000, 8000),
    ('Guardian', 2000, 3000),
    ('Herald', 0, 2000),
    ('Immortal', 8000, 100000),
    ('Legend', 5000, 6000);

INSERT INTO nf."attributes" ("attribute_code", "attribute_name") VALUES
    ('AGI', 'Ловкость'),
    ('INT', 'Интеллект'),
    ('STR', 'Сила');

INSERT INTO nf."roles" ("role_id", "role_name") VALUES
    (1, 'Mid Laner'),
    (2, 'Support'),
    (3, 'Carry'),
    (4, 'Roamer');

INSERT INTO nf."gamemodes" ("game_mode_id", "mode_name") VALUES
    (1, 'Captain''s Mode'),
    (2, 'All Pick');

INSERT INTO nf."teams" ("team_id", "name", "region_id", "foundation_date") VALUES
    (1, 'Team Spirit', 3, '2015-10-01'::date),
    (2, 'Team Secret', 2, '2014-11-20'::date),
    (3, 'PSG.LGD', 1, '2017-04-09'::date),
    (4, 'Team Liquid', 2, '2015-05-18'::date),
    (5, 'HW6_Academy', NULL, NULL);

INSERT INTO nf."players" ("player_id", "nickname", "mmr", "region_id", "registration_date", "team_id") VALUES
    (1, 'Yatoro', 12500, 3, '2020-01-15'::date, 1),
    (2, 'Collapse', 9800, 3, '2020-03-02'::date, 1),
    (3, 'Miposhka', 9800, 3, '2018-07-22'::date, 1),
    (4, 'Puppey', 9800, 2, '2014-12-01'::date, 2),
    (5, 'Ame', 9800, 1, '2017-05-11'::date, 3),
    (6, 'HW6_Boreal', 10000, NULL, '2026-10-01'::date, 5),
    (7, 'HW6_Cinder', 10000, NULL, '2026-10-01'::date, 5),
    (8, 'HW6_Atlas', 11000, NULL, '2026-10-01'::date, 5),
    (9, 'HW6_Delta', 9000, NULL, '2026-10-01'::date, 5);

INSERT INTO nf."heroes" ("hero_id", "name", "primary_attribute") VALUES
    (1, 'Invoker', 'INT'),
    (2, 'Anti-Mage', 'AGI'),
    (3, 'Pudge', 'STR'),
    (4, 'Crystal Maiden', 'INT'),
    (5, 'Faceless Void', 'AGI');

INSERT INTO nf."heroroles" ("hero_id", "role_id") VALUES
    (1, 1),
    (2, 3),
    (3, 2),
    (3, 4),
    (4, 2),
    (5, 3);

INSERT INTO nf."items" ("item_id", "name", "cost", "description") VALUES
    (1, 'Black King Bar', 4050, 'Даёт иммунитет к большинству заклинаний'),
    (2, 'Aghanim''s Scepter', 4200, 'Улучшает способности героя'),
    (3, 'Blink Dagger', 2250, 'Телепортация на небольшое расстояние'),
    (4, 'Town Portal Scroll', 50, 'Возвращает к фонтану или зданию'),
    (5, 'Tango', 100, 'Восстанавливает здоровье, поедая дерево');

INSERT INTO nf."matches" ("match_id", "duration_sec", "game_mode_id", "match_date") VALUES
    (1, 3420, 1, '2024-03-04'::date),
    (2, 3105, 2, '2024-03-10'::date),
    (3, 2900, 1, '2024-03-12'::date),
    (4, 2775, 1, '2024-03-04'::date),
    (5, 1802, 2, '2026-11-01'::date),
    (6, 1804, 2, '2026-11-04'::date),
    (7, 1803, 2, '2026-11-02'::date),
    (8, 1801, 2, '2026-11-01'::date);

INSERT INTO nf."matchteams" ("match_id", "team_id", "side", "is_winner") VALUES
    (1, 1, 'Radiant', true),
    (1, 2, 'Dire', false),
    (2, 1, 'Dire', true),
    (2, 2, 'Radiant', false),
    (3, 1, 'Radiant', true),
    (3, 3, 'Dire', false),
    (4, 3, 'Radiant', false),
    (4, 4, 'Dire', true),
    (5, 1, 'Dire', true),
    (5, 5, 'Radiant', false),
    (6, 1, 'Dire', false),
    (6, 5, 'Radiant', true),
    (7, 1, 'Dire', true),
    (7, 5, 'Radiant', false),
    (8, 1, 'Dire', false),
    (8, 5, 'Radiant', true);

INSERT INTO nf."playermatchstats" ("player_id", "match_id", "hero_id", "kills", "deaths", "assists", "gold_earned", "total_xp") VALUES
    (1, 1, 2, 12, 3, 6, 28500, 34000),
    (1, 2, 1, 15, 4, 8, 31200, 36500),
    (2, 1, 1, 9, 5, 9, 26400, 31800),
    (3, 1, 4, 2, 6, 17, 15700, 22300),
    (4, 1, 3, 5, 7, 11, 19800, 24700),
    (6, 7, 1, 12, 4, 7, 22000, 27000),
    (6, 8, 1, 8, 4, 7, 18000, 23000),
    (7, 8, 3, 8, 4, 7, 18000, 23000),
    (8, 5, 1, 14, 4, 7, 24000, 29000),
    (8, 6, 1, 20, 4, 7, 30000, 35000),
    (8, 7, 2, 6, 4, 7, 16000, 21000),
    (8, 8, 2, 10, 4, 7, 20000, 25000),
    (9, 8, 4, 3, 4, 7, 13000, 18000);

INSERT INTO nf."playerinventory" ("player_id", "match_id", "slot_index", "item_id", "purchase_time_sec") VALUES
    (1, 1, 1, 1, NULL),
    (1, 1, 2, 2, NULL),
    (1, 2, 1, 1, NULL),
    (2, 1, 1, 3, NULL),
    (4, 1, 1, 4, NULL);

-- Синхронизировать SERIAL после вставки исходных ID. Выполняется только в новой схеме.
SELECT setval(pg_get_serial_sequence('nf.gamemodes', 'game_mode_id'),
    COALESCE((SELECT max(game_mode_id) FROM nf.gamemodes), 1), EXISTS (SELECT 1 FROM nf.gamemodes));
SELECT setval(pg_get_serial_sequence('nf.heroes', 'hero_id'),
    COALESCE((SELECT max(hero_id) FROM nf.heroes), 1), EXISTS (SELECT 1 FROM nf.heroes));
SELECT setval(pg_get_serial_sequence('nf.items', 'item_id'),
    COALESCE((SELECT max(item_id) FROM nf.items), 1), EXISTS (SELECT 1 FROM nf.items));
SELECT setval(pg_get_serial_sequence('nf.matches', 'match_id'),
    COALESCE((SELECT max(match_id) FROM nf.matches), 1), EXISTS (SELECT 1 FROM nf.matches));
SELECT setval(pg_get_serial_sequence('nf.players', 'player_id'),
    COALESCE((SELECT max(player_id) FROM nf.players), 1), EXISTS (SELECT 1 FROM nf.players));
SELECT setval(pg_get_serial_sequence('nf.regions', 'region_id'),
    COALESCE((SELECT max(region_id) FROM nf.regions), 1), EXISTS (SELECT 1 FROM nf.regions));
SELECT setval(pg_get_serial_sequence('nf.roles', 'role_id'),
    COALESCE((SELECT max(role_id) FROM nf.roles), 1), EXISTS (SELECT 1 FROM nf.roles));
SELECT setval(pg_get_serial_sequence('nf.teams', 'team_id'),
    COALESCE((SELECT max(team_id) FROM nf.teams), 1), EXISTS (SELECT 1 FROM nf.teams));

COMMIT;

-- Должно быть 14 таблиц.
SELECT count(*) AS nf_tables FROM information_schema.tables WHERE table_schema='nf' AND table_type='BASE TABLE';
SELECT 'teams' AS table_name, count(*) FROM nf.Teams
UNION ALL SELECT 'players', count(*) FROM nf.Players
UNION ALL SELECT 'matches', count(*) FROM nf.Matches
UNION ALL SELECT 'items', count(*) FROM nf.Items;
