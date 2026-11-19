# Фотографии выполнения HW7

В папке 117 исходных снимков pgAdmin на PostgreSQL 18. Они сгруппированы по 24 сценариям.
Все изображения скопированы из предоставленного архива без изменения пикселей,
переименованы по шаблону `<сценарий>_<номер>.png` и включены в `transaction.md`.
В отчёте фотографии каждого сценария раскрываются по нажатию «Показать снимки».

Соответствие исходных имён новым и SHA-256 каждого файла: [source_index.csv](source_index.csv).
Автоматическая проверка SQL выполнялась отдельно на PostgreSQL 17.10; её протоколы
находятся в `../output`. Они не подменяют ручной прогон на фотографиях.

На части снимков длинные запросы или значения обрезаны шириной редактора/колонок,
а после нескольких SELECT виден только последний набор данных. Изображения не
дорисовывались; полные запросы и локальные результаты сохранены в отчёте.

## Индекс

| Сценарий | Снимков | Файлы |
|---|---:|---|
| 01_commit_a | 5 | [01_commit_a_1.png](./01_commit_a_1.png), [01_commit_a_2.png](./01_commit_a_2.png), [01_commit_a_3.png](./01_commit_a_3.png), [01_commit_a_4.png](./01_commit_a_4.png), [01_commit_a_5.png](./01_commit_a_5.png) |
| 02_commit_b | 4 | [02_commit_b_1.png](./02_commit_b_1.png), [02_commit_b_2.png](./02_commit_b_2.png), [02_commit_b_3.png](./02_commit_b_3.png), [02_commit_b_4.png](./02_commit_b_4.png) |
| 03_rollback_a | 3 | [03_rollback_a_1.png](./03_rollback_a_1.png), [03_rollback_a_2.png](./03_rollback_a_2.png), [03_rollback_a_3.png](./03_rollback_a_3.png) |
| 04_rollback_b | 4 | [04_rollback_b_1.png](./04_rollback_b_1.png), [04_rollback_b_2.png](./04_rollback_b_2.png), [04_rollback_b_3.png](./04_rollback_b_3.png), [04_rollback_b_4.png](./04_rollback_b_4.png) |
| 05_error_a | 5 | [05_error_a_1.png](./05_error_a_1.png), [05_error_a_2.png](./05_error_a_2.png), [05_error_a_3.png](./05_error_a_3.png), [05_error_a_4.png](./05_error_a_4.png), [05_error_a_5.png](./05_error_a_5.png) |
| 06_error_b | 6 | [06_error_b_1.png](./06_error_b_1.png), [06_error_b_2.png](./06_error_b_2.png), [06_error_b_3.png](./06_error_b_3.png), [06_error_b_4.png](./06_error_b_4.png), [06_error_b_5.png](./06_error_b_5.png), [06_error_b_6.png](./06_error_b_6.png) |
| 07_ru_dirty_a | 4 | [07_ru_dirty_a_1.png](./07_ru_dirty_a_1.png), [07_ru_dirty_a_2.png](./07_ru_dirty_a_2.png), [07_ru_dirty_a_3.png](./07_ru_dirty_a_3.png), [07_ru_dirty_a_4.png](./07_ru_dirty_a_4.png) |
| 08_ru_dirty_b | 5 | [08_ru_dirty_b_1.png](./08_ru_dirty_b_1.png), [08_ru_dirty_b_2.png](./08_ru_dirty_b_2.png), [08_ru_dirty_b_3.png](./08_ru_dirty_b_3.png), [08_ru_dirty_b_4.png](./08_ru_dirty_b_4.png), [08_ru_dirty_b_5.png](./08_ru_dirty_b_5.png) |
| 09_rc_dirty_a | 5 | [09_rc_dirty_a_1.png](./09_rc_dirty_a_1.png), [09_rc_dirty_a_2.png](./09_rc_dirty_a_2.png), [09_rc_dirty_a_3.png](./09_rc_dirty_a_3.png), [09_rc_dirty_a_4.png](./09_rc_dirty_a_4.png), [09_rc_dirty_a_5.png](./09_rc_dirty_a_5.png) |
| 10_rc_dirty_b | 4 | [10_rc_dirty_b_1.png](./10_rc_dirty_b_1.png), [10_rc_dirty_b_2.png](./10_rc_dirty_b_2.png), [10_rc_dirty_b_3.png](./10_rc_dirty_b_3.png), [10_rc_dirty_b_4.png](./10_rc_dirty_b_4.png) |
| 11_rc_repeat_a | 4 | [11_rc_repeat_a_1.png](./11_rc_repeat_a_1.png), [11_rc_repeat_a_2.png](./11_rc_repeat_a_2.png), [11_rc_repeat_a_3.png](./11_rc_repeat_a_3.png), [11_rc_repeat_a_4.png](./11_rc_repeat_a_4.png) |
| 12_rc_repeat_b | 4 | [12_rc_repeat_b_1.png](./12_rc_repeat_b_1.png), [12_rc_repeat_b_2.png](./12_rc_repeat_b_2.png), [12_rc_repeat_b_3.png](./12_rc_repeat_b_3.png), [12_rc_repeat_b_4.png](./12_rc_repeat_b_4.png) |
| 13_rc_phantom_a | 4 | [13_rc_phantom_a_1.png](./13_rc_phantom_a_1.png), [13_rc_phantom_a_2.png](./13_rc_phantom_a_2.png), [13_rc_phantom_a_3.png](./13_rc_phantom_a_3.png), [13_rc_phantom_a_4.png](./13_rc_phantom_a_4.png) |
| 14_rc_phantom_b | 4 | [14_rc_phantom_b_1.png](./14_rc_phantom_b_1.png), [14_rc_phantom_b_2.png](./14_rc_phantom_b_2.png), [14_rc_phantom_b_3.png](./14_rc_phantom_b_3.png), [14_rc_phantom_b_4.png](./14_rc_phantom_b_4.png) |
| 15_rr_repeat_a | 4 | [15_rr_repeat_a_1.png](./15_rr_repeat_a_1.png), [15_rr_repeat_a_2.png](./15_rr_repeat_a_2.png), [15_rr_repeat_a_3.png](./15_rr_repeat_a_3.png), [15_rr_repeat_a_4.png](./15_rr_repeat_a_4.png) |
| 16_rr_repeat_b | 4 | [16_rr_repeat_b_1.png](./16_rr_repeat_b_1.png), [16_rr_repeat_b_2.png](./16_rr_repeat_b_2.png), [16_rr_repeat_b_3.png](./16_rr_repeat_b_3.png), [16_rr_repeat_b_4.png](./16_rr_repeat_b_4.png) |
| 17_rr_phantom_a | 4 | [17_rr_phantom_a_1.png](./17_rr_phantom_a_1.png), [17_rr_phantom_a_2.png](./17_rr_phantom_a_2.png), [17_rr_phantom_a_3.png](./17_rr_phantom_a_3.png), [17_rr_phantom_a_4.png](./17_rr_phantom_a_4.png) |
| 18_rr_phantom_b | 4 | [18_rr_phantom_b_1.png](./18_rr_phantom_b_1.png), [18_rr_phantom_b_2.png](./18_rr_phantom_b_2.png), [18_rr_phantom_b_3.png](./18_rr_phantom_b_3.png), [18_rr_phantom_b_4.png](./18_rr_phantom_b_4.png) |
| 19_serial_insert_a | 7 | [19_serial_insert_a_1.png](./19_serial_insert_a_1.png), [19_serial_insert_a_2.png](./19_serial_insert_a_2.png), [19_serial_insert_a_3.png](./19_serial_insert_a_3.png), [19_serial_insert_a_4.png](./19_serial_insert_a_4.png), [19_serial_insert_a_5.png](./19_serial_insert_a_5.png), [19_serial_insert_a_6.png](./19_serial_insert_a_6.png), [19_serial_insert_a_7.png](./19_serial_insert_a_7.png) |
| 20_serial_insert_b | 8 | [20_serial_insert_b_1.png](./20_serial_insert_b_1.png), [20_serial_insert_b_2.png](./20_serial_insert_b_2.png), [20_serial_insert_b_3.png](./20_serial_insert_b_3.png), [20_serial_insert_b_4.png](./20_serial_insert_b_4.png), [20_serial_insert_b_5.png](./20_serial_insert_b_5.png), [20_serial_insert_b_6.png](./20_serial_insert_b_6.png), [20_serial_insert_b_7.png](./20_serial_insert_b_7.png), [20_serial_insert_b_8.png](./20_serial_insert_b_8.png) |
| 21_serial_update_a | 8 | [21_serial_update_a_1.png](./21_serial_update_a_1.png), [21_serial_update_a_2.png](./21_serial_update_a_2.png), [21_serial_update_a_3.png](./21_serial_update_a_3.png), [21_serial_update_a_4.png](./21_serial_update_a_4.png), [21_serial_update_a_5.png](./21_serial_update_a_5.png), [21_serial_update_a_6.png](./21_serial_update_a_6.png), [21_serial_update_a_7.png](./21_serial_update_a_7.png), [21_serial_update_a_8.png](./21_serial_update_a_8.png) |
| 22_serial_update_b | 8 | [22_serial_update_b_1.png](./22_serial_update_b_1.png), [22_serial_update_b_2.png](./22_serial_update_b_2.png), [22_serial_update_b_3.png](./22_serial_update_b_3.png), [22_serial_update_b_4.png](./22_serial_update_b_4.png), [22_serial_update_b_5.png](./22_serial_update_b_5.png), [22_serial_update_b_6.png](./22_serial_update_b_6.png), [22_serial_update_b_7.png](./22_serial_update_b_7.png), [22_serial_update_b_8.png](./22_serial_update_b_8.png) |
| 23_savepoint_one | 5 | [23_savepoint_one_1.png](./23_savepoint_one_1.png), [23_savepoint_one_2.png](./23_savepoint_one_2.png), [23_savepoint_one_3.png](./23_savepoint_one_3.png), [23_savepoint_one_4.png](./23_savepoint_one_4.png), [23_savepoint_one_5.png](./23_savepoint_one_5.png) |
| 24_savepoint_two | 4 | [24_savepoint_two_1.png](./24_savepoint_two_1.png), [24_savepoint_two_2.png](./24_savepoint_two_2.png), [24_savepoint_two_3.png](./24_savepoint_two_3.png), [24_savepoint_two_4.png](./24_savepoint_two_4.png) |
