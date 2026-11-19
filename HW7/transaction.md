# Домашняя работа 7 — Транзакции

**Предметная область:** Dota 2.\
**Схема данных:** `nf` из HW3, с данными HW2 и дополнениями HW6.\
**Презентация:** «10. Транзакции», слайды 31–35.\
**Срок на слайде:** до 20.11.\
**Локальная проверка:** PostgreSQL 17.10, все 24 сценария выполнены успешно.

## Состав работы

| Раздел | Количество сценариев |
|---|---:|
| BEGIN / COMMIT: INSERT и UPDATE связанной записи | 2 |
| То же с ROLLBACK | 2 |
| Ошибка внутри транзакции и полный откат | 2 |
| Восемь тем изоляции, по два сценария | 16 |
| SAVEPOINT и два SAVEPOINT | 2 |
| **Итого** | **24** |

Для уровней изоляции выделены восемь тем: грязное чтение на READ UNCOMMITTED,
грязное чтение на READ COMMITTED, неповторяющееся чтение на READ COMMITTED,
фантомы на READ COMMITTED, стабильность строки на REPEATABLE READ,
фантомы на REPEATABLE READ, конфликт одинаковых вставок на SERIALIZABLE,
конкурентный UPDATE на SERIALIZABLE с повтором транзакции.
Сравнение фантомов с READ COMMITTED добавлено как контрольный опыт:
на слайдах заявлено восемь заданий, но отдельная нумерация отсутствует.

## Важные особенности PostgreSQL

- READ UNCOMMITTED ведёт себя как READ COMMITTED: грязных чтений нет.
- REPEATABLE READ в PostgreSQL не показывает и фантомные строки других транзакций.
  Поэтому соответствующее задание проверяет **отсутствие** фантома, затем его видимость
  после завершения транзакции; для сравнения на READ COMMITTED фантом появляется.
- Снимок REPEATABLE READ / SERIALIZABLE устанавливается при первом запросе,
  которому нужен снимок, а не обязательно в момент одной команды BEGIN.
- SERIALIZABLE может отменить конфликтующую транзакцию с SQLSTATE `40001`.
  Повторять нужно всю транзакцию с BEGIN и повторным чтением, а не один UPDATE
  в уже прерванной транзакции.
- После обычной ошибки без SAVEPOINT транзакция находится в состоянии aborted:
  последующие команды возвращают `25P02`. Для выхода выполняется ROLLBACK.
- Значения SERIAL-последовательностей не возвращаются при ROLLBACK. Пропуски ID
  не означают, что откат не сработал. Проверяются строки таблиц, а не непрерывность ID.

Эти особенности важнее общей таблицы на слайде 28, где для REPEATABLE READ
фантомы отмечены как возможные по минимальным гарантиям SQL.

## Подготовка и выполнение

1. Открываю ту же базу, что использовалась для HW6, и выполняю
   [00_check_schema.sql](00_check_schema.sql). Нужны таблицы схемы `nf`.
2. В отдельном Query Tool выполняю целиком [01_prepare.sql](01_prepare.sql).
   Скрипт добавляет демонстрационные строки `HW7_TX_`, не меняя старые строки.
   Для восстановления начальных условий всех опытов его можно повторить,
   предварительно завершив все открытые T1/T2.
3. Открываю **два независимых Query Tool одной базы**: T1 и T2. Проверяю в каждом:

   ```sql
   SELECT current_database(), pg_backend_pid();
   ```

   База должна совпадать, PID — различаться. Разделение редактора или повторное
   выполнение в той же вкладке не создаёт независимую транзакцию.
4. В обоих Query Tool оставляю **Auto-commit включённым**, а **Auto-rollback выключенным**.
   Явные BEGIN/COMMIT/ROLLBACK в сценариях управляют транзакциями самостоятельно.
   Автооткат помешает увидеть состояние `25P02` после ошибки.
5. Открываю соответствующие файлы T1.sql и T2.sql. **Выделяю и выполняю только один
   пронумерованный шаг**, затем переключаюсь в нужную вкладку по порядку отчёта.
   Нельзя запускать оба файла целиком: порядок между сессиями является частью опыта.
6. Ожидаемую ошибку выполняю отдельным запуском. Следующий ROLLBACK также выделяю
   и выполняю отдельно, иначе клиент может остановить отправку после ошибки.
7. Снимаю результаты в pgAdmin. Места для собственных фотографий указаны в конце
   каждого сценария; инструкции и имена файлов — в [screenshots/README.md](screenshots/README.md).
8. После окончания всех опытов при желании выполняю [99_cleanup.sql](99_cleanup.sql).

SQL не содержит команд psql. Во всех таблицах явно указана схема `nf`.
Временные значения идентификаторов не зашиты в запросы: ссылки находятся по именам.
До очистки общие агрегаты прошлых работ могут учитывать демонстрационные строки;
после `99_cleanup.sql` исходные наборы строк восстановлены.

**Важно:** подготовка повторно удаляет только результаты опытов с префиксом `HW7_TX_`.
Не использовать этот префикс для обычных данных. Старые скрипты HW2/HW3 с DROP
повторять в заполненной базе не требуется. Матчи опытов определяются через
отдельные режимы `HW7_TX_19_Mode` и `HW7_TX_20_Mode`.

## Начальные демонстрационные данные

После `01_prepare.sql`:

| Таблица | Демонстрационных строк |
|---|---:|
| Teams | 6 |
| Players | 7 |
| Items | 8 |
| Regions | 3 |
| GameModes | 2 |

Начальная цена каждого демонстрационного предмета — 100,
MMR каждого начального демонстрационного игрока — 8000,
дата основания демонстрационных команд — 2000-01-01.
Эти значения не зависят от актуального MMR Yatoro и других исходных строк.

Ниже приведены **фактические результаты локального выполнения**, а не фотографии
pgAdmin. Фотографии добавляются после ручного прогона. Полные протоколы всех
шагов сохранены в [output](output/); сводка — [verification.txt](output/verification.txt).

## 1. Базовые операции с транзакциями — 6 сценариев

В таблицах результатов используется список строк: `[[100]]` означает одну строку
со значением 100, `[["A"], ["B"]]` — две строки со значениями A и B.

### 01_commit_a. COMMIT: игрок и команда

**SQL:** [T1](sql/01_commit_a/T1.sql).\
**Локальный протокол:** [01_commit_a.txt](output/01_commit_a.txt).

