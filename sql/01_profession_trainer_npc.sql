-- "Profession Trainer" - summonable, follows the player. Model/unit_class
-- copied from the real Gelman Stonehand (entry 5513, Mining Trainer,
-- CreatureDisplayID 3308) - a separate entry, his own row/model/trainer
-- list are never touched.
--
-- unit_flags 770 = UNIT_FLAG_NON_ATTACKABLE (0x2) | UNIT_FLAG_IMMUNE_TO_PC
-- (0x100) | UNIT_FLAG_IMMUNE_TO_NPC (0x200): the real Gelman is stationary
-- and only needs IMMUNE_TO_NPC (512); ours follows the player through
-- potentially hostile areas, so it reuses the same fuller flag set the
-- Roguelite Heirloom Vendor already proved works for a following summon
-- (confirmed live: without it, a follow-summon gets pulled into combat by
-- nearby hostile creatures and abandons the player to run back to its
-- spawn point).
DELETE FROM `creature_template` WHERE `entry` = 900200;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `RegenHealth`) VALUES
(900200, 'Profession Trainer', 'Premium', 80, 80, 12, 81, 1, 770, 1);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 900200;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(900200, 0, 3308, 1, 1);
