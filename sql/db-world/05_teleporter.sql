-- "Teleporter" - summonable, follows the player. Model copied from the
-- real Archmage Xylem (entry 8379, CreatureDisplayID 7591), the
-- Dalaran-sewers NPC who teleports players between major cities in the
-- real game - a separate entry, his own row is never touched. (His real
-- gossip_menu_id is just 0, the generic shared pool - his actual
-- teleport behavior isn't reusable data the way Class Trainer's was, so
-- this NPC's destination menu is built entirely in Lua instead.)
--
-- npcflag 1 = UNIT_NPC_FLAG_GOSSIP - no vendor/trainer flag needed, the
-- destination menu is built entirely in Lua (teleporter.lua), not from
-- any native trainer/vendor table.
--
-- unit_flags 770 = UNIT_FLAG_NON_ATTACKABLE (0x2) | UNIT_FLAG_IMMUNE_TO_PC
-- (0x100) | UNIT_FLAG_IMMUNE_TO_NPC (0x200): this NPC follows the player
-- through potentially hostile areas and needs the fuller set - without
-- it, a following summon gets pulled into combat by nearby hostile
-- creatures and abandons the player to run back to its spawn point.
DELETE FROM `creature_template` WHERE `entry` = 900202;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `RegenHealth`) VALUES
(900202, 'Teleporter', 'Premium', 80, 80, 12, 1, 8, 770, 1);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 900202;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(900202, 0, 7591, 1, 1);

-- Gossip header text shown above the destination list (teleporter.lua's
-- OnGossipHello). A new row scoped to our own entry, not a reused real one.
DELETE FROM `npc_text` WHERE `ID` = 900202;
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES
(900202, 'Where would you like to go?');
