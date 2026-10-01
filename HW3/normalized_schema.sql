-- ============================================================
-- HW3. Этап 1. Нормализованная схема (3НФ / НФБК)
-- Предметная область: Dota 2 (продолжение HW1, HW2)
-- СУБД: PostgreSQL 16
--
-- Все отношения приведены к 3НФ, а отношения с пересекающимися
-- ключами — дополнительно проверены на НФБК. Обоснование
-- для каждой таблицы — в normal_forms.md.
--
-- Нормализованные объекты размещаются в схеме nf, чтобы не
-- конфликтовать с таблицами HW2 (teams, players, ...), которые
-- остаются в public как есть для сравнения.
-- ============================================================

DROP SCHEMA IF EXISTS nf CASCADE;
CREATE SCHEMA nf;
SET search_path TO nf, public;

-- Порядок удаления — от зависимых к независимым (CASCADE страхует)
DROP TABLE IF EXISTS nf.PlayerInventory   CASCADE;
DROP TABLE IF EXISTS nf.PlayerMatchStats CASCADE;
DROP TABLE IF EXISTS nf.MatchTeams       CASCADE;
DROP TABLE IF EXISTS nf.Matches          CASCADE;
DROP TABLE IF EXISTS nf.GameModes        CASCADE;
DROP TABLE IF EXISTS nf.HeroRoles        CASCADE;
DROP TABLE IF EXISTS nf.Heroes           CASCADE;
DROP TABLE IF EXISTS nf.Roles            CASCADE;
DROP TABLE IF EXISTS nf.Attributes       CASCADE;
DROP TABLE IF EXISTS nf.Items            CASCADE;
DROP TABLE IF EXISTS nf.Players          CASCADE;
DROP TABLE IF EXISTS nf.Teams            CASCADE;
DROP TABLE IF EXISTS nf.Regions          CASCADE;
DROP TABLE IF EXISTS nf.Ranks            CASCADE;

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