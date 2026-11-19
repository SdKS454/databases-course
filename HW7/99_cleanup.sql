BEGIN;
-- Удаляются только демонстрационные строки HW7_TX_.
-- Выполнять после завершения всех T1/T2; чужие данные и последовательности не сбрасываются.
DELETE FROM nf.Players WHERE left(nickname, 7) = 'HW7_TX_';
DELETE FROM nf.Teams WHERE left(name, 7) = 'HW7_TX_';
DELETE FROM nf.Items WHERE left(name, 7) = 'HW7_TX_';
DELETE FROM nf.Matches WHERE game_mode_id IN
    (SELECT game_mode_id FROM nf.GameModes WHERE left(mode_name, 7) = 'HW7_TX_');
DELETE FROM nf.GameModes WHERE left(mode_name, 7) = 'HW7_TX_';
DELETE FROM nf.Regions WHERE left(region_name, 7) = 'HW7_TX_';
COMMIT;
