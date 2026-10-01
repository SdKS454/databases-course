# Домашняя работа 3 — Нормализация до 3НФ и НФБК

**Предметная область:** Dota 2 (продолжение HW1, HW2)
**Дедлайн:** 2 октября 2025

## Цель работы

1. Привести схему из HW2 к **3-й нормальной форме**.
2. Проверить полученную схему на **НФБК** (все нетривиальные зависимости — от ключей-кандидатов).
3. Выявить аномалии вставки, обновления и удаления.
4. Описать, какие аномалии были и как они устранены.
5. Приложить новую ER-диаграмму в НФ.

## Основной документ

**[normal_forms.md](normal_forms.md)** — разбор функциональных зависимостей, найденные
аномалии и способы их устранения, доказательство НФБК для каждой из 14 таблиц,
собственные примеры и задачи к паре.

## Файлы работы

```
HW3/
├── normal_forms.md         — разбор ФЗ, аномалии, решения, задачи к паре
├── normalized_schema.sql   — 14 таблиц в 3НФ/НФБК + 2 представления (схема nf)
├── migrate_to_nf.sql       — перенос данных из схемы HW2 + проверка целостности
├── diagram.mmd             — исходник ER-диаграммы (Mermaid)
└── ER_diagram_nf.png       — ER-диаграмма нормализованной схемы
```

Нормализованные объекты размещены в PostgreSQL-схеме `nf`, чтобы не конфликтовать
с таблицами HW2 в `public`: исходная схема остаётся для сравнения.

## Кратко: что было сделано

| Было (HW2) | Стало | Тип нарушения |
|---|---|---|
| `Heroes.role = 'Support/Roamer'` | `HeroRoles` + `Roles` | 1НФ, составной атрибут |
| `Matches.radiant_team_id`, `dire_team_id` | `MatchTeams` | повторяющаяся группа |
| `Matches.winner_side` | `MatchTeams.is_winner` | двойное представление факта |
| `Players.rank` | `Ranks` по диапазону MMR | 3НФ, транзитивная зависимость |
| `Teams.region`, `Players.region` | `Regions` + FK | дубль справочника |
| `PlayerMatchItems` | `PlayerInventory` | неверный ключ |
| `Matches.game_mode` | `GameModes` + FK | дубль справочника |

Аномалии нашлись настоящие, а не выдуманные: в данных HW2 регион был записан
двумя способами (`'Western Europe'` и `'Western Europe (EU)'`), а у игрока Miposhka
`rank = 'Divine'` расходился с `mmr = 9800`. Оба расхождения миграция выводит
отчётом, а не исправляет молча.

Побочный эффект нормализации: в `PlayerInventory` `slot_index` стал частью ключа,
поэтому в базе наконец можно записать, что игрок купил два одинаковых предмета —
в схеме HW2 такое было запрещено первичным ключом.

## Как воспроизвести

```bash
# 1. Схема и данные HW2
psql -h 127.0.0.1 -U timerlan -d dota2_hw -f ../HW2/create_tables.sql
psql -h 127.0.0.1 -U timerlan -d dota2_hw -f ../HW2/alter_tables.sql
psql -h 127.0.0.1 -U timerlan -d dota2_hw -f ../HW2/insert_data.sql
psql -h 127.0.0.1 -U timerlan -d dota2_hw -f ../HW2/update_data.sql

# 2. Нормализованная схема (3НФ / НФБК)
psql -h 127.0.0.1 -U timerlan -d dota2_hw -f normalized_schema.sql

# 3. Перенос данных и проверка целостности
psql -h 127.0.0.1 -U timerlan -d dota2_hw -f migrate_to_nf.sql

# 4. Результат
psql -h 127.0.0.1 -U timerlan -d dota2_hw -c "SELECT * FROM nf.v_match_results ORDER BY match_id;"
psql -h 127.0.0.1 -U timerlan -d dota2_hw -c "SELECT * FROM nf.v_players_with_rank ORDER BY player_id;"
```

Рендер ER-диаграммы:

```bash
npx --yes @mermaid-js/mermaid-cli -i diagram.mmd -o ER_diagram_nf.png -b white -s 2
```

Все скрипты проверены на PostgreSQL 16: схема создаётся, данные переносятся
без потерь, а блок проверки в конце `migrate_to_nf.sql` подтверждает, что ни одна
строка не потеряна, каждый игрок попадает ровно в один диапазон MMR, а в каждом
матче ровно один победитель.