**Шаг 1 — T1.** До изменений.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_01_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_01_NewPlayer';
```

**Шаг 2 — T1.** INSERT в одну таблицу и UPDATE связанной записи в другой.

```sql
BEGIN;
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_01_NewPlayer', 8500, team_id FROM nf.Teams WHERE name = 'HW7_TX_01_Team';
UPDATE nf.Teams SET foundation_date = DATE '2026-11-19' WHERE name = 'HW7_TX_01_Team';
```

**Шаг 3 — T1.** Внутри своей транзакции изменения уже видны.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_01_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_01_NewPlayer';
```

**Шаг 4 — T1.** Завершить транзакцию.

```sql
COMMIT;
```

**Шаг 5 — T1.** Проверка после завершения.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_01_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_01_NewPlayer';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | foundation_date → [["2000-01-01"]]; new_players → [[0]] |
| 2 | T1 | INSERT 0 1; UPDATE 1 |
| 3 | T1 | foundation_date → [["2026-11-19"]]; new_players → [[1]] |
| 4 | T1 | Команда выполнена. |
| 5 | T1 | foundation_date → [["2026-11-19"]]; new_players → [[1]] |

**Вывод:** Изменения обеих таблиц сохранены.

**Фотографии pgAdmin:** после ручной проверки добавить `01_commit_a_1.png` и `01_commit_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 02_commit_b. COMMIT: команда и регион

**SQL:** [T1](sql/02_commit_b/T1.sql).\
**Локальный протокол:** [02_commit_b.txt](output/02_commit_b.txt).

**Шаг 1 — T1.** До изменений.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_02_Region', 'HW7_TX_02_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_02_NewTeam';
```

**Шаг 2 — T1.** INSERT в одну таблицу и UPDATE связанной записи в другой.

```sql
BEGIN;
INSERT INTO nf.Teams (name, region_id)
SELECT 'HW7_TX_02_NewTeam', region_id FROM nf.Regions WHERE region_name = 'HW7_TX_02_Region';
UPDATE nf.Regions SET region_name = 'HW7_TX_02_Region_OK' WHERE region_name = 'HW7_TX_02_Region';
```

**Шаг 3 — T1.** Внутри своей транзакции изменения уже видны.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_02_Region', 'HW7_TX_02_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_02_NewTeam';
```

**Шаг 4 — T1.** Завершить транзакцию.

```sql
COMMIT;
```

**Шаг 5 — T1.** Проверка после завершения.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_02_Region', 'HW7_TX_02_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_02_NewTeam';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | region_name → [["HW7_TX_02_Region"]]; new_teams → [[0]] |
| 2 | T1 | INSERT 0 1; UPDATE 1 |
| 3 | T1 | region_name → [["HW7_TX_02_Region_OK"]]; new_teams → [[1]] |
| 4 | T1 | Команда выполнена. |
| 5 | T1 | region_name → [["HW7_TX_02_Region_OK"]]; new_teams → [[1]] |

**Вывод:** Изменения обеих таблиц сохранены.

**Фотографии pgAdmin:** после ручной проверки добавить `02_commit_b_1.png` и `02_commit_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 03_rollback_a. ROLLBACK: игрок и команда

**SQL:** [T1](sql/03_rollback_a/T1.sql).\
**Локальный протокол:** [03_rollback_a.txt](output/03_rollback_a.txt).

**Шаг 1 — T1.** До изменений.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_03_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_03_NewPlayer';
```

**Шаг 2 — T1.** INSERT в одну таблицу и UPDATE связанной записи в другой.

```sql
BEGIN;
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_03_NewPlayer', 8500, team_id FROM nf.Teams WHERE name = 'HW7_TX_03_Team';
UPDATE nf.Teams SET foundation_date = DATE '2026-11-19' WHERE name = 'HW7_TX_03_Team';
```

**Шаг 3 — T1.** Внутри своей транзакции изменения уже видны.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_03_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_03_NewPlayer';
```

**Шаг 4 — T1.** Завершить транзакцию.

```sql
ROLLBACK;
```

**Шаг 5 — T1.** Проверка после завершения.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_03_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_03_NewPlayer';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | foundation_date → [["2000-01-01"]]; new_players → [[0]] |
| 2 | T1 | INSERT 0 1; UPDATE 1 |
| 3 | T1 | foundation_date → [["2026-11-19"]]; new_players → [[1]] |
| 4 | T1 | Команда выполнена. |
| 5 | T1 | foundation_date → [["2000-01-01"]]; new_players → [[0]] |

**Вывод:** Изменения обеих таблиц не сохранены.

**Фотографии pgAdmin:** после ручной проверки добавить `03_rollback_a_1.png` и `03_rollback_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 04_rollback_b. ROLLBACK: команда и регион

**SQL:** [T1](sql/04_rollback_b/T1.sql).\
**Локальный протокол:** [04_rollback_b.txt](output/04_rollback_b.txt).

**Шаг 1 — T1.** До изменений.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_04_Region', 'HW7_TX_04_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_04_NewTeam';
```

**Шаг 2 — T1.** INSERT в одну таблицу и UPDATE связанной записи в другой.

```sql
BEGIN;
INSERT INTO nf.Teams (name, region_id)
SELECT 'HW7_TX_04_NewTeam', region_id FROM nf.Regions WHERE region_name = 'HW7_TX_04_Region';
UPDATE nf.Regions SET region_name = 'HW7_TX_04_Region_OK' WHERE region_name = 'HW7_TX_04_Region';
```

**Шаг 3 — T1.** Внутри своей транзакции изменения уже видны.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_04_Region', 'HW7_TX_04_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_04_NewTeam';
```

**Шаг 4 — T1.** Завершить транзакцию.

```sql
ROLLBACK;
```

**Шаг 5 — T1.** Проверка после завершения.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_04_Region', 'HW7_TX_04_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_04_NewTeam';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | region_name → [["HW7_TX_04_Region"]]; new_teams → [[0]] |
| 2 | T1 | INSERT 0 1; UPDATE 1 |
| 3 | T1 | region_name → [["HW7_TX_04_Region_OK"]]; new_teams → [[1]] |
| 4 | T1 | Команда выполнена. |
| 5 | T1 | region_name → [["HW7_TX_04_Region"]]; new_teams → [[0]] |

**Вывод:** Изменения обеих таблиц не сохранены.

**Фотографии pgAdmin:** после ручной проверки добавить `04_rollback_b_1.png` и `04_rollback_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 05_error_a. ERROR: игрок и команда

