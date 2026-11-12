# Домашняя работа 6 — Подзапросы

**Предметная область:** Dota 2  
**Схема:** `nf` из HW3 (14 таблиц)  
**Проверено:** PostgreSQL 16.15, данные HW2 после UPDATE и миграции HW3.

## Задание

Последний слайд презентации «08. Подзапросы»: по два запроса с подзапросами
в `SELECT`, `FROM`, `WHERE`, `HAVING`, с `ALL`, `IN`, `ANY`, `EXISTS`,
со сравнением по нескольким столбцам; дополнительно пять коррелированных.
Итого **23 отдельных запроса**. В презентации указано `EXIST`; в SQL используется `EXISTS`.
Срок, указанный на слайде: 06.11.2026.

| Раздел | Количество |
|---|---:|
| SELECT | 2 |
| FROM | 2 |
| WHERE | 2 |
| HAVING | 2 |
| ALL | 2 |
| IN | 2 |
| ANY | 2 |
| EXISTS / NOT EXISTS | 2 |
| Сравнение по нескольким столбцам | 2 |
| Дополнительные коррелированные | 5 |
| **Итого** | **23** |

Некоторые примеры первых девяти разделов тоже коррелированные, но они не заменяют
пять дополнительных запросов раздела 10.

## Запуск в pgAdmin

1. Выбрать базу, в которой выполнялась HW5, и открыть **Query Tool**.
2. Открыть [queries.sql](queries.sql). Выполнять отдельные запросы по номерам
   или весь файл. При запуске всего файла способ просмотра нескольких результатов
   зависит от версии pgAdmin; для отдельного результата выделить нужный SELECT.
3. Сравнить результаты с таблицами ниже. Здесь приведены реальные результаты
   на данных репозитория, а не ожидаемые примеры. На изменённой БД значения могут отличаться.

Все запросы используют явный префикс `nf.` и только читают данные.
Команд psql (`\i`, `\o` и т.п.) в `queries.sql` нет.
Полный вывод проверки: [output/psql_output.txt](output/psql_output.txt).

Если схема `nf` ещё не загружена, в **отдельной учебной базе** выполнить файлы
в следующем порядке (каждый открыть в Query Tool):

1. `HW2/create_tables.sql`
2. `HW2/alter_tables.sql`
3. `HW2/insert_data.sql`
4. `HW2/update_data.sql`
5. `HW3/normalized_schema.sql`
6. `HW3/migrate_to_nf.sql`

При подготовке HW2 использовать `public` как текущую схему; перед первым файлом
выполнить `SET search_path TO public;`. Скрипт HW3 сам переключает схему на `nf`.
Создание таблиц HW2 и схемы HW3 удаляет существующие одноимённые объекты,
поэтому повторно подготавливать уже заполненную рабочую БД для HW6 не нужно.

Данные для воспроизведения полностью есть в репозитории: 4 команды, 5 игроков,
5 героев, 5 предметов, 4 матча, 5 записей статистики и 5 записей инвентаря.
Не все участники матчей представлены в статистике; состав команды в `Players`
не является историей переходов между командами.

**Замечание о старой миграции HW3.** Она вставляет предметы без сохранения
исходных `item_id` и без `ORDER BY`, а инвентарь копирует со старыми ID.
В проверенной локальной БД `public.items.item_id = 4` — Tango, а
`nf.items.item_id = 4` — Town Portal Scroll. Поэтому результат 10.5 отражает
фактический инвентарь схемы `nf`: Town Portal Scroll — 1, Tango — 0.
На пользовательской БД эти числа могут отличаться. Это проблема миграции,
а не подсчёта HW6; исходные файлы HW3 в рамках этой работы не изменялись.

## 1. Подзапросы в SELECT

### 1.1. SELECT — количество игроков команды

**Задача:** Вывести все команды и число игроков в каждой, включая команды без игроков.

