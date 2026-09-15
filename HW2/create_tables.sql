-- ============================================================
-- HW2. Этап 1. Создание таблиц на основе ER-диаграммы (HW1)
-- СУБД: PostgreSQL 16
-- ВНИМАНИЕ: это «первая версия» структуры. Ряд колонок и
-- ограничений будет добавлен/изменён на этапе ALTER (alter_tables.sql).
-- ============================================================

DROP TABLE IF EXISTS PlayerMatchItems CASCADE;
DROP TABLE IF EXISTS PlayerMatchStats CASCADE;
DROP TABLE IF EXISTS Matches         CASCADE;
DROP TABLE IF EXISTS Items           CASCADE;
DROP TABLE IF EXISTS Heroes          CASCADE;
DROP TABLE IF EXISTS Players         CASCADE;
DROP TABLE IF EXISTS Teams           CASCADE;

-- Сущность: Команды
CREATE TABLE Teams (
    team_id         SERIAL PRIMARY KEY,
    name            VARCHAR(50)  NOT NULL UNIQUE,
    region          VARCHAR(30),
    foundation_date DATE
);

-- Сущность: Игроки
CREATE TABLE Players (
    player_id         SERIAL PRIMARY KEY,
    nickname          VARCHAR(30) NOT NULL UNIQUE,
    rank              VARCHAR(20) NOT NULL,
    region            VARCHAR(30),
    registration_date DATE        NOT NULL DEFAULT CURRENT_DATE,
    team_id           INT         REFERENCES Teams(team_id)
);

-- Сущность: Герои
CREATE TABLE Heroes (
    hero_id           SERIAL PRIMARY KEY,
    name              VARCHAR(30) NOT NULL UNIQUE,
    role              VARCHAR(40),
    primary_attribute VARCHAR(10) NOT NULL
);

-- Сущность: Матчи
CREATE TABLE Matches (
    match_id        SERIAL PRIMARY KEY,
    duration_sec    INT      NOT NULL,
    winner_side     VARCHAR(7) NOT NULL CHECK (winner_side IN ('Radiant', 'Dire')),
    game_mode       VARCHAR(30),
    match_date      DATE     NOT NULL DEFAULT CURRENT_DATE,
    radiant_team_id INT      REFERENCES Teams(team_id),
    dire_team_id    INT      REFERENCES Teams(team_id)
);

-- Сущность: Предметы
CREATE TABLE Items (
    item_id     SERIAL PRIMARY KEY,
    name        VARCHAR(40) NOT NULL UNIQUE,
    cost        INT  NOT NULL CHECK (cost >= 0),
    description TEXT
);

-- Сущность: Статистика игрока в матче
CREATE TABLE PlayerMatchStats (
    player_id   INT REFERENCES Players(player_id),
    match_id    INT REFERENCES Matches(match_id),
    hero_id     INT REFERENCES Heroes(hero_id),
    kills       INT NOT NULL,
    deaths      INT NOT NULL,
    assists     INT NOT NULL,
    gold_earned INT NOT NULL,
    total_xp    INT NOT NULL,
    PRIMARY KEY (player_id, match_id)
);

-- Сущность: Предметы, купленные игроком в матче
CREATE TABLE PlayerMatchItems (
    player_id      INT,
    match_id       INT,
    item_id        INT REFERENCES Items(item_id),
    purchase_order INT NOT NULL,
    PRIMARY KEY (player_id, match_id, item_id),
    FOREIGN KEY (player_id, match_id)
        REFERENCES PlayerMatchStats (player_id, match_id)
);