**SQL:** [T1](sql/05_error_a/T1.sql).\
**Локальный протокол:** [05_error_a.txt](output/05_error_a.txt).

**Шаг 1 — T1.** До изменений.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_05_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_05_NewPlayer';
```

**Шаг 2 — T1.** INSERT в одну таблицу и UPDATE связанной записи в другой.

```sql
BEGIN;
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_05_NewPlayer', 8500, team_id FROM nf.Teams WHERE name = 'HW7_TX_05_Team';
UPDATE nf.Teams SET foundation_date = DATE '2026-11-19' WHERE name = 'HW7_TX_05_Team';
```

**Шаг 3 — T1.** Внутри своей транзакции изменения уже видны.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_05_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_05_NewPlayer';
```

**Шаг 4 — T1.** Ожидаемая ошибка. Выполнить только этот шаг.

```sql
SELECT 1 / 0;
```

**Шаг 5 — T1.** Транзакция в ошибочном состоянии: новые команды не выполняются.

```sql
SELECT 1;
```

**Шаг 6 — T1.** Выполнить отдельным запуском после ошибки: полностью отменить транзакцию.

```sql
ROLLBACK;
```

**Шаг 7 — T1.** Проверка после завершения.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_05_Team';
SELECT count(*) AS new_players FROM nf.Players WHERE nickname = 'HW7_TX_05_NewPlayer';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | foundation_date → [["2000-01-01"]]; new_players → [[0]] |
| 2 | T1 | INSERT 0 1; UPDATE 1 |
| 3 | T1 | foundation_date → [["2026-11-19"]]; new_players → [[1]] |
| 4 | T1 | `22012`: division by zero |
| 5 | T1 | `25P02`: current transaction is aborted, commands ignored until end of transaction block |
| 6 | T1 | Команда выполнена. |
| 7 | T1 | foundation_date → [["2000-01-01"]]; new_players → [[0]] |

**Вывод:** Изменения обеих таблиц не сохранены.

**Фотографии pgAdmin:** после ручной проверки добавить `05_error_a_1.png` и `05_error_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 06_error_b. ERROR: команда и регион

**SQL:** [T1](sql/06_error_b/T1.sql).\
**Локальный протокол:** [06_error_b.txt](output/06_error_b.txt).

**Шаг 1 — T1.** До изменений.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_06_Region', 'HW7_TX_06_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_06_NewTeam';
```

**Шаг 2 — T1.** INSERT в одну таблицу и UPDATE связанной записи в другой.

```sql
BEGIN;
INSERT INTO nf.Teams (name, region_id)
SELECT 'HW7_TX_06_NewTeam', region_id FROM nf.Regions WHERE region_name = 'HW7_TX_06_Region';
UPDATE nf.Regions SET region_name = 'HW7_TX_06_Region_OK' WHERE region_name = 'HW7_TX_06_Region';
```

**Шаг 3 — T1.** Внутри своей транзакции изменения уже видны.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_06_Region', 'HW7_TX_06_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_06_NewTeam';
```

**Шаг 4 — T1.** Ожидаемая ошибка. Выполнить только этот шаг.

```sql
SELECT 1 / 0;
```

**Шаг 5 — T1.** Транзакция в ошибочном состоянии: новые команды не выполняются.

```sql
SELECT 1;
```

**Шаг 6 — T1.** Выполнить отдельным запуском после ошибки: полностью отменить транзакцию.

```sql
ROLLBACK;
```

**Шаг 7 — T1.** Проверка после завершения.

```sql
SELECT region_name FROM nf.Regions WHERE region_name IN ('HW7_TX_06_Region', 'HW7_TX_06_Region_OK') ORDER BY region_name;
SELECT count(*) AS new_teams FROM nf.Teams WHERE name = 'HW7_TX_06_NewTeam';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | region_name → [["HW7_TX_06_Region"]]; new_teams → [[0]] |
| 2 | T1 | INSERT 0 1; UPDATE 1 |
| 3 | T1 | region_name → [["HW7_TX_06_Region_OK"]]; new_teams → [[1]] |
| 4 | T1 | `22012`: division by zero |
| 5 | T1 | `25P02`: current transaction is aborted, commands ignored until end of transaction block |
| 6 | T1 | Команда выполнена. |
| 7 | T1 | region_name → [["HW7_TX_06_Region"]]; new_teams → [[0]] |

**Вывод:** Изменения обеих таблиц не сохранены.

**Фотографии pgAdmin:** после ручной проверки добавить `06_error_b_1.png` и `06_error_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

## 2. Уровни изоляции — 16 сценариев

В сценариях 19–20 две сессии пытаются создать матч с одинаковыми значениями
`duration_sec`, `game_mode_id` и `match_date`. Различается только автоматически
выданный `match_id`. На эти бизнес-поля нет UNIQUE: конфликт вызывается
проверкой отсутствия записи и SERIALIZABLE, а не нарушением уникальности.
В опыте считаю повторную заявку на такое сочетание дубликатом.
Просто вставить одинаковый уникальный nickname означало бы проверять `23505`,
а не гарантированно получить ошибку сериализации.

### 07_ru_dirty_a. READ UNCOMMITTED: грязное чтение, цена предмета

**SQL:** [T1](sql/07_ru_dirty_a/T1.sql), [T2](sql/07_ru_dirty_a/T2.sql).\
**Локальный протокол:** [07_ru_dirty_a.txt](output/07_ru_dirty_a.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T2) → 4 (T1) → 5 (T2) → 6 (T2).

**Шаг 1 — T1.** Оставить транзакцию открытой, не нажимать COMMIT.

```sql
BEGIN;
UPDATE nf.Items SET cost = 900 WHERE name = 'HW7_TX_07_Item';
```

**Шаг 2 — T2.** Начать независимую читающую транзакцию.

```sql
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SHOW transaction_isolation;
```

**Шаг 3 — T2.** Читается старое подтверждённое значение, без ожидания UPDATE.

```sql
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_07_Item';
```

**Шаг 4 — T1.** Завершить T1 через ROLLBACK.

```sql
ROLLBACK;
```

**Шаг 5 — T2.** Повторное чтение.

```sql
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_07_Item';
```

**Шаг 6 — T2.** Завершить T2.

```sql
COMMIT;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | UPDATE 1 |
| 2 | T2 | transaction_isolation → [["read uncommitted"]] |
| 3 | T2 | cost → [[100]] |
| 4 | T1 | Команда выполнена. |
| 5 | T2 | cost → [[100]] |
| 6 | T2 | Команда выполнена. |