```sql
SELECT t.name AS team_name,
       (SELECT count(*)
        FROM nf.Players p
        WHERE p.team_id = t.team_id) AS players_count
FROM nf.Teams t
ORDER BY t.name;
```

**Пояснение:** Скалярный коррелированный подзапрос в SELECT связан с командой через t.team_id. COUNT(*) всегда возвращает одну строку; для пустого состава получится 0.

**Результат:**

| team_name | players_count |
| --- | --- |
| PSG.LGD | 1 |
| Team Liquid | 0 |
| Team Secret | 1 |
| Team Spirit | 3 |

### 1.2. SELECT — отклонение цены от средней

**Задача:** Для каждого предмета показать цену и её отклонение от средней цены всех предметов.

```sql
SELECT i.name AS item_name,
       i.cost,
       round(i.cost - (SELECT avg(i2.cost) FROM nf.Items i2), 2) AS cost_diff
FROM nf.Items i
ORDER BY i.name;
```

**Пояснение:** Некоррелированный скалярный подзапрос вычисляет общее среднее. Округляется только вывод, а не исходная цена.

**Результат:**

| item_name | cost | cost_diff |
| --- | --- | --- |
| Aghanim's Scepter | 4200 | 2070.00 |
| Black King Bar | 4050 | 1920.00 |
| Blink Dagger | 2250 | 120.00 |
| Tango | 100 | -2030.00 |
| Town Portal Scroll | 50 | -2080.00 |

## 2. Подзапросы в FROM

### 2.1. FROM — статистика составов команд

**Задача:** Вывести команды, у которых не меньше двух игроков, с количеством игроков и средним MMR.

```sql
SELECT t.name AS team_name,
       team_stats.players_count,
       round(team_stats.avg_mmr, 2) AS avg_mmr
FROM (
    SELECT p.team_id, count(*) AS players_count, avg(p.mmr) AS avg_mmr
    FROM nf.Players p
    GROUP BY p.team_id
) AS team_stats
JOIN nf.Teams t ON t.team_id = team_stats.team_id
WHERE team_stats.players_count >= 2
ORDER BY t.name;
```

**Пояснение:** Производная таблица team_stats сначала группирует игроков по команде. Внешний запрос присоединяет названия и фильтрует полученные агрегаты.

**Результат:**

| team_name | players_count | avg_mmr |
| --- | --- | --- |
| Team Spirit | 3 | 10700.00 |

### 2.2. FROM — результативные герои

**Задача:** Показать героев со средним числом убийств за записанное выступление не меньше 10.

```sql
SELECT h.name AS hero_name,
       hero_stats.stat_rows,
       round(hero_stats.avg_kills, 2) AS avg_kills
FROM (
    SELECT s.hero_id, count(*) AS stat_rows, avg(s.kills) AS avg_kills
    FROM nf.PlayerMatchStats s
    GROUP BY s.hero_id
) AS hero_stats
JOIN nf.Heroes h ON h.hero_id = hero_stats.hero_id
WHERE hero_stats.avg_kills >= 10
ORDER BY h.name;
```

**Пояснение:** Подзапрос в FROM возвращает таблицу агрегатов по героям. Сравнение выполняется по неокруглённому среднему.

**Результат:**

| hero_name | stat_rows | avg_kills |
| --- | --- | --- |
| Anti-Mage | 1 | 12.00 |
| Invoker | 2 | 12.00 |

## 3. Подзапросы в WHERE

### 3.1. WHERE — игроки выше среднего MMR

**Задача:** Найти игроков, чей MMR выше среднего MMR всех игроков.

```sql
SELECT p.nickname, p.mmr
FROM nf.Players p
WHERE p.mmr > (SELECT avg(p2.mmr) FROM nf.Players p2)
ORDER BY p.mmr DESC, p.nickname;
```

**Пояснение:** Независимый скалярный подзапрос в WHERE возвращает одно среднее значение.

**Результат:**

| nickname | mmr |
| --- | --- |
| Yatoro | 12500 |

