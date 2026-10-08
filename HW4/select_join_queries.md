# Домашняя работа 4 — SELECT, CASE и JOIN

**Предметная область:** Dota 2 (схема `nf` из HW3)  
**СУБД:** PostgreSQL

Все запросы ниже рассчитаны на объекты из `HW3/normalized_schema.sql` и используют
схему `nf`. Перед выполнением установите `search_path` командой
`SET search_path TO nf, public;`.

В локальной базе PostgreSQL сервер доступен, но схема `nf` и данные HW3 не были
загружены, поэтому фактический запуск этих запросов невозможен. Ниже приведено
ожидаемое представление результата: конкретные значения зависят от данных,
перенесённых скриптом `HW3/migrate_to_nf.sql`.

## 1. SELECT с CASE

### 1.1. Определение ранга по MMR

```sql
SELECT p.player_id,
       p.nickname,
       p.mmr,
       CASE
           WHEN p.mmr >= 8000 THEN 'Immortal'
           WHEN p.mmr >= 7000 THEN 'Divine'
           WHEN p.mmr >= 6000 THEN 'Ancient'
           WHEN p.mmr >= 5000 THEN 'Legend'
           WHEN p.mmr >= 4000 THEN 'Archon'
           WHEN p.mmr >= 3000 THEN 'Crusader'
           WHEN p.mmr >= 2000 THEN 'Guardian'
           ELSE 'Herald'
       END AS rank_by_mmr
FROM nf.Players AS p
ORDER BY p.mmr DESC;
```

**Ожидаемый результат:** по одной строке на игрока; столбец `rank_by_mmr`
содержит ранг, выбранный по диапазону MMR. Например, игрок с MMR `9800`
получит значение `Immortal`.

### 1.2. Категория длительности матча

```sql
SELECT m.match_id,
       m.duration_sec,
       CASE
           WHEN m.duration_sec < 1800 THEN 'Короткий'
           WHEN m.duration_sec < 3000 THEN 'Средний'
           ELSE 'Длинный'
       END AS duration_category,
       gm.mode_name
FROM nf.Matches AS m
LEFT JOIN nf.GameModes AS gm
       ON gm.game_mode_id = m.game_mode_id
ORDER BY m.match_id;
```

**Ожидаемый результат:** по одной строке на матч, например `duration_sec = 1600`
будет представлен как `Короткий`, `2400` — как `Средний`, а `3600` — как
`Длинный`.

## 2. INNER JOIN

### 2.1. Команды и регионы

```sql
SELECT t.team_id,
       t.name AS team_name,
       r.region_name
FROM nf.Teams AS t
INNER JOIN nf.Regions AS r
        ON r.region_id = t.region_id
ORDER BY t.team_id;
```

**Ожидаемый результат:** только команды, для которых найден регион; каждая строка
содержит идентификатор и название команды и название её региона.

### 2.2. Статистика игроков и герои

```sql
SELECT s.match_id,
       p.nickname,
       h.name AS hero_name,
       s.kills,
       s.deaths,
       s.assists
FROM nf.PlayerMatchStats AS s
INNER JOIN nf.Players AS p
        ON p.player_id = s.player_id
INNER JOIN nf.Heroes AS h
        ON h.hero_id = s.hero_id
ORDER BY s.match_id, p.nickname;
```

**Ожидаемый результат:** только корректные записи статистики с существующими
игроком и героем; в результате видны K/D/A каждого игрока в матче.

## 3. LEFT JOIN

### 3.1. Все команды, включая команды без региона

```sql
SELECT t.team_id,
       t.name AS team_name,
       r.region_name
FROM nf.Teams AS t
LEFT JOIN nf.Regions AS r
       ON r.region_id = t.region_id
ORDER BY t.team_id;
```

**Ожидаемый результат:** присутствуют все команды. Если регион не задан, значение
`region_name` равно `NULL`.

### 3.2. Все игроки, включая игроков без команды