**Вывод:** Незафиксированное значение не видно. После ROLLBACK остаётся исходное значение.

**Фотографии pgAdmin:** после ручной проверки добавить `07_ru_dirty_a_1.png` и `07_ru_dirty_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 08_ru_dirty_b. READ UNCOMMITTED: грязное чтение, MMR игрока

**SQL:** [T1](sql/08_ru_dirty_b/T1.sql), [T2](sql/08_ru_dirty_b/T2.sql).\
**Локальный протокол:** [08_ru_dirty_b.txt](output/08_ru_dirty_b.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T2) → 4 (T1) → 5 (T2) → 6 (T2).

**Шаг 1 — T1.** Оставить транзакцию открытой, не нажимать COMMIT.

```sql
BEGIN;
UPDATE nf.Players SET mmr = 9000 WHERE nickname = 'HW7_TX_08_Player';
```

**Шаг 2 — T2.** Начать независимую читающую транзакцию.

```sql
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SHOW transaction_isolation;
```

**Шаг 3 — T2.** Читается старое подтверждённое значение, без ожидания UPDATE.

```sql
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_08_Player';
```

**Шаг 4 — T1.** Завершить T1 через COMMIT.

```sql
COMMIT;
```

**Шаг 5 — T2.** Повторное чтение.

```sql
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_08_Player';
```

**Шаг 6 — T2.** Завершить T2.

```sql
COMMIT;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | UPDATE 1 |
| 2 | T2 | transaction_isolation → [["read uncommitted"]] |
| 3 | T2 | mmr → [[8000]] |
| 4 | T1 | Команда выполнена. |
| 5 | T2 | mmr → [[9000]] |
| 6 | T2 | Команда выполнена. |

**Вывод:** Незафиксированное значение не видно. После COMMIT другой транзакции следующий SELECT видит новое значение.

**Фотографии pgAdmin:** после ручной проверки добавить `08_ru_dirty_b_1.png` и `08_ru_dirty_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 09_rc_dirty_a. READ COMMITTED: грязное чтение, цена предмета

**SQL:** [T1](sql/09_rc_dirty_a/T1.sql), [T2](sql/09_rc_dirty_a/T2.sql).\
**Локальный протокол:** [09_rc_dirty_a.txt](output/09_rc_dirty_a.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T2) → 4 (T1) → 5 (T2) → 6 (T2).

**Шаг 1 — T1.** Оставить транзакцию открытой, не нажимать COMMIT.

```sql
BEGIN;
UPDATE nf.Items SET cost = 900 WHERE name = 'HW7_TX_09_Item';
```

**Шаг 2 — T2.** Начать независимую читающую транзакцию.

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SHOW transaction_isolation;
```

**Шаг 3 — T2.** Читается старое подтверждённое значение, без ожидания UPDATE.

```sql
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_09_Item';
```

**Шаг 4 — T1.** Завершить T1 через ROLLBACK.

```sql
ROLLBACK;
```

**Шаг 5 — T2.** Повторное чтение.

```sql
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_09_Item';
```

**Шаг 6 — T2.** Завершить T2.

```sql
COMMIT;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | UPDATE 1 |
| 2 | T2 | transaction_isolation → [["read committed"]] |
| 3 | T2 | cost → [[100]] |
| 4 | T1 | Команда выполнена. |
| 5 | T2 | cost → [[100]] |
| 6 | T2 | Команда выполнена. |

**Вывод:** Незафиксированное значение не видно. После ROLLBACK остаётся исходное значение.

**Фотографии pgAdmin:** после ручной проверки добавить `09_rc_dirty_a_1.png` и `09_rc_dirty_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 10_rc_dirty_b. READ COMMITTED: грязное чтение, MMR игрока

**SQL:** [T1](sql/10_rc_dirty_b/T1.sql), [T2](sql/10_rc_dirty_b/T2.sql).\
**Локальный протокол:** [10_rc_dirty_b.txt](output/10_rc_dirty_b.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T2) → 4 (T1) → 5 (T2) → 6 (T2).

**Шаг 1 — T1.** Оставить транзакцию открытой, не нажимать COMMIT.

```sql
BEGIN;
UPDATE nf.Players SET mmr = 9000 WHERE nickname = 'HW7_TX_10_Player';
```

**Шаг 2 — T2.** Начать независимую читающую транзакцию.

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SHOW transaction_isolation;
```

**Шаг 3 — T2.** Читается старое подтверждённое значение, без ожидания UPDATE.

```sql
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_10_Player';
```

**Шаг 4 — T1.** Завершить T1 через COMMIT.

```sql
COMMIT;
```

**Шаг 5 — T2.** Повторное чтение.

```sql
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_10_Player';
```

**Шаг 6 — T2.** Завершить T2.

```sql
COMMIT;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | UPDATE 1 |
| 2 | T2 | transaction_isolation → [["read committed"]] |
| 3 | T2 | mmr → [[8000]] |
| 4 | T1 | Команда выполнена. |
| 5 | T2 | mmr → [[9000]] |
| 6 | T2 | Команда выполнена. |

**Вывод:** Незафиксированное значение не видно. После COMMIT другой транзакции следующий SELECT видит новое значение.

**Фотографии pgAdmin:** после ручной проверки добавить `10_rc_dirty_b_1.png` и `10_rc_dirty_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 11_rc_repeat_a. READ COMMITTED: повторное чтение, цена предмета

**SQL:** [T1](sql/11_rc_repeat_a/T1.sql), [T2](sql/11_rc_repeat_a/T2.sql).\
**Локальный протокол:** [11_rc_repeat_a.txt](output/11_rc_repeat_a.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T1).

**Шаг 1 — T1.** Первое чтение создаёт снимок.

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_11_Item';
```

**Шаг 2 — T2.** Изменить значение и зафиксировать.

```sql
BEGIN;
UPDATE nf.Items SET cost = 150 WHERE name = 'HW7_TX_11_Item';
COMMIT;
```

**Шаг 3 — T1.** Повторить тот же SELECT.

```sql
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_11_Item';
```

**Шаг 4 — T1.** После завершения транзакции.

```sql
COMMIT;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_11_Item';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | cost → [[100]] |
| 2 | T2 | UPDATE 1 |
| 3 | T1 | cost → [[150]] |
| 4 | T1 | cost → [[150]] |

**Вывод:** В одной транзакции два SELECT видят разные значения.

**Фотографии pgAdmin:** после ручной проверки добавить `11_rc_repeat_a_1.png` и `11_rc_repeat_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 12_rc_repeat_b. READ COMMITTED: повторное чтение, MMR игрока