### 3.2. WHERE — предметы дороже среднего

**Задача:** Найти предметы, цена которых выше средней цены всех предметов.

```sql
SELECT i.name AS item_name, i.cost
FROM nf.Items i
WHERE i.cost > (SELECT avg(i2.cost) FROM nf.Items i2)
ORDER BY i.cost DESC, i.name;
```

**Пояснение:** AVG возвращает одно значение, поэтому результат подзапроса можно использовать с оператором >.

**Результат:**

| item_name | cost |
| --- | --- |
| Aghanim's Scepter | 4200 |
| Black King Bar | 4050 |
| Blink Dagger | 2250 |

## 4. Подзапросы в HAVING

### 4.1. HAVING — команды с высоким средним MMR

**Задача:** Найти команды, средний MMR игроков которых выше среднего MMR по всем игрокам.

```sql
SELECT t.name AS team_name,
       round(avg(p.mmr), 2) AS avg_mmr
FROM nf.Teams t
JOIN nf.Players p ON p.team_id = t.team_id
GROUP BY t.team_id, t.name
HAVING avg(p.mmr) > (SELECT avg(p2.mmr) FROM nf.Players p2)
ORDER BY t.name;
```

**Пояснение:** HAVING сравнивает среднее каждой группы с общим средним из подзапроса. JOIN включает только команды с игроками.

**Результат:**

| team_name | avg_mmr |
| --- | --- |
| Team Spirit | 10700.00 |

### 4.2. HAVING — герои с большой суммой убийств

**Задача:** Найти героев, сумма убийств на которых выше средней суммы убийств по использованным героям.

```sql
SELECT h.name AS hero_name,
       sum(s.kills) AS total_kills
FROM nf.Heroes h
JOIN nf.PlayerMatchStats s ON s.hero_id = h.hero_id
GROUP BY h.hero_id, h.name
HAVING sum(s.kills) > (
    SELECT avg(hero_totals.total_kills)
    FROM (
        SELECT sum(s2.kills) AS total_kills
        FROM nf.PlayerMatchStats s2
        GROUP BY s2.hero_id
    ) AS hero_totals
)
ORDER BY total_kills DESC, h.name;
```

**Пояснение:** Внутренний подзапрос считает сумму для каждого использованного героя, внешний подзапрос усредняет эти суммы. Герои без статистики не входят в базу сравнения.

**Результат:**

| hero_name | total_kills |
| --- | --- |
| Invoker | 24 |
| Anti-Mage | 12 |

## 5. ALL

### 5.1. ALL — максимальный MMR

**Задача:** Найти всех игроков с максимальным MMR, сохраняя возможные ничьи.

```sql
SELECT p.nickname, p.mmr
FROM nf.Players p
WHERE p.mmr >= ALL (SELECT p2.mmr FROM nf.Players p2)
ORDER BY p.nickname;
```

**Пояснение:** >= ALL требует, чтобы MMR игрока был не меньше каждого значения из подзапроса. MMR объявлен NOT NULL.

**Результат:**

| nickname | mmr |
| --- | --- |
| Yatoro | 12500 |

### 5.2. ALL — дороже всех бюджетных предметов

**Задача:** Найти предметы дороже каждого предмета с ценой меньше 1000 золота.

```sql
SELECT i.name AS item_name, i.cost
FROM nf.Items i
WHERE i.cost > ALL (
    SELECT cheap.cost
    FROM nf.Items cheap
    WHERE cheap.cost < 1000
)
ORDER BY i.cost DESC, i.name;
```

**Пояснение:** > ALL означает строгое превосходство над всеми ценами выбранного набора. Для пустого набора ALL даёт TRUE; здесь бюджетные предметы есть, cost не допускает NULL.

**Результат:**

| item_name | cost |
| --- | --- |
| Aghanim's Scepter | 4200 |
| Black King Bar | 4050 |
| Blink Dagger | 2250 |

