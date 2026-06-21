-- "Profession Trainer" - summonable, follows the player. Model/unit_class
-- copied from the real Gelman Stonehand (entry 5513, Mining Trainer,
-- CreatureDisplayID 3308) - a separate entry, his own row/model/trainer
-- list are never touched.
--
-- unit_flags 770 = UNIT_FLAG_NON_ATTACKABLE (0x2) | UNIT_FLAG_IMMUNE_TO_PC
-- (0x100) | UNIT_FLAG_IMMUNE_TO_NPC (0x200): the real Gelman is stationary
-- and only needs IMMUNE_TO_NPC (512); ours follows the player through
-- potentially hostile areas and needs the fuller set - without it, a
-- following summon gets pulled into combat by nearby hostile creatures
-- and abandons the player to run back to its spawn point.
-- gossip_menu_id 900200 (see 03_profession_trainer_gossip.sql) gives this
-- NPC its own dedicated gossip menu containing only the trainer option -
-- left at the default 0, it falls back to the engine's generic shared
-- menu pool, which bundles in unrelated options (unlearn talents, dual
-- talent specialization) alongside the trainer option for any
-- UNIT_NPC_FLAG_TRAINER creature using that default.
DELETE FROM `creature_template` WHERE `entry` = 900200;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `RegenHealth`, `gossip_menu_id`) VALUES
(900200, 'Profession Trainer', 'Premium', 80, 80, 12, 81, 1, 770, 1, 900200);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 900200;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(900200, 0, 3308, 1, 1);

-- Dedicated gossip menu (referenced by gossip_menu_id above). Contains
-- only the "Train me!" option (OptionType 5 = GOSSIP_OPTION_TRAINER), so
-- this NPC doesn't inherit the unrelated options (unlearn talents, dual
-- talent specialization, etc.) bundled into the engine's generic
-- gossip_menu_id 0 pool for any UNIT_NPC_FLAG_TRAINER creature using that
-- default. Pattern copied from real, properly-configured trainers (e.g.
-- "Shaina Fuller", gossip_menu_id 657), not the generic default.
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 900200;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionType`, `OptionNpcFlag`) VALUES
(900200, 0, 3, 'Train me!', 5, 16);