**SQL:** [T1](sql/12_rc_repeat_b/T1.sql), [T2](sql/12_rc_repeat_b/T2.sql).\
**Локальный протокол:** [12_rc_repeat_b.txt](output/12_rc_repeat_b.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T1).

**Шаг 1 — T1.** Первое чтение создаёт снимок.

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_12_Player';
```

**Шаг 2 — T2.** Изменить значение и зафиксировать.

```sql
BEGIN;
UPDATE nf.Players SET mmr = 8100 WHERE nickname = 'HW7_TX_12_Player';
COMMIT;
```

**Шаг 3 — T1.** Повторить тот же SELECT.

```sql
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_12_Player';
```

**Шаг 4 — T1.** После завершения транзакции.

```sql
COMMIT;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_12_Player';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | mmr → [[8000]] |
| 2 | T2 | UPDATE 1 |
| 3 | T1 | mmr → [[8100]] |
| 4 | T1 | mmr → [[8100]] |

**Вывод:** В одной транзакции два SELECT видят разные значения.

**Фотографии pgAdmin:** после ручной проверки добавить `12_rc_repeat_b_1.png` и `12_rc_repeat_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 13_rc_phantom_a. READ COMMITTED: новый игрок команды

**SQL:** [T1](sql/13_rc_phantom_a/T1.sql), [T2](sql/13_rc_phantom_a/T2.sql).\
**Локальный протокол:** [13_rc_phantom_a.txt](output/13_rc_phantom_a.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T1).

**Шаг 1 — T1.** Первое чтение набора строк.

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team');
```

**Шаг 2 — T2.** Добавить строку, подходящую под условие, и зафиксировать.

```sql
BEGIN;
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_13_New', 8500, team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team';
COMMIT;
```

**Шаг 3 — T1.** Повторить тот же запрос.

```sql
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team');
```

**Шаг 4 — T1.** После завершения T1 новая строка видна.

```sql
COMMIT;
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_13_Team');
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | players_count → [[1]] |
| 2 | T2 | INSERT 0 1 |
| 3 | T1 | players_count → [[2]] |
| 4 | T1 | players_count → [[2]] |

**Вывод:** Количество строк изменяется с 1 до 2: фантомное чтение.

**Фотографии pgAdmin:** после ручной проверки добавить `13_rc_phantom_a_1.png` и `13_rc_phantom_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 14_rc_phantom_b. READ COMMITTED: новый предмет в выборке

**SQL:** [T1](sql/14_rc_phantom_b/T1.sql), [T2](sql/14_rc_phantom_b/T2.sql).\
**Локальный протокол:** [14_rc_phantom_b.txt](output/14_rc_phantom_b.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T1).

**Шаг 1 — T1.** Первое чтение набора строк.

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_14_Group' AND cost >= 100;
```

**Шаг 2 — T2.** Добавить строку, подходящую под условие, и зафиксировать.

```sql
BEGIN;
INSERT INTO nf.Items (name, cost, description)
VALUES ('HW7_TX_14_New', 200, 'HW7_TX_14_Group');
COMMIT;
```

**Шаг 3 — T1.** Повторить тот же запрос.

```sql
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_14_Group' AND cost >= 100;
```

**Шаг 4 — T1.** После завершения T1 новая строка видна.

```sql
COMMIT;
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_14_Group' AND cost >= 100;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | items_count → [[1]] |
| 2 | T2 | INSERT 0 1 |
| 3 | T1 | items_count → [[2]] |
| 4 | T1 | items_count → [[2]] |

**Вывод:** Количество строк изменяется с 1 до 2: фантомное чтение.

**Фотографии pgAdmin:** после ручной проверки добавить `14_rc_phantom_b_1.png` и `14_rc_phantom_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 15_rr_repeat_a. REPEATABLE READ: повторное чтение, цена предмета

**SQL:** [T1](sql/15_rr_repeat_a/T1.sql), [T2](sql/15_rr_repeat_a/T2.sql).\
**Локальный протокол:** [15_rr_repeat_a.txt](output/15_rr_repeat_a.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T1).

**Шаг 1 — T1.** Первое чтение создаёт снимок.

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_15_Item';
```

**Шаг 2 — T2.** Изменить значение и зафиксировать.

```sql
BEGIN;
UPDATE nf.Items SET cost = 150 WHERE name = 'HW7_TX_15_Item';
COMMIT;
```

**Шаг 3 — T1.** Повторить тот же SELECT.

```sql
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_15_Item';
```

**Шаг 4 — T1.** После завершения транзакции.

```sql
COMMIT;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_15_Item';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | cost → [[100]] |
| 2 | T2 | UPDATE 1 |
| 3 | T1 | cost → [[100]] |
| 4 | T1 | cost → [[150]] |

**Вывод:** В T1 остаётся старый снимок. Новое значение видно только после завершения T1.

**Фотографии pgAdmin:** после ручной проверки добавить `15_rr_repeat_a_1.png` и `15_rr_repeat_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 16_rr_repeat_b. REPEATABLE READ: повторное чтение, MMR игрока

**SQL:** [T1](sql/16_rr_repeat_b/T1.sql), [T2](sql/16_rr_repeat_b/T2.sql).\
**Локальный протокол:** [16_rr_repeat_b.txt](output/16_rr_repeat_b.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T1).

**Шаг 1 — T1.** Первое чтение создаёт снимок.

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_16_Player';
```

**Шаг 2 — T2.** Изменить значение и зафиксировать.

```sql
BEGIN;
UPDATE nf.Players SET mmr = 8100 WHERE nickname = 'HW7_TX_16_Player';
COMMIT;
```

**Шаг 3 — T1.** Повторить тот же SELECT.

```sql
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_16_Player';
```

**Шаг 4 — T1.** После завершения транзакции.

```sql
COMMIT;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_16_Player';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | mmr → [[8000]] |
| 2 | T2 | UPDATE 1 |
| 3 | T1 | mmr → [[8000]] |
| 4 | T1 | mmr → [[8100]] |

**Вывод:** В T1 остаётся старый снимок. Новое значение видно только после завершения T1.