## 6. IN

### 6.1. IN — команды с сильными игроками

**Задача:** Найти команды, в которых есть игроки с MMR не меньше 10000.

```sql
SELECT t.name AS team_name
FROM nf.Teams t
WHERE t.team_id IN (
    SELECT p.team_id
    FROM nf.Players p
    WHERE p.mmr >= 10000 AND p.team_id IS NOT NULL
)
ORDER BY t.name;
```

**Пояснение:** IN проверяет принадлежность team_id набору команд из подзапроса. NULL-команды исключаются явно; повторы внутри набора не дублируют команды.

**Результат:**

| team_name |
| --- |
| Team Spirit |

### 6.2. IN — герои поддержки

**Задача:** Найти героев, у которых среди ролей есть Support.

```sql
SELECT h.name AS hero_name
FROM nf.Heroes h
WHERE h.hero_id IN (
    SELECT hr.hero_id
    FROM nf.HeroRoles hr
    JOIN nf.Roles r ON r.role_id = hr.role_id
    WHERE r.role_name = 'Support'
)
ORDER BY h.name;
```

**Пояснение:** Подзапрос возвращает идентификаторы героев через таблицу связи HeroRoles и справочник Roles.

**Результат:**

| hero_name |
| --- |
| Crystal Maiden |
| Pudge |

## 7. ANY

### 7.1. ANY — игроки с результативным выступлением

**Задача:** Найти игроков, у которых есть хотя бы одно выступление с 10 убийствами или больше.

```sql
SELECT p.nickname
FROM nf.Players p
WHERE p.player_id = ANY (
    SELECT s.player_id
    FROM nf.PlayerMatchStats s
    WHERE s.kills >= 10
)
ORDER BY p.nickname;
```

**Пояснение:** = ANY проверяет совпадение хотя бы с одним player_id и в этом случае эквивалентен IN.

**Результат:**

| nickname |
| --- |
| Yatoro |

### 7.2. ANY — сравнение с дорогими предметами

**Задача:** Найти предметы дороже хотя бы одного предмета стоимостью не меньше 4000 золота.

```sql
SELECT i.name AS item_name, i.cost
FROM nf.Items i
WHERE i.cost > ANY (
    SELECT expensive.cost
    FROM nf.Items expensive
    WHERE expensive.cost >= 4000
)
ORDER BY i.cost DESC, i.name;
```

**Пояснение:** > ANY достаточно одного успешного сравнения. Это не то же самое, что > ALL; для пустого набора ANY даёт FALSE.

**Результат:**

| item_name | cost |
| --- | --- |
| Aghanim's Scepter | 4200 |

## 8. EXISTS и NOT EXISTS

### 8.1. EXISTS — команды с игроками

**Задача:** Найти команды, у которых есть хотя бы один игрок.

```sql
SELECT t.name AS team_name
FROM nf.Teams t
WHERE EXISTS (
    SELECT 1
    FROM nf.Players p
    WHERE p.team_id = t.team_id
)
ORDER BY t.name;
```

**Пояснение:** EXISTS проверяет наличие строки; содержимое SELECT 1 не важно. Подзапрос коррелирован через t.team_id.

**Результат:**

| team_name |
| --- |
| PSG.LGD |
| Team Secret |
| Team Spirit |

### 8.2. NOT EXISTS — неиспользованные герои

**Задача:** Найти героев, для которых нет ни одной записи статистики.

```sql
SELECT h.name AS hero_name
FROM nf.Heroes h
WHERE NOT EXISTS (
    SELECT 1
    FROM nf.PlayerMatchStats s
    WHERE s.hero_id = h.hero_id
)
ORDER BY h.name;
```

**Пояснение:** NOT EXISTS проверяет отсутствие соответствующей строки и не имеет проблемы NULL-набора, характерной для NOT IN. В задании написано EXIST; правильное ключевое слово SQL — EXISTS.

**Результат:**

