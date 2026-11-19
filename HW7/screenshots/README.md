# Фотографии выполнения HW7

Для отчёта я сохранил 117 снимков pgAdmin на PostgreSQL 18.
В каждом опыте основные результаты видны сразу, остальные снимки раскрываются ниже.

[К отчёту](../transaction.md#contents) · [Порядок показа](../README.md#showcase)

Имена файлов содержат номер сценария и номер снимка.
Соответствие первоначальных имён и контрольные суммы файлов сохранены
в [source_index.csv](source_index.csv).

| Опыт | Снимков | Фотографии |
|---|---:|---|
| [01. COMMIT: игрок и команда](../transaction.md#hw7-01) | 5 | [1](./01_commit_a_1.png), [2](./01_commit_a_2.png), [3](./01_commit_a_3.png), [4](./01_commit_a_4.png), [5](./01_commit_a_5.png) |
| [02. COMMIT: команда и регион](../transaction.md#hw7-02) | 4 | [1](./02_commit_b_1.png), [2](./02_commit_b_2.png), [3](./02_commit_b_3.png), [4](./02_commit_b_4.png) |
| [03. ROLLBACK: игрок и команда](../transaction.md#hw7-03) | 3 | [1](./03_rollback_a_1.png), [2](./03_rollback_a_2.png), [3](./03_rollback_a_3.png) |
| [04. ROLLBACK: команда и регион](../transaction.md#hw7-04) | 4 | [1](./04_rollback_b_1.png), [2](./04_rollback_b_2.png), [3](./04_rollback_b_3.png), [4](./04_rollback_b_4.png) |
| [05. ERROR: игрок и команда](../transaction.md#hw7-05) | 5 | [1](./05_error_a_1.png), [2](./05_error_a_2.png), [3](./05_error_a_3.png), [4](./05_error_a_4.png), [5](./05_error_a_5.png) |
| [06. ERROR: команда и регион](../transaction.md#hw7-06) | 6 | [1](./06_error_b_1.png), [2](./06_error_b_2.png), [3](./06_error_b_3.png), [4](./06_error_b_4.png), [5](./06_error_b_5.png), [6](./06_error_b_6.png) |
| [07. READ UNCOMMITTED: грязное чтение, цена предмета](../transaction.md#hw7-07) | 4 | [1](./07_ru_dirty_a_1.png), [2](./07_ru_dirty_a_2.png), [3](./07_ru_dirty_a_3.png), [4](./07_ru_dirty_a_4.png) |
| [08. READ UNCOMMITTED: грязное чтение, MMR игрока](../transaction.md#hw7-08) | 5 | [1](./08_ru_dirty_b_1.png), [2](./08_ru_dirty_b_2.png), [3](./08_ru_dirty_b_3.png), [4](./08_ru_dirty_b_4.png), [5](./08_ru_dirty_b_5.png) |
| [09. READ COMMITTED: грязное чтение, цена предмета](../transaction.md#hw7-09) | 5 | [1](./09_rc_dirty_a_1.png), [2](./09_rc_dirty_a_2.png), [3](./09_rc_dirty_a_3.png), [4](./09_rc_dirty_a_4.png), [5](./09_rc_dirty_a_5.png) |
| [10. READ COMMITTED: грязное чтение, MMR игрока](../transaction.md#hw7-10) | 4 | [1](./10_rc_dirty_b_1.png), [2](./10_rc_dirty_b_2.png), [3](./10_rc_dirty_b_3.png), [4](./10_rc_dirty_b_4.png) |
| [11. READ COMMITTED: повторное чтение, цена предмета](../transaction.md#hw7-11) | 4 | [1](./11_rc_repeat_a_1.png), [2](./11_rc_repeat_a_2.png), [3](./11_rc_repeat_a_3.png), [4](./11_rc_repeat_a_4.png) |
| [12. READ COMMITTED: повторное чтение, MMR игрока](../transaction.md#hw7-12) | 4 | [1](./12_rc_repeat_b_1.png), [2](./12_rc_repeat_b_2.png), [3](./12_rc_repeat_b_3.png), [4](./12_rc_repeat_b_4.png) |
| [13. READ COMMITTED: новый игрок команды](../transaction.md#hw7-13) | 4 | [1](./13_rc_phantom_a_1.png), [2](./13_rc_phantom_a_2.png), [3](./13_rc_phantom_a_3.png), [4](./13_rc_phantom_a_4.png) |
| [14. READ COMMITTED: новый предмет в выборке](../transaction.md#hw7-14) | 4 | [1](./14_rc_phantom_b_1.png), [2](./14_rc_phantom_b_2.png), [3](./14_rc_phantom_b_3.png), [4](./14_rc_phantom_b_4.png) |
| [15. REPEATABLE READ: повторное чтение, цена предмета](../transaction.md#hw7-15) | 4 | [1](./15_rr_repeat_a_1.png), [2](./15_rr_repeat_a_2.png), [3](./15_rr_repeat_a_3.png), [4](./15_rr_repeat_a_4.png) |
| [16. REPEATABLE READ: повторное чтение, MMR игрока](../transaction.md#hw7-16) | 4 | [1](./16_rr_repeat_b_1.png), [2](./16_rr_repeat_b_2.png), [3](./16_rr_repeat_b_3.png), [4](./16_rr_repeat_b_4.png) |
| [17. REPEATABLE READ: новый игрок команды](../transaction.md#hw7-17) | 4 | [1](./17_rr_phantom_a_1.png), [2](./17_rr_phantom_a_2.png), [3](./17_rr_phantom_a_3.png), [4](./17_rr_phantom_a_4.png) |
| [18. REPEATABLE READ: новый предмет в выборке](../transaction.md#hw7-18) | 4 | [1](./18_rr_phantom_b_1.png), [2](./18_rr_phantom_b_2.png), [3](./18_rr_phantom_b_3.png), [4](./18_rr_phantom_b_4.png) |
| [19. SERIALIZABLE: две одинаковые заявки на матч (1800 секунд)](../transaction.md#hw7-19) | 7 | [1](./19_serial_insert_a_1.png), [2](./19_serial_insert_a_2.png), [3](./19_serial_insert_a_3.png), [4](./19_serial_insert_a_4.png), [5](./19_serial_insert_a_5.png), [6](./19_serial_insert_a_6.png), [7](./19_serial_insert_a_7.png) |
| [20. SERIALIZABLE: две одинаковые заявки на матч (2400 секунд)](../transaction.md#hw7-20) | 8 | [1](./20_serial_insert_b_1.png), [2](./20_serial_insert_b_2.png), [3](./20_serial_insert_b_3.png), [4](./20_serial_insert_b_4.png), [5](./20_serial_insert_b_5.png), [6](./20_serial_insert_b_6.png), [7](./20_serial_insert_b_7.png), [8](./20_serial_insert_b_8.png) |
| [21. SERIALIZABLE: конкурентное обновление цены](../transaction.md#hw7-21) | 8 | [1](./21_serial_update_a_1.png), [2](./21_serial_update_a_2.png), [3](./21_serial_update_a_3.png), [4](./21_serial_update_a_4.png), [5](./21_serial_update_a_5.png), [6](./21_serial_update_a_6.png), [7](./21_serial_update_a_7.png), [8](./21_serial_update_a_8.png) |
| [22. SERIALIZABLE: конкурентное обновление MMR](../transaction.md#hw7-22) | 8 | [1](./22_serial_update_b_1.png), [2](./22_serial_update_b_2.png), [3](./22_serial_update_b_3.png), [4](./22_serial_update_b_4.png), [5](./22_serial_update_b_5.png), [6](./22_serial_update_b_6.png), [7](./22_serial_update_b_7.png), [8](./22_serial_update_b_8.png) |
| [23. SAVEPOINT: сохранить изменения до точки](../transaction.md#hw7-23) | 5 | [1](./23_savepoint_one_1.png), [2](./23_savepoint_one_2.png), [3](./23_savepoint_one_3.png), [4](./23_savepoint_one_4.png), [5](./23_savepoint_one_5.png) |
| [24. SAVEPOINT: возврат ко второй и первой точкам](../transaction.md#hw7-24) | 4 | [1](./24_savepoint_two_1.png), [2](./24_savepoint_two_2.png), [3](./24_savepoint_two_3.png), [4](./24_savepoint_two_4.png) |