**Фотографии pgAdmin:** после ручной проверки добавить `16_rr_repeat_b_1.png` и `16_rr_repeat_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 17_rr_phantom_a. REPEATABLE READ: новый игрок команды

**SQL:** [T1](sql/17_rr_phantom_a/T1.sql), [T2](sql/17_rr_phantom_a/T2.sql).\
**Локальный протокол:** [17_rr_phantom_a.txt](output/17_rr_phantom_a.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T1).

**Шаг 1 — T1.** Первое чтение набора строк.

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_17_Team');
```

**Шаг 2 — T2.** Добавить строку, подходящую под условие, и зафиксировать.

```sql
BEGIN;
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_17_New', 8500, team_id FROM nf.Teams WHERE name = 'HW7_TX_17_Team';
COMMIT;
```

**Шаг 3 — T1.** Повторить тот же запрос.

```sql
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_17_Team');
```

**Шаг 4 — T1.** После завершения T1 новая строка видна.

```sql
COMMIT;
SELECT count(*) AS players_count FROM nf.Players
WHERE team_id = (SELECT team_id FROM nf.Teams WHERE name = 'HW7_TX_17_Team');
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | players_count → [[1]] |
| 2 | T2 | INSERT 0 1 |
| 3 | T1 | players_count → [[1]] |
| 4 | T1 | players_count → [[2]] |

**Вывод:** В T1 количество остаётся 1, после COMMIT становится 2. Фантомного чтения в PostgreSQL REPEATABLE READ нет.

**Фотографии pgAdmin:** после ручной проверки добавить `17_rr_phantom_a_1.png` и `17_rr_phantom_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 18_rr_phantom_b. REPEATABLE READ: новый предмет в выборке

**SQL:** [T1](sql/18_rr_phantom_b/T1.sql), [T2](sql/18_rr_phantom_b/T2.sql).\
**Локальный протокол:** [18_rr_phantom_b.txt](output/18_rr_phantom_b.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T1).

**Шаг 1 — T1.** Первое чтение набора строк.

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_18_Group' AND cost >= 100;
```

**Шаг 2 — T2.** Добавить строку, подходящую под условие, и зафиксировать.

```sql
BEGIN;
INSERT INTO nf.Items (name, cost, description)
VALUES ('HW7_TX_18_New', 200, 'HW7_TX_18_Group');
COMMIT;
```

**Шаг 3 — T1.** Повторить тот же запрос.

```sql
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_18_Group' AND cost >= 100;
```

**Шаг 4 — T1.** После завершения T1 новая строка видна.

```sql
COMMIT;
SELECT count(*) AS items_count FROM nf.Items WHERE description = 'HW7_TX_18_Group' AND cost >= 100;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | items_count → [[1]] |
| 2 | T2 | INSERT 0 1 |
| 3 | T1 | items_count → [[1]] |
| 4 | T1 | items_count → [[2]] |

**Вывод:** В T1 количество остаётся 1, после COMMIT становится 2. Фантомного чтения в PostgreSQL REPEATABLE READ нет.

**Фотографии pgAdmin:** после ручной проверки добавить `18_rr_phantom_b_1.png` и `18_rr_phantom_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 19_serial_insert_a. SERIALIZABLE: две одинаковые заявки на матч (1800 секунд)

**SQL:** [T1](sql/19_serial_insert_a/T1.sql), [T2](sql/19_serial_insert_a/T2.sql).\
**Локальный протокол:** [19_serial_insert_a.txt](output/19_serial_insert_a.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T2) → 5 (T2) → 6 (T2) → 7 (T2) → 8 (T1).

**Шаг 1 — T1.** T1 проверяет отсутствие матча.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 1800;
```

**Шаг 2 — T2.** T2 также видит отсутствие матча.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 1800;
```

**Шаг 3 — T1.** T1 первой создаёт матч и фиксирует результат.

```sql
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 1800, game_mode_id, DATE '2026-11-19' FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode';
COMMIT;
```

**Шаг 4 — T2.** Ожидаемая ошибка сериализации, не ошибка UNIQUE.

```sql
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 1800, game_mode_id, DATE '2026-11-19' FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode';
```

**Шаг 5 — T2.** Завершить неудачную транзакцию отдельной командой.

```sql
ROLLBACK;
```

**Шаг 6 — T2.** Повтор всей транзакции: снимок и проверка создаются заново.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 1800;
```

**Шаг 7 — T2.** На свежем снимке NOT EXISTS ложно: INSERT 0 0.

```sql
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 1800, game_mode_id, DATE '2026-11-19' FROM nf.GameModes
WHERE mode_name = 'HW7_TX_19_Mode'
  AND NOT EXISTS (SELECT 1 FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 1800);
COMMIT;
```

**Шаг 8 — T1.** Окончательная проверка.

```sql
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_19_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 1800;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | matches_count → [[0]] |
| 2 | T2 | matches_count → [[0]] |
| 3 | T1 | INSERT 0 1 |
| 4 | T2 | `40001`: could not serialize access due to read/write dependencies among transactions |
| 5 | T2 | Команда выполнена. |
| 6 | T2 | matches_count → [[1]] |
| 7 | T2 | INSERT 0 0 |
| 8 | T1 | matches_count → [[1]] |

**Вывод:** Обе транзакции прочитали отсутствие матча. После вставки и COMMIT T1 вставка T2 завершается SQLSTATE 40001. После повтора T2 видит матч и не вставляет дубликат. Итог — один матч.

**Фотографии pgAdmin:** после ручной проверки добавить `19_serial_insert_a_1.png` и `19_serial_insert_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 20_serial_insert_b. SERIALIZABLE: две одинаковые заявки на матч (2400 секунд)

**SQL:** [T1](sql/20_serial_insert_b/T1.sql), [T2](sql/20_serial_insert_b/T2.sql).\
**Локальный протокол:** [20_serial_insert_b.txt](output/20_serial_insert_b.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T2) → 5 (T2) → 6 (T2) → 7 (T2) → 8 (T1).

**Шаг 1 — T1.** T1 проверяет отсутствие матча.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 2400;
```

**Шаг 2 — T2.** T2 также видит отсутствие матча.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 2400;
```

**Шаг 3 — T1.** T1 первой создаёт матч и фиксирует результат.

```sql
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 2400, game_mode_id, DATE '2026-11-19' FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode';
COMMIT;
```

**Шаг 4 — T2.** Ожидаемая ошибка сериализации, не ошибка UNIQUE.

```sql
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 2400, game_mode_id, DATE '2026-11-19' FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode';
```

**Шаг 5 — T2.** Завершить неудачную транзакцию отдельной командой.