| hero_name |
| --- |
| Faceless Void |

## 9. Сравнение по нескольким столбцам

### 9.1. Несколько столбцов — выступления с покупками

**Задача:** Вывести записи статистики, для которых в инвентаре есть хотя бы один предмет именно этого игрока именно в этом матче.

```sql
SELECT p.nickname, s.match_id, s.kills
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
WHERE (s.player_id, s.match_id) IN (
    SELECT pi.player_id, pi.match_id
    FROM nf.PlayerInventory pi
)
ORDER BY p.nickname, s.match_id;
```

**Пояснение:** Пара (player_id, match_id) сравнивается целиком. Отдельные IN по двум колонкам могли бы принять игрока и матч из разных строк. Несколько предметов не дублируют выступление.

**Результат:**

| nickname | match_id | kills |
| --- | --- | --- |
| Collapse | 1 | 9 |
| Puppey | 1 | 5 |
| Yatoro | 1 | 12 |
| Yatoro | 2 | 15 |

### 9.2. Несколько столбцов — рекорды на каждом герое

**Задача:** Найти выступления с максимальным числом убийств для соответствующего героя; при равенстве сохранить все.

```sql
SELECT h.name AS hero_name, p.nickname, s.match_id, s.kills
FROM nf.PlayerMatchStats s
JOIN nf.Heroes h ON h.hero_id = s.hero_id
JOIN nf.Players p ON p.player_id = s.player_id
WHERE (s.hero_id, s.kills) IN (
    SELECT s2.hero_id, max(s2.kills)
    FROM nf.PlayerMatchStats s2
    GROUP BY s2.hero_id
)
ORDER BY h.name, p.nickname, s.match_id;
```

**Пояснение:** Подзапрос возвращает пары (hero_id, max(kills)). Сравнивается и герой, и его собственный рекорд, а не максимум другого героя.

**Результат:**

| hero_name | nickname | match_id | kills |
| --- | --- | --- | --- |
| Anti-Mage | Yatoro | 1 | 12 |
| Crystal Maiden | Miposhka | 1 | 2 |
| Invoker | Yatoro | 2 | 15 |
| Pudge | Puppey | 1 | 5 |

## 10. Пять дополнительных коррелированных подзапросов

### 10.1. Коррелированный — MMR выше среднего своей команды

**Задача:** Найти игроков, чей MMR выше среднего MMR игроков их собственной команды.

```sql
SELECT p.nickname, t.name AS team_name, p.mmr
FROM nf.Players p
JOIN nf.Teams t ON t.team_id = p.team_id
WHERE p.mmr > (
    SELECT avg(teammate.mmr)
    FROM nf.Players teammate
    WHERE teammate.team_id = p.team_id
)
ORDER BY t.name, p.nickname;
```

**Пояснение:** Ссылка p.team_id меняет набор усредняемых игроков для каждой внешней строки. Для игрока без команды AVG по пустому набору даст NULL, и строка не пройдёт фильтр.

**Результат:**

| nickname | team_name | mmr |
| --- | --- | --- |
| Yatoro | Team Spirit | 12500 |

### 10.2. Коррелированный — число побед команды

**Задача:** Вывести все команды и число их побед по таблице участников матчей.

```sql
SELECT t.name AS team_name,
       (SELECT count(*)
        FROM nf.MatchTeams mt
        WHERE mt.team_id = t.team_id AND mt.is_winner) AS wins
FROM nf.Teams t
ORDER BY wins DESC, t.name;
```

**Пояснение:** Подзапрос связан с t.team_id и считает только победные записи. Команда без побед получает 0; статистика отдельных игроков для подсчёта не нужна.

**Результат:**

| team_name | wins |
| --- | --- |
| Team Spirit | 3 |
| Team Liquid | 1 |
| PSG.LGD | 0 |
| Team Secret | 0 |

### 10.3. Коррелированный — лучший результат в каждом матче

