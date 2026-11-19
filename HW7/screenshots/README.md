# Фотографии выполнения в pgAdmin

Фотографии нужно сделать во время своего прогона; сейчас здесь нет готовых снимков.
Текстовые протоколы в `../output` — фактические результаты локальной PostgreSQL,
но они не заменяют фотографии из pgAdmin.

На снимке должны быть видны SQL выделенного шага и результат Data Output
либо текст ошибки во вкладке Messages. Для двухсессионных опытов указывать T1/T2
в имени вкладки или захватывать обе вкладки по отдельности.
Не требуется показывать пароль подключения.

Для каждого сценария сохранить два снимка с именами из таблицы:
первый показывает исходное чтение/состояние, второй — изменение результата
или его отсутствие после действий второй транзакции. Для ошибки сериализации
второй снимок должен показывать SQLSTATE 40001, а успешный повтор можно сохранить
третьим снимком с суффиксом `_3.png`. Для деления на ноль также показать ROLLBACK
и восстановленные значения.

| Сценарий | Первый снимок | Второй снимок |
|---|---|---|
| COMMIT: игрок и команда | `01_commit_a_1.png` | `01_commit_a_2.png` |
| COMMIT: команда и регион | `02_commit_b_1.png` | `02_commit_b_2.png` |
| ROLLBACK: игрок и команда | `03_rollback_a_1.png` | `03_rollback_a_2.png` |
| ROLLBACK: команда и регион | `04_rollback_b_1.png` | `04_rollback_b_2.png` |
| ERROR: игрок и команда | `05_error_a_1.png` | `05_error_a_2.png` |
| ERROR: команда и регион | `06_error_b_1.png` | `06_error_b_2.png` |
| READ UNCOMMITTED: грязное чтение, цена предмета | `07_ru_dirty_a_1.png` | `07_ru_dirty_a_2.png` |
| READ UNCOMMITTED: грязное чтение, MMR игрока | `08_ru_dirty_b_1.png` | `08_ru_dirty_b_2.png` |
| READ COMMITTED: грязное чтение, цена предмета | `09_rc_dirty_a_1.png` | `09_rc_dirty_a_2.png` |
| READ COMMITTED: грязное чтение, MMR игрока | `10_rc_dirty_b_1.png` | `10_rc_dirty_b_2.png` |
| READ COMMITTED: повторное чтение, цена предмета | `11_rc_repeat_a_1.png` | `11_rc_repeat_a_2.png` |
| READ COMMITTED: повторное чтение, MMR игрока | `12_rc_repeat_b_1.png` | `12_rc_repeat_b_2.png` |
| READ COMMITTED: новый игрок команды | `13_rc_phantom_a_1.png` | `13_rc_phantom_a_2.png` |
| READ COMMITTED: новый предмет в выборке | `14_rc_phantom_b_1.png` | `14_rc_phantom_b_2.png` |
| REPEATABLE READ: повторное чтение, цена предмета | `15_rr_repeat_a_1.png` | `15_rr_repeat_a_2.png` |
| REPEATABLE READ: повторное чтение, MMR игрока | `16_rr_repeat_b_1.png` | `16_rr_repeat_b_2.png` |
| REPEATABLE READ: новый игрок команды | `17_rr_phantom_a_1.png` | `17_rr_phantom_a_2.png` |
| REPEATABLE READ: новый предмет в выборке | `18_rr_phantom_b_1.png` | `18_rr_phantom_b_2.png` |
| SERIALIZABLE: две одинаковые заявки на матч (1800 секунд) | `19_serial_insert_a_1.png` | `19_serial_insert_a_2.png` |
| SERIALIZABLE: две одинаковые заявки на матч (2400 секунд) | `20_serial_insert_b_1.png` | `20_serial_insert_b_2.png` |
| SERIALIZABLE: конкурентное обновление цены | `21_serial_update_a_1.png` | `21_serial_update_a_2.png` |
| SERIALIZABLE: конкурентное обновление MMR | `22_serial_update_b_1.png` | `22_serial_update_b_2.png` |
| SAVEPOINT: сохранить изменения до точки | `23_savepoint_one_1.png` | `23_savepoint_one_2.png` |
| SAVEPOINT: возврат ко второй и первой точкам | `24_savepoint_two_1.png` | `24_savepoint_two_2.png` |

После создания файлов вставить их в соответствующие разделы `transaction.md`, например:

```markdown
![Первое чтение T1](screenshots/11_rc_repeat_a_1.png)
![Второе чтение T1 после COMMIT T2](screenshots/11_rc_repeat_a_2.png)
```