```sql
ROLLBACK;
```

**Шаг 6 — T2.** Повтор всей транзакции: снимок и проверка создаются заново.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 2400;
```

**Шаг 7 — T2.** На свежем снимке NOT EXISTS ложно: INSERT 0 0.

```sql
INSERT INTO nf.Matches (duration_sec, game_mode_id, match_date)
SELECT 2400, game_mode_id, DATE '2026-11-19' FROM nf.GameModes
WHERE mode_name = 'HW7_TX_20_Mode'
  AND NOT EXISTS (SELECT 1 FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 2400);
COMMIT;
```

**Шаг 8 — T1.** Окончательная проверка.

```sql
SELECT count(*) AS matches_count FROM nf.Matches WHERE game_mode_id = (SELECT game_mode_id FROM nf.GameModes WHERE mode_name = 'HW7_TX_20_Mode')
  AND match_date = DATE '2026-11-19' AND duration_sec = 2400;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | matches_count → [[0]] |
| 2 | T2 | matches_count → [[0]] |
| 3 | T1 | INSERT 0 1 |
| 4 | T2 | `40001`: could not serialize access due to read/write dependencies among transactions |
| 5 | T2 | Команда выполнена. |
| 6 | T2 | matches_count → [[1]] |
| 7 | T2 | INSERT 0 0 |
| 8 | T1 | matches_count → [[1]] |

**Вывод:** Обе транзакции прочитали отсутствие матча. После вставки и COMMIT T1 вставка T2 завершается SQLSTATE 40001. После повтора T2 видит матч и не вставляет дубликат. Итог — один матч.

**Фотографии pgAdmin:** после ручной проверки добавить `20_serial_insert_b_1.png` и `20_serial_insert_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 21_serial_update_a. SERIALIZABLE: конкурентное обновление цены

**SQL:** [T1](sql/21_serial_update_a/T1.sql), [T2](sql/21_serial_update_a/T2.sql).\
**Локальный протокол:** [21_serial_update_a.txt](output/21_serial_update_a.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T2) → 5 (T2) → 6 (T2) → 7 (T2) → 8 (T1).

**Шаг 1 — T1.** Создать снимок T1.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_21_Item';
```

**Шаг 2 — T2.** Создать снимок T2 до изменения строки.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_21_Item';
```

**Шаг 3 — T1.** Первое обновление фиксируется.

```sql
UPDATE nf.Items SET cost = cost + 10 WHERE name = 'HW7_TX_21_Item';
COMMIT;
```

**Шаг 4 — T2.** Ожидается именно ошибка concurrent update.

```sql
UPDATE nf.Items SET cost = cost + 20 WHERE name = 'HW7_TX_21_Item';
```

**Шаг 5 — T2.** Закрыть неудачную транзакцию.

```sql
ROLLBACK;
```

**Шаг 6 — T2.** Повторить транзакцию с самого начала.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_21_Item';
```

**Шаг 7 — T2.** Повторное обновление на свежем снимке.

```sql
UPDATE nf.Items SET cost = cost + 20 WHERE name = 'HW7_TX_21_Item';
COMMIT;
```

**Шаг 8 — T1.** Обе прибавки сохранены.

```sql
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_21_Item';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | cost → [[100]] |
| 2 | T2 | cost → [[100]] |
| 3 | T1 | UPDATE 1 |
| 4 | T2 | `40001`: could not serialize access due to concurrent update |
| 5 | T2 | Команда выполнена. |
| 6 | T2 | cost → [[110]] |
| 7 | T2 | UPDATE 1 |
| 8 | T1 | cost → [[130]] |

**Вывод:** T2 получает could not serialize access due to concurrent update (40001). После полного повтора учитываются обе прибавки: 100 → 110 → 130.

**Фотографии pgAdmin:** после ручной проверки добавить `21_serial_update_a_1.png` и `21_serial_update_a_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 22_serial_update_b. SERIALIZABLE: конкурентное обновление MMR

**SQL:** [T1](sql/22_serial_update_b/T1.sql), [T2](sql/22_serial_update_b/T2.sql).\
**Локальный протокол:** [22_serial_update_b.txt](output/22_serial_update_b.txt).

**Порядок:** 1 (T1) → 2 (T2) → 3 (T1) → 4 (T2) → 5 (T2) → 6 (T2) → 7 (T2) → 8 (T1).

**Шаг 1 — T1.** Создать снимок T1.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_22_Player';
```

**Шаг 2 — T2.** Создать снимок T2 до изменения строки.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_22_Player';
```

**Шаг 3 — T1.** Первое обновление фиксируется.

```sql
UPDATE nf.Players SET mmr = mmr + 100 WHERE nickname = 'HW7_TX_22_Player';
COMMIT;
```

**Шаг 4 — T2.** Ожидается именно ошибка concurrent update.

```sql
UPDATE nf.Players SET mmr = mmr + 200 WHERE nickname = 'HW7_TX_22_Player';
```

**Шаг 5 — T2.** Закрыть неудачную транзакцию.

```sql
ROLLBACK;
```

**Шаг 6 — T2.** Повторить транзакцию с самого начала.

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_22_Player';
```

**Шаг 7 — T2.** Повторное обновление на свежем снимке.

```sql
UPDATE nf.Players SET mmr = mmr + 200 WHERE nickname = 'HW7_TX_22_Player';
COMMIT;
```

**Шаг 8 — T1.** Обе прибавки сохранены.

```sql
SELECT mmr FROM nf.Players WHERE nickname = 'HW7_TX_22_Player';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | mmr → [[8000]] |
| 2 | T2 | mmr → [[8000]] |
| 3 | T1 | UPDATE 1 |
| 4 | T2 | `40001`: could not serialize access due to concurrent update |
| 5 | T2 | Команда выполнена. |
| 6 | T2 | mmr → [[8100]] |
| 7 | T2 | UPDATE 1 |
| 8 | T1 | mmr → [[8300]] |

**Вывод:** T2 получает could not serialize access due to concurrent update (40001). После полного повтора учитываются обе прибавки: 8000 → 8100 → 8300.