**Задача:** Найти игроков с максимальным числом убийств среди имеющихся записей статистики каждого матча.

```sql
SELECT s.match_id, p.nickname, s.kills
FROM nf.PlayerMatchStats s
JOIN nf.Players p ON p.player_id = s.player_id
WHERE s.kills = (
    SELECT max(other.kills)
    FROM nf.PlayerMatchStats other
    WHERE other.match_id = s.match_id
)
ORDER BY s.match_id, p.nickname;
```

**Пояснение:** Подзапрос ссылается на s.match_id. Равенство MAX сохраняет ничьи. Матчи без статистики не выводятся; речь только о записанных выступлениях, а не полном составе матча.

**Результат:**

| match_id | nickname | kills |
| --- | --- | --- |
| 1 | Yatoro | 12 |
| 2 | Yatoro | 15 |

### 10.4. Коррелированный — игроки без статистики

**Задача:** Найти игроков, у которых нет ни одной записи индивидуальной статистики.

```sql
SELECT p.nickname
FROM nf.Players p
WHERE NOT EXISTS (
    SELECT 1
    FROM nf.PlayerMatchStats s
    WHERE s.player_id = p.player_id
)
ORDER BY p.nickname;
```

**Пояснение:** NOT EXISTS связан с текущим p.player_id. Отсутствие статистики не доказывает, что игрок никогда не участвовал в матчах: учебный набор неполный.

**Результат:**

| nickname |
| --- |
| Ame |

### 10.5. Коррелированный — число покупок каждого предмета

**Задача:** Вывести все предметы с количеством записей их покупки в инвентаре, включая ни разу не купленные.

```sql
SELECT i.name AS item_name,
       (SELECT count(*)
        FROM nf.PlayerInventory pi
        WHERE pi.item_id = i.item_id) AS purchases_count
FROM nf.Items i
ORDER BY purchases_count DESC, i.name;
```

**Пояснение:** Подзапрос связан с i.item_id. COUNT(*) считает записи инвентаря, а не число уникальных игроков; для отсутствующих покупок возвращает 0.

**Результат:**

| item_name | purchases_count |
| --- | --- |
| Black King Bar | 2 |
| Aghanim's Scepter | 1 |
| Blink Dagger | 1 |
| Town Portal Scroll | 1 |
| Tango | 0 |

## Особенности подзапросов

- Скалярный подзапрос возвращает один столбец и не более одной строки:
  ноль строк означает `NULL`, больше одной строки — ошибку.
  Агрегат без GROUP BY возвращает одну строку; `COUNT(*)` по пустому набору — 0,
  а `AVG`, `MAX` и `SUM` по пустому набору — `NULL`.
- `ALL` требует выполнения сравнения для всех значений, `ANY` — хотя бы для одного.
  Для пустого подзапроса результат `ALL` — TRUE, `ANY` — FALSE.
  При наличии NULL результат может быть UNKNOWN: например, `5 > ALL (NULL)`.
  Условия WHERE/HAVING оставляют только TRUE. В примерах сравниваемые `mmr`,
  `cost`, ключи и `kills` имеют ограничения NOT NULL.
- `EXISTS` проверяет наличие строк, а не значения их столбцов; `EXISTS (SELECT NULL)` — TRUE.
- Коррелированный подзапрос содержит ссылку на внешний запрос.
  Это логическая зависимость; PostgreSQL выбирает фактический план исполнения.
  Не любой подзапрос обязательно выполняется заранее и не любой коррелированный
  подзапрос приводит к отдельному проходу для каждой строки. Для анализа нужен EXPLAIN.

## Проверка

Все 23 запроса выполнены с `ON_ERROR_STOP=1` на PostgreSQL 16.15.
Ни один запрос не изменяет данные. В документе SQL совпадает с `queries.sql`;
результаты получены из локальной БД, восстановленной по файлам HW2–HW3.
Скриншоты pgAdmin можно добавить после проверки на пользовательской БД.