```sql
SELECT p.player_id,
       p.nickname,
       t.name AS team_name
FROM nf.Players AS p
LEFT JOIN nf.Teams AS t
       ON t.team_id = p.team_id
ORDER BY p.player_id;
```

**Ожидаемый результат:** присутствуют все игроки; для игрока без команды
`team_name` имеет значение `NULL`.

## 4. RIGHT JOIN

### 4.1. Все команды и их игроки

```sql
SELECT t.team_id,
       t.name AS team_name,
       p.nickname
FROM nf.Players AS p
RIGHT JOIN nf.Teams AS t
         ON t.team_id = p.team_id
ORDER BY t.team_id, p.nickname;
```

**Ожидаемый результат:** присутствуют все команды, в том числе без игроков; для
такой команды `nickname` равен `NULL`.

### 4.2. Все роли и связанные с ними герои

```sql
SELECT ro.role_id,
       ro.role_name,
       h.name AS hero_name
FROM nf.HeroRoles AS hr
RIGHT JOIN nf.Roles AS ro
         ON ro.role_id = hr.role_id
LEFT JOIN nf.Heroes AS h
       ON h.hero_id = hr.hero_id
ORDER BY ro.role_id, h.name;
```

**Ожидаемый результат:** присутствуют все роли. Если роль пока не связана ни с
одним героем, `hero_name` равен `NULL`.

## 5. CROSS JOIN

`CROSS JOIN` формирует декартово произведение: каждая строка первой таблицы
сочетается с каждой строкой второй таблицы.

### 5.1. Все сочетания режимов игры и рангов

```sql
SELECT gm.mode_name,
       r.rank_name
FROM nf.GameModes AS gm
CROSS JOIN nf.Ranks AS r
ORDER BY gm.mode_name, r.min_mmr;
```

**Ожидаемый результат:** при `M` режимах и `8` рангах будет `M * 8` строк,
например для каждого режима появится пара с `Herald`, `Guardian`, …, `Immortal`.

### 5.2. Сочетания команд и сторон матча

```sql
SELECT t.name AS team_name,
       side.side_name
FROM nf.Teams AS t
CROSS JOIN (
    VALUES ('Radiant'), ('Dire')
) AS side(side_name)
ORDER BY t.team_id, side.side_name;
```

**Ожидаемый результат:** для каждой команды будут две строки — одна с `Radiant`
и одна с `Dire`; при `N` командах результат содержит `2N` строк.

## 6. FULL OUTER JOIN

В PostgreSQL ключевое слово `OUTER` само по себе не является отдельным видом
соединения: запись `FULL OUTER JOIN` означает полное внешнее соединение
(`FULL JOIN`). Оно сохраняет строки обеих таблиц, даже если для них нет пары.

### 6.1. Команды и игроки с сохранением неприкреплённых строк

```sql
SELECT t.team_id,
       t.name AS team_name,
       p.player_id,
       p.nickname
FROM nf.Teams AS t
FULL OUTER JOIN nf.Players AS p
                 ON p.team_id = t.team_id
ORDER BY t.team_id NULLS LAST, p.player_id NULLS LAST;
```

**Ожидаемый результат:** строки команды без игроков имеют `NULL` в столбцах
игрока, а игроки без команды — `NULL` в `team_id` и `team_name`.

### 6.2. Регионы и команды с сохранением пустых регионов

```sql
SELECT r.region_id,
       r.region_name,
       t.team_id,
       t.name AS team_name
FROM nf.Regions AS r
FULL OUTER JOIN nf.Teams AS t
                 ON t.region_id = r.region_id
ORDER BY r.region_id NULLS LAST, t.team_id NULLS LAST;
```

**Ожидаемый результат:** выводятся все регионы и все команды. Регион без команды
имеет `NULL` в `team_id` и `team_name`; команда без региона имеет `NULL` в
`region_id` и `region_name`.