**Фотографии pgAdmin:** после ручной проверки добавить `22_serial_update_b_1.png` и `22_serial_update_b_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

## 3. SAVEPOINT — 2 сценария

### 23_savepoint_one. SAVEPOINT: сохранить изменения до точки

**SQL:** [T1](sql/23_savepoint_one/T1.sql).\
**Локальный протокол:** [23_savepoint_one.txt](output/23_savepoint_one.txt).

**Шаг 1 — T1.** Изменения до точки сохранения.

```sql
BEGIN;
UPDATE nf.Teams SET foundation_date = DATE '2010-01-01' WHERE name = 'HW7_TX_23_Team';
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_23_Before', 8000, team_id FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
SAVEPOINT before_extra;
```

**Шаг 2 — T1.** Изменения после точки.

```sql
UPDATE nf.Teams SET foundation_date = DATE '2020-01-01' WHERE name = 'HW7_TX_23_Team';
INSERT INTO nf.Players (nickname, mmr, team_id)
SELECT 'HW7_TX_23_After', 9000, team_id FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
```

**Шаг 3 — T1.** Перед частичным откатом.

```sql
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
SELECT nickname FROM nf.Players WHERE nickname IN ('HW7_TX_23_Before', 'HW7_TX_23_After') ORDER BY nickname;
```

**Шаг 4 — T1.** Изменения до SAVEPOINT остались.

```sql
ROLLBACK TO SAVEPOINT before_extra;
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
SELECT nickname FROM nf.Players WHERE nickname IN ('HW7_TX_23_Before', 'HW7_TX_23_After') ORDER BY nickname;
```

**Шаг 5 — T1.** Оставшиеся изменения зафиксированы.

```sql
COMMIT;
SELECT foundation_date FROM nf.Teams WHERE name = 'HW7_TX_23_Team';
SELECT nickname FROM nf.Players WHERE nickname IN ('HW7_TX_23_Before', 'HW7_TX_23_After') ORDER BY nickname;
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | UPDATE 1; INSERT 0 1 |
| 2 | T1 | UPDATE 1; INSERT 0 1 |
| 3 | T1 | foundation_date → [["2020-01-01"]]; nickname → [["HW7_TX_23_After"], ["HW7_TX_23_Before"]] |
| 4 | T1 | foundation_date → [["2010-01-01"]]; nickname → [["HW7_TX_23_Before"]] |
| 5 | T1 | foundation_date → [["2010-01-01"]]; nickname → [["HW7_TX_23_Before"]] |

**Вывод:** После ROLLBACK TO остались дата 2010-01-01 и игрок Before, созданные до SAVEPOINT. Игрок After и дата 2020-01-01 отменены. COMMIT сохраняет оставшуюся часть.

**Фотографии pgAdmin:** после ручной проверки добавить `23_savepoint_one_1.png` и `23_savepoint_one_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

### 24_savepoint_two. SAVEPOINT: возврат ко второй и первой точкам

**SQL:** [T1](sql/24_savepoint_two/T1.sql).\
**Локальный протокол:** [24_savepoint_two.txt](output/24_savepoint_two.txt).

**Шаг 1 — T1.** Создать две точки.

```sql
BEGIN;
UPDATE nf.Items SET cost = 110 WHERE name = 'HW7_TX_24_Item';
SAVEPOINT first_point;
UPDATE nf.Items SET cost = 120 WHERE name = 'HW7_TX_24_Item';
SAVEPOINT second_point;
UPDATE nf.Items SET cost = 130 WHERE name = 'HW7_TX_24_Item';
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_24_Item';
```

**Шаг 2 — T1.** Возврат ко второй.

```sql
ROLLBACK TO SAVEPOINT second_point;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_24_Item';
```

**Шаг 3 — T1.** Возврат к первой.

```sql
ROLLBACK TO SAVEPOINT first_point;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_24_Item';
```

**Шаг 4 — T1.** Сохранить результат.

```sql
RELEASE SAVEPOINT first_point;
COMMIT;
SELECT cost FROM nf.Items WHERE name = 'HW7_TX_24_Item';
```

**Фактический результат локальной проверки:**

| Шаг | Сессия | Результат |
|---|---|---|
| 1 | T1 | UPDATE 1; UPDATE 1; UPDATE 1; cost → [[130]] |
| 2 | T1 | cost → [[120]] |
| 3 | T1 | cost → [[110]] |
| 4 | T1 | cost → [[110]] |

**Вывод:** Цена меняется 100 → 110 → 120 → 130. Откат ко второй точке возвращает 120, к первой — 110. Откат к первой уничтожает более позднюю вторую точку. После COMMIT цена 110.

**Фотографии pgAdmin:** после ручной проверки добавить `24_savepoint_two_1.png` и `24_savepoint_two_2.png` в `screenshots/` и вставить их в этот раздел. Сейчас фотографии не приложены.

## 4. Общие выводы

1. COMMIT сохраняет связанные INSERT и UPDATE, ROLLBACK отменяет оба изменения.
2. Ошибка деления на ноль переводит всю транзакцию в aborted. Без SAVEPOINT
   предыдущие операции этой транзакции нельзя зафиксировать; после ROLLBACK
   в таблицах остаются исходные значения.
3. READ UNCOMMITTED и READ COMMITTED в PostgreSQL не видят незакоммиченные
   значения другой сессии. После чужого COMMIT новый запрос может видеть новое состояние.
4. На READ COMMITTED снимок меняется от команды к команде: возможны и
   неповторяющееся чтение строки, и появление новых строк в той же выборке.
5. REPEATABLE READ сохраняет снимок: обе аномалии чтения в проведённых опытах
   отсутствуют. После завершения T1 изменения T2 становятся видны.
6. SERIALIZABLE не означает последовательное исполнение без ошибок:
   PostgreSQL может отклонить одну из несовместимых транзакций. После `40001`
   выполняются ROLLBACK и полный повтор на свежем снимке.
7. ROLLBACK TO SAVEPOINT отменяет только изменения после точки. Более ранние
   изменения можно зафиксировать. Возврат к ранней точке удаляет более поздние точки.
8. Имена и данные предыдущих домашних работ не менялись. Локально проверено,
   что после очистки наборы строк всех 14 таблиц `nf` совпадают с исходными.
   Состояние последовательностей не откатывается и не сбрасывается.

## 5. Статус перед сдачей

- [x] Подготовлены SQL-блоки с комментариями.
- [x] Все 24 сценария выполнены на локальной PostgreSQL.
- [x] Фактические результаты и выводы включены в отчёт.
- [ ] Выполнить сценарии в своей базе через pgAdmin.
- [ ] Добавить собственные фотографии выполнения в `screenshots/` и отчёт.
- [ ] После проверки подготовить изменения репозитория и отправку.

На этапе подготовки работа только сохранена локально: коммитов, push и PR нет